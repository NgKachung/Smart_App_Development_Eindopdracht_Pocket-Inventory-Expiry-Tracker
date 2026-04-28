import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'dart:io';

import '../services/open_food_facts_service.dart';
import 'add_product_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();

  CameraController? _cameraController;
  bool _isInitializing = true;
  bool _isProcessingFrame = false;
  bool _isLoadingProduct = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final cameraDescription = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        cameraDescription,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
        : ImageFormatGroup.yuv420,
      );

      await controller.initialize();
      await controller.startImageStream(_processCameraImage);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isInitializing = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Kon camera niet starten.\n$e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessingFrame || _isLoadingProduct || _cameraController == null) {
      return;
    }

    _isProcessingFrame = true;
    try {
      final inputImage = _inputImageFromCameraImage(image, _cameraController!);
      if (inputImage == null) {
        return;
      }

      final barcodes = await _barcodeScanner.processImage(inputImage);
      final barcodeValue = barcodes
          .map((barcode) => barcode.rawValue?.trim())
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .cast<String?>()
          .firstOrNull;

      if (barcodeValue != null && barcodeValue.isNotEmpty) {
        await _handleDetectedBarcode(barcodeValue);
      }
    } catch (_) {
      // Ignore single-frame scan errors.
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image, CameraController controller) {
    final rotation = InputImageRotationValue.fromRawValue(controller.description.sensorOrientation);
    if (rotation == null) {
      return null;
    }

    if (Platform.isAndroid) {
      final nv21Bytes = _androidCameraImageToNv21(image);
      if (nv21Bytes == null) {
        return null;
      }

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      );

      return InputImage.fromBytes(
        bytes: nv21Bytes,
        metadata: metadata,
      );
    }

    if (Platform.isIOS) {
      if (image.planes.length != 1) {
        return null;
      }

      final plane = image.planes.first;
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.bgra8888,
        bytesPerRow: plane.bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: metadata,
      );
    }

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) {
      return null;
    }

    final bytes = WriteBuffer();
    for (final plane in image.planes) {
      bytes.putUint8List(plane.bytes);
    }

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(
      bytes: bytes.done().buffer.asUint8List(),
      metadata: metadata,
    );
  }

  Uint8List? _androidCameraImageToNv21(CameraImage image) {
    if (image.planes.isEmpty) {
      return null;
    }

    if (image.planes.length == 1) {
      return image.planes.first.bytes;
    }

    if (image.planes.length < 3) {
      return null;
    }

    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final yPixelStride = yPlane.bytesPerPixel ?? 1;
    final uRowStride = uPlane.bytesPerRow;
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vRowStride = vPlane.bytesPerRow;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    final output = Uint8List(width * height * 3 ~/ 2);
    var outputOffset = 0;

    for (var row = 0; row < height; row++) {
      final rowOffset = row * yRowStride;
      for (var col = 0; col < width; col++) {
        output[outputOffset++] = yBytes[rowOffset + col * yPixelStride];
      }
    }

    final chromaHeight = height ~/ 2;
    final chromaWidth = width ~/ 2;
    for (var row = 0; row < chromaHeight; row++) {
      final uRowOffset = row * uRowStride;
      final vRowOffset = row * vRowStride;
      for (var col = 0; col < chromaWidth; col++) {
        final uIndex = uRowOffset + col * uPixelStride;
        final vIndex = vRowOffset + col * vPixelStride;
        output[outputOffset++] = vBytes[vIndex];
        output[outputOffset++] = uBytes[uIndex];
      }
    }

    return output;
  }

  Future<void> _handleDetectedBarcode(String barcode) async {
    if (_isLoadingProduct || !mounted) {
      return;
    }

    setState(() => _isLoadingProduct = true);

    try {
      final product = await _openFoodFactsService.fetchProductByBarcode(barcode.trim());

      if (!mounted) {
        return;
      }

      if (product == null) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Niet gevonden'),
            content: const Text('Geen product gevonden op OpenFoodFacts. Je kunt het handmatig toevoegen.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );

        if (mounted) {
          await Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => AddProductScreen(prefilledBarcode: barcode),
            ),
          );
        }
      } else {
        if (mounted) {
          await Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (_) => AddProductScreen(
                prefilledTitle: product.title,
                prefilledSubtitle: product.subtitle,
                prefilledDescription: product.description,
                prefilledImageUrl: product.imageUrl,
                prefilledBrand: product.brand,
                prefilledQuantity: product.quantity,
                prefilledBarcode: product.barcode,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Fout'),
          content: Text('Kon product niet ophalen.\n$e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingProduct = false);
      }
    }
  }

  Future<void> _showBarcodeInputDialog() async {
    final barcodeController = TextEditingController();
    bool isLoading = false;

    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => CupertinoAlertDialog(
          title: const Text('Product via barcode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: barcodeController,
                placeholder: 'Voer barcode in (EAN)',
                keyboardType: TextInputType.number,
                enabled: !isLoading,
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Annuleren'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            CupertinoDialogAction(
              child: isLoading ? const CupertinoActivityIndicator() : const Text('Volgende'),
              onPressed: isLoading
                  ? null
                  : () async {
                      final barcode = barcodeController.text.trim();
                      if (barcode.isEmpty) {
                        return;
                      }

                      setStateDialog(() => isLoading = true);

                      try {
                        final product = await _openFoodFactsService.fetchProductByBarcode(barcode);

                        if (!mounted) {
                          return;
                        }

                        Navigator.of(dialogContext).pop();

                        if (product == null) {
                          await showCupertinoDialog<void>(
                            context: context,
                            builder: (ctx) => CupertinoAlertDialog(
                              title: const Text('Niet gevonden'),
                              content: const Text('Geen product gevonden op OpenFoodFacts. Je kunt het handmatig toevoegen.'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('OK'),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                              ],
                            ),
                          );

                          if (mounted) {
                            await Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) => AddProductScreen(prefilledBarcode: barcode),
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            await Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (_) => AddProductScreen(
                                  prefilledTitle: product.title,
                                  prefilledSubtitle: product.subtitle,
                                  prefilledDescription: product.description,
                                  prefilledImageUrl: product.imageUrl,
                                  prefilledBrand: product.brand,
                                  prefilledQuantity: product.quantity,
                                  prefilledBarcode: product.barcode,
                                ),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (!mounted) {
                          return;
                        }

                        Navigator.of(dialogContext).pop();

                        await showCupertinoDialog<void>(
                          context: context,
                          builder: (ctx) => CupertinoAlertDialog(
                            title: const Text('Fout'),
                            content: Text('Kon product niet ophalen.\n$e'),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('OK'),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Scan barcode'),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_errorMessage!, textAlign: TextAlign.center),
                ),
              )
            else if (_isInitializing)
              const Center(child: CupertinoActivityIndicator(radius: 16))
            else if (_cameraController != null && _cameraController!.value.isInitialized)
              CameraPreview(_cameraController!)
            else
              const Center(child: Text('Camera niet beschikbaar')),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Richt de camera op een barcode\nof gebruik het toetsenbordicoon rechtsbeneden.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 95,
              child: GestureDetector(
                onTap: _showBarcodeInputDialog,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(CupertinoIcons.keyboard, color: Colors.white, size: 26),
                ),
              ),
            ),
            if (_isLoadingProduct)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CupertinoActivityIndicator(radius: 16)),
              ),
          ],
        ),
      ),
    );
  }
}
