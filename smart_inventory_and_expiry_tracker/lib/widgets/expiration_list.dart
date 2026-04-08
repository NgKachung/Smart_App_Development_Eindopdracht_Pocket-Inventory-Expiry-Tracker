import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'itemCard.dart';
import 'item_detail_sheet.dart';

/// A simple expiration list: shows only items that are "use soon" / yellow-orange.
class ExpirationList extends StatelessWidget {
  const ExpirationList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ItemCard(
            title: 'Douwe Egberts Moka Royal',
            subtitle: 'De warmste momenten van de dag beleef je met Douwe Egberts omdat...',
            statusLabel: 'USE SOON',
            statusColor: const Color(0xFFF7D9BD),
            stockCount: 4,
            onTap: () {
              // ignore: avoid_print
              print('Tapped Douwe Egberts Moka Royal (Expiration)');
              showItemDetailSheet(
                context: context,
                title: 'Douwe Egberts Moka Royal',
                description: 'Moka Royal is een uitgesproken koffie. Een krachtig samenspel van gemalen Arabica- en Robustabonen.',
                stockCount: 4,
                expiryDate: DateTime.now().add(const Duration(days: 1)),
              );
            },
          ),
        ),

        // Also show expired items in this tab, with a subtle red background
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ItemCard(
            title: 'Coca-Cola | Original taste',
            subtitle: 'De klassieke Coca-Cola in flessen en blik. Perfect koud.',
            statusLabel: 'EXPIRED',
            statusColor: const Color(0xFFFFE6E6),
            borderColor: const Color(0xFFD32F2F),
            stockCount: 8,
            onTap: () {
              // ignore: avoid_print
              print('Tapped Coca-Cola | Original taste (Expiration)');
              showItemDetailSheet(
                context: context,
                title: 'Coca-Cola | Original taste',
                description: 'De klassieke Coca-Cola in flessen en blik. Perfect koud.',
                stockCount: 8,
                expiryDate: DateTime.now().subtract(const Duration(days: 3)),
              );
            },
          ),
        ),

        // If you later populate from a backend, map and filter items here by expiry level.
      ],
    );
  }
}
