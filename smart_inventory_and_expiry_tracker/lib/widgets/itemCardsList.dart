import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../screens/edit_product_screen.dart';
import '../services/firestore_inventory_service.dart';
import 'itemCard.dart';
import 'item_detail_sheet.dart';

class ItemCardsList extends StatefulWidget {
  const ItemCardsList({super.key});

  @override
  State<ItemCardsList> createState() => _ItemCardsListState();
}

class _ItemCardsListState extends State<ItemCardsList> {
  final FirestoreInventoryService _inventoryService = FirestoreInventoryService();

  Future<void> _confirmAndDelete(BuildContext context, InventoryItem item) async {
    final shouldDelete = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Verwijderen?'),
        content: Text('Weet je zeker dat je "${item.title}" wilt verwijderen?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuleren'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Verwijderen'),
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
      if (!mounted) {
        return;
      }
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('Verwijderen mislukt'),
          content: Text('Kon item niet verwijderen.\n$e'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  String _statusLabelForItem(InventoryItem item) {
    if (item.isExpired) {
      return 'EXPIRED';
    }
    if (item.isUseSoon) {
      return 'USE SOON';
    }
    return 'FRESH';
  }

  Color _statusColorForItem(InventoryItem item) {
    if (item.isExpired) {
      return const Color(0xFFFFE6E6);
    }
    if (item.isUseSoon) {
      return const Color(0xFFF7D9BD);
    }
    return const Color(0xFFDFF7D9);
  }

  Widget _buildCard(BuildContext context, InventoryItem item) {
    final statusLabel = _statusLabelForItem(item);
    final statusColor = _statusColorForItem(item);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ItemCard(
        title: item.title,
        subtitle: item.subtitle,
        imageUrl: item.imageUrl,
        statusLabel: statusLabel,
        statusColor: statusColor,
        borderColor: item.isExpired ? const Color(0xFFD32F2F) : null,
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
              style: TextStyle(color: Colors.grey.shade700),
            ),
          );
        }

        final items = snapshot.data ?? const <InventoryItem>[];

        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Text(
              'Geen producten gevonden voor dit account.',
              style: TextStyle(color: Colors.grey.shade700),
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
