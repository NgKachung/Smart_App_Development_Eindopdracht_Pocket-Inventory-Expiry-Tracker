import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_filter_provider.dart';
import '../providers/inventory_items_provider.dart';
import '../screens/edit_product_screen.dart';
import 'itemCard.dart';
import 'item_detail_sheet.dart';

class ItemCardsList extends ConsumerStatefulWidget {
  const ItemCardsList({
    super.key,
    this.searchQuery = '',
  });

  final String searchQuery;

  @override
  ConsumerState<ItemCardsList> createState() => _ItemCardsListState();
}

class _ItemCardsListState extends ConsumerState<ItemCardsList> {
  bool _matchesSearch(InventoryItem item, String searchQuery) {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return true;
    }

    final haystack = <String>[
      item.title,
      item.subtitle,
      item.description,
      item.brand ?? '',
      item.quantity ?? '',
      item.barcode ?? '',
    ].join(' ').toLowerCase();

    return haystack.contains(q);
  }

  bool _matchesDisplayMode(InventoryItem item, InventoryDisplayMode mode) {
    switch (mode) {
      case InventoryDisplayMode.all:
        return true;
      case InventoryDisplayMode.expiringSoon:
        return item.isExpired || item.isUseSoon;
      case InventoryDisplayMode.lowStock:
        return item.stockCount <= 5;
    }
  }

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
      await ref.read(inventoryServiceProvider).deleteItem(item.id);
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
        backgroundColor: item.isExpired ? const Color(0xFFFFF0F0) : null,
        borderColor: item.isExpired ? const Color(0xFFE57373) : null,
        deleteButtonColor: item.isExpired ? const Color(0xFFE57373) : null,
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
    final displayMode = ref.watch(inventoryDisplayModeProvider);
    final itemsAsync = ref.watch(inventoryItemsProvider);

    return itemsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 28.0),
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          'Firestore error: $error',
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ),
      data: (allItems) {
        final items = allItems
            .where((item) => _matchesSearch(item, widget.searchQuery))
            .where((item) => _matchesDisplayMode(item, displayMode))
            .toList(growable: false);

        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Text(
              widget.searchQuery.trim().isEmpty
                  ? 'Geen producten gevonden voor dit account.'
                  : 'Geen producten gevonden voor "${widget.searchQuery}".',
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
