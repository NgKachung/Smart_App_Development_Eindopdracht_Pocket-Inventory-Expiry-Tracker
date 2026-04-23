import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

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
    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (rotation == null || format == null) {
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
                  'Richt de camera op een barcode\nof gebruik het toetsenbordicoon rechtsboven.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 24,
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
