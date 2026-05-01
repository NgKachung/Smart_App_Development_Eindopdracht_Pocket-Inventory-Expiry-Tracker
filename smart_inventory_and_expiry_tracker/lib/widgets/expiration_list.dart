import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../screens/edit_product_screen.dart';
import '../services/firestore_inventory_service.dart';
import 'itemCard.dart';
import 'item_detail_sheet.dart';

/// A simple expiration list: shows only items that are "use soon" / yellow-orange.
class ExpirationList extends StatelessWidget {
  const ExpirationList({super.key});

  static final FirestoreInventoryService _inventoryService = FirestoreInventoryService();

  Future<void> _confirmAndDelete(BuildContext context, InventoryItem item) async {
    final shouldDelete = await showAdaptiveDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog.adaptive(
        title: const Text('Verwijderen?'),
        content: Text('Weet je zeker dat je "${item.title}" wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Verwijderen',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _inventoryService.deleteItem(item.id);
    } catch (e) {
      await showAdaptiveDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog.adaptive(
          title: const Text('Verwijderen mislukt'),
          content: Text('Kon item niet verwijderen.\n$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildCard(BuildContext context, InventoryItem item) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ItemCard(
        title: item.title,
        subtitle: item.subtitle,
        imageUrl: item.imageUrl,
        statusLabel: item.isExpired ? 'EXPIRED' : 'USE SOON',
        statusColor: item.isExpired 
            ? const Color(0xFFD32F2F) 
            : const Color(0xFFEB6B00),
        backgroundColor: item.isExpired 
            ? (isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFAF9F9)) 
            : null,
        stockCount: item.stockCount,
        onDelete: () => _confirmAndDelete(context, item),
        onTap: () {
          showItemDetailSheet(
            context: context,
            title: item.title,
            description: item.description,
            imageUrl: item.imageUrl,
            stockCount: item.stockCount,
            expiryDate: item.expiryDate,
            onEdit: () async {
              await Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => EditProductScreen(item: item)),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    
    return StreamBuilder<List<InventoryItem>>(
      stream: _inventoryService.watchAllItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28.0),
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Text(
              'Firestore error: ${snapshot.error}',
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          );
        }

        final items = (snapshot.data ?? const <InventoryItem>[])
            .where((item) => item.isUseSoon || item.isExpired)
            .toList();

        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text(
              'Geen items die bijna verlopen of verlopen zijn voor dit account.',
              style: TextStyle(color: CupertinoColors.secondaryLabel),
            ),
          );
        }

        return Column(
          children: items.map((item) => _buildCard(context, item)).toList(),
        );
      },
    );
  }
}
