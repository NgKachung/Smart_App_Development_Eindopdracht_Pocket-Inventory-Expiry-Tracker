import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/firestore_inventory_service.dart';

/// Manual product add screen. Uses the app's Cupertino styling.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final FirestoreInventoryService _inventoryService = FirestoreInventoryService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  // OpenFoodFacts related fields
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  // (packaging, ingredients and nutrition removed — not needed for manual add)

  // status is derived automatically from the expiry date
  DateTime? _expiryDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _pickExpiryDate() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            SizedBox(
              height: 240,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _expiryDate ?? DateTime.now().add(const Duration(days: 7)),
                minimumDate: DateTime(2000),
                maximumDate: DateTime(2100),
                onDateTimeChanged: (d) => setState(() => _expiryDate = d),
              ),
            ),
            CupertinoButton(child: const Text('Done'), onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    final title = _titleController.text.trim();
    final subtitle = _subtitleController.text.trim();
    final description = _descriptionController.text.trim();
    final imageUrl = _imageUrlController.text.trim();
    final stockCount = int.tryParse(_stockController.text.trim()) ?? 0;

    final barcode = _barcodeController.text.trim();
    final brand = _brandController.text.trim();
    final quantity = _quantityController.text.trim();

    if (title.isEmpty || description.isEmpty || _expiryDate == null) {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Validation'),
          content: const Text('Please provide a title, description and an expiry date.'),
          actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.of(context).pop())],
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _inventoryService.addItem(
        title: title,
        subtitle: subtitle,
        description: description,
        expiryDate: _expiryDate!,
        stockCount: stockCount,
        barcode: barcode,
        brand: brand,
        quantity: quantity,
        imageUrl: imageUrl,
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Save failed'),
          content: Text('Could not save product to Firestore.\n$e'),
          actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.of(context).pop())],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Add product')),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            const Text('Title', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            CupertinoTextField(controller: _titleController, placeholder: 'Product name'),
            const SizedBox(height: 16),

            const Text('Short description', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            CupertinoTextField(controller: _subtitleController, placeholder: 'Short subtitle'),
            const SizedBox(height: 16),

            const Text('Description', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _descriptionController,
              placeholder: 'Full product description',
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            const Text('Image URL (optional)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            CupertinoTextField(controller: _imageUrlController, placeholder: 'https://...'),
            const SizedBox(height: 16),

            const Text('Barcode (EAN/GTIN)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            CupertinoTextField(controller: _barcodeController, placeholder: 'e.g. 8712100876543', keyboardType: TextInputType.number),
            const SizedBox(height: 16),

            const Text('Brand', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            CupertinoTextField(controller: _brandController, placeholder: 'Brand name'),
            const SizedBox(height: 16),

            const Text('Quantity (pack size)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            CupertinoTextField(controller: _quantityController, placeholder: 'e.g. 500 g, 1 L'),
            const SizedBox(height: 16),

            // packaging / ingredients removed per request

            // Status is derived from expiry date; manual selector removed
            const SizedBox.shrink(),
            const SizedBox(height: 16),

            const Text('Stock count', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            CupertinoTextField(controller: _stockController, placeholder: '0', keyboardType: TextInputType.number),
            const SizedBox(height: 16),

            // nutrition removed per request

            const Text('Expiry date', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Text(_expiryDate == null ? 'No date chosen' : _expiryDate!.toLocal().toString().split(' ')[0])),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _pickExpiryDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Pick date', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),

            const SizedBox(height: 32),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _isSaving ? null : _save,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                    ),
                    child: Center(
                      child: _isSaving
                          ? const CupertinoActivityIndicator(color: Colors.white)
                          : const Text('Save product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
          ]),
        ),
      ),
    );
  }
}
