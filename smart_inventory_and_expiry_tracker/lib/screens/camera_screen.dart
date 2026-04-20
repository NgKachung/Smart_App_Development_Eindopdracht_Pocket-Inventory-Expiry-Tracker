import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/open_food_facts_service.dart';
import 'add_product_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isReady = false;
  String? _error;
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('No cameras available');
      _controller = CameraController(cameras.first, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isReady = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _showBarcodeInputDialog() async {
    final barcodeController = TextEditingController();
    bool isLoading = false;

    return showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => CupertinoAlertDialog(
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

                      setState(() => isLoading = true);

                      try {
                        final product = await _openFoodFactsService.fetchProductByBarcode(barcode);

                        if (!mounted) return;

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
                        if (!mounted) return;

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
        middle: Text('Scan QR'),
      ),
      child: SafeArea(
        child: _error != null
            ? Center(child: Text('Camera error: $_error'))
            : (_isReady && _controller != null)
                ? Stack(
                    children: [
                      Center(child: CameraPreview(_controller!)),
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
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
                            ),
                            child: const Icon(CupertinoIcons.add, color: Colors.white, size: 28),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(child: CupertinoActivityIndicator()),
      ),
    );
  }
}
