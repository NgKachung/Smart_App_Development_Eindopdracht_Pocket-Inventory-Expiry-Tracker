import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/open_food_facts_service.dart';
import 'add_product_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _isHandlingScan = false;
  bool _isLoadingProduct = false;
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processBarcode(String barcode) async {
    final normalized = barcode.trim();
    if (normalized.isEmpty || _isLoadingProduct) {
      return;
    }

    setState(() => _isLoadingProduct = true);
    try {
      final product = await _openFoodFactsService.fetchProductByBarcode(normalized);

      if (!mounted) return;

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
              builder: (_) => AddProductScreen(prefilledBarcode: normalized),
            ),
          );
        }
      } else {
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
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isHandlingScan || _isLoadingProduct) {
      return;
    }

    String? foundValue;
    for (final code in capture.barcodes) {
      final value = code.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        foundValue = value;
        break;
      }
    }

    if (foundValue == null) {
      return;
    }

    _isHandlingScan = true;
    try {
      await _scannerController.stop();
      await _processBarcode(foundValue);
    } finally {
      _isHandlingScan = false;
      if (mounted) {
        await _scannerController.start();
      }
    }
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
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Scan barcode'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showBarcodeInputDialog,
          child: const Icon(CupertinoIcons.keyboard),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Camera error: $error', textAlign: TextAlign.center),
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Richt de camera op een barcode\nof gebruik het toetsenbordicoon rechtsboven.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
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
