import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/inventory_item.dart';
import '../services/firestore_inventory_service.dart';
import 'itemCard.dart';
import 'item_detail_sheet.dart';

/// A simple expiration list: shows only items that are "use soon" / yellow-orange.
class ExpirationList extends StatelessWidget {
  const ExpirationList({super.key});

  static final FirestoreInventoryService _inventoryService = FirestoreInventoryService();

  Widget _buildCard(BuildContext context, InventoryItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ItemCard(
        title: item.title,
        subtitle: item.subtitle,
        imageUrl: item.imageUrl,
        statusLabel: item.isExpired ? 'EXPIRED' : 'USE SOON',
        statusColor: item.isExpired ? const Color(0xFFFFE6E6) : const Color(0xFFF7D9BD),
        borderColor: item.isExpired ? const Color(0xFFD32F2F) : null,
        stockCount: item.stockCount,
        onTap: () {
          showItemDetailSheet(
            context: context,
            title: item.title,
            description: item.description,
            imageUrl: item.imageUrl,
            stockCount: item.stockCount,
            expiryDate: item.expiryDate,
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

        final items = (snapshot.data ?? const <InventoryItem>[])
            .where((item) => item.isUseSoon || item.isExpired)
            .toList();

        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Text(
              'Geen items die bijna verlopen of verlopen zijn voor dit account.',
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
