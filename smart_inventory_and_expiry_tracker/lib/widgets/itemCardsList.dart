import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item.dart';
import '../providers/inventory_filter_provider.dart';
import '../providers/inventory_items_provider.dart';
import '../screens/edit_product_screen.dart';
import '../providers/theme_provider.dart';
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
      await ref.read(inventoryServiceProvider).deleteItem(item.id);
    } catch (e) {
      if (!mounted) {
        return;
      }
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
      return const Color(0xFFD32F2F);
    }
    if (item.isUseSoon) {
      return const Color(0xFFEB6B00);
    }
    return const Color(0xFF38873A);
  }

  Widget _buildCard(BuildContext context, InventoryItem item) {
    final statusLabel = _statusLabelForItem(item);
    final statusColor = _statusColorForItem(item);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ItemCard(
        title: item.title,
        subtitle: item.subtitle,
        imageUrl: item.imageUrl,
        statusLabel: statusLabel,
        statusColor: statusColor,

        deleteButtonColor: null,
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
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return itemsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 28.0),
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Text(
          'Firestore error: $error',
              style: TextStyle(color: isDark ? AppColors.darkText : AppColors.lightText),
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
              style: TextStyle(color: isDark ? AppColors.darkText : AppColors.lightText),
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
