import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../models/inventory_item.dart';
import '../services/firestore_inventory_service.dart';
import '../services/image_storage_service.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({
    super.key,
    required this.item,
  });

  final InventoryItem item;

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final FirestoreInventoryService _inventoryService = FirestoreInventoryService();
  final ImageStorageService _imageStorageService = ImageStorageService();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _stockController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _brandController;
  late final TextEditingController _quantityController;

  late DateTime _expiryDate;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  File? _selectedImage;
  bool _removeExistingImage = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _subtitleController = TextEditingController(text: widget.item.subtitle);
    _descriptionController = TextEditingController(text: widget.item.description);
    _imageUrlController = TextEditingController(text: widget.item.imageUrl ?? '');
    _stockController = TextEditingController(text: widget.item.stockCount.toString());
    _barcodeController = TextEditingController(text: widget.item.barcode ?? '');
    _brandController = TextEditingController(text: widget.item.brand ?? '');
    _quantityController = TextEditingController(text: widget.item.quantity ?? '');
    _expiryDate = widget.item.expiryDate;
  }

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
    if (Platform.isIOS) {
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
                  initialDateTime: _expiryDate,
                  minimumDate: DateTime(2000),
                  maximumDate: DateTime(2100),
                  onDateTimeChanged: (d) => setState(() => _expiryDate = d),
                ),
              ),
              CupertinoButton(
                child: const Text('Done'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    } else {
      showDatePicker(
        context: context,
        initialDate: _expiryDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      ).then((selectedDate) {
        if (selectedDate != null) {
          setState(() => _expiryDate = selectedDate);
        }
      });
    }
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    final title = _titleController.text.trim();
    final subtitle = _subtitleController.text.trim();
    final description = _descriptionController.text.trim();
    final manualImageUrl = _imageUrlController.text.trim();
    final stockCount = int.tryParse(_stockController.text.trim()) ?? 0;

    final barcode = _barcodeController.text.trim();
    final brand = _brandController.text.trim();
    final quantity = _quantityController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      showAdaptiveDialog(
        context: context,
        builder: (context) => AlertDialog.adaptive(
          title: const Text('Validation'),
          content: const Text('Please provide a title and description.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      var imageUrl = manualImageUrl;
      if (_selectedImage != null) {
        if (mounted) {
          setState(() => _isUploadingImage = true);
        }
        imageUrl = await _imageStorageService.uploadProductImage(imageFile: _selectedImage!);
      } else if (_removeExistingImage) {
        imageUrl = '';
      }

      await _inventoryService.updateItem(
        id: widget.item.id,
        title: title,
        subtitle: subtitle,
        description: description,
        expiryDate: _expiryDate,
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
      showAdaptiveDialog(
        context: context,
        builder: (context) => AlertDialog.adaptive(
          title: const Text('Save failed'),
          content: Text('Could not update product in Firestore.\n$e'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source, imageQuality: 85);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _removeExistingImage = false;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      showAdaptiveDialog(
        context: context,
        builder: (context) => AlertDialog.adaptive(
          title: const Text('Fout'),
          content: Text('Kon foto niet selecteren.\n$e'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showImageSourcePicker() async {
    if (_isSaving || _isUploadingImage) {
      return;
    }

    if (Platform.isIOS) {
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          title: const Text('Kies een foto'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                await _pickImage(ImageSource.camera);
              },
              child: const Text('Neem foto'),
            ),
            CupertinoActionSheetAction(
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                await _pickImage(ImageSource.gallery);
              },
              child: const Text('Kies uit galerij'),
            ),
            if (_selectedImage != null || _imageUrlController.text.trim().isNotEmpty)
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  setState(() {
                    _selectedImage = null;
                    _imageUrlController.clear();
                    _removeExistingImage = true;
                  });
                },
                child: const Text('Verwijder foto'),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Annuleren'),
          ),
        ),
      );
    } else {
      await showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Neem foto'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Kies uit galerij'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null || _imageUrlController.text.trim().isNotEmpty)
                ListTile(
                  leading: Icon(
                    Icons.delete, 
                    color: CupertinoTheme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF616161) 
                        : Colors.grey.shade600,
                  ),
                  title: Text(
                    'Verwijder foto', 
                    style: TextStyle(
                      color: CupertinoTheme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF616161) 
                          : Colors.grey.shade600,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    setState(() {
                      _selectedImage = null;
                      _imageUrlController.clear();
                      _removeExistingImage = true;
                    });
                  },
                ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildPhotoPickerCard() {
    final hasImage = _selectedImage != null || _imageUrlController.text.trim().isNotEmpty;

    return GestureDetector(
      onTap: _showImageSourcePicker,
      child: Container(
        width: double.infinity,
        height: 170,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDCDDE1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            children: [
              Positioned.fill(
                child: _isUploadingImage
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoActivityIndicator(),
                            SizedBox(height: 8),
                            Text('Foto uploaden...'),
                          ],
                        ),
                      )
                    : _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.contain)
                        : _imageUrlController.text.trim().isNotEmpty
                            ? Image.network(
                                _imageUrlController.text.trim(),
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => _buildPhotoPickerPlaceholder(hasImage),
                              )
                            : _buildPhotoPickerPlaceholder(hasImage),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xE6FFFFFF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFCBD2D9)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.hand_draw, size: 12, color: Color(0xFF5C6670)),
                      SizedBox(width: 5),
                      Text(
                        'Tik',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF5C6670)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPickerPlaceholder(bool hasImage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.camera,
            size: 28,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 8),
          Text(
            hasImage ? 'Tik om foto te wijzigen' : 'Tik om foto toe te voegen',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Edit product')),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text('Foto', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _buildPhotoPickerCard(),
              const SizedBox(height: 16),

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
              CupertinoTextField(
                controller: _barcodeController,
                placeholder: 'e.g. 8712100876543',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              const Text('Brand', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CupertinoTextField(controller: _brandController, placeholder: 'Brand name'),
              const SizedBox(height: 16),

              const Text('Quantity (pack size)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CupertinoTextField(controller: _quantityController, placeholder: 'e.g. 500 g, 1 L'),
              const SizedBox(height: 16),

              const Text('Stock count', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              CupertinoTextField(controller: _stockController, placeholder: '0', keyboardType: TextInputType.number),
              const SizedBox(height: 16),

              const Text('Expiry date', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _expiryDate.toLocal().toString().split(' ')[0],
                    ),
                  ),
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
                onTap: (_isSaving || _isUploadingImage) ? null : _save,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: (_isSaving || _isUploadingImage) ? Colors.grey.shade400 : Colors.green.shade700,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Center(
                    child: _isSaving
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text(
                            'Save changes',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
