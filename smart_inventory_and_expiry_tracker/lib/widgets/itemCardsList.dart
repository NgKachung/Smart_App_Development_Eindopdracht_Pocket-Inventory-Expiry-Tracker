import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'itemCard.dart';
import 'item_detail_sheet.dart';

class ItemCardsList extends StatelessWidget {
  const ItemCardsList({super.key});

  @override
  Widget build(BuildContext context) {
    // Example colors matching Fresh / Use Soon / Expired

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ItemCard(
            title: 'Mild & Creamy Naturel met Kokos',
            subtitle: 'Lekker exotisch wakker worden, dat doe je met onze zijdeachtige...',
            statusLabel: 'FRESH',
            statusColor: const Color(0xFFDFF7D9),
            stockCount: 1,
            onTap: () {
              // debug: confirm tap
              // ignore: avoid_print
              print('Tapped Mild & Creamy Naturel met Kokos');
              showItemDetailSheet(
              context: context,
              title: 'Mild & Creamy Naturel met Kokos',
              description: 'Lekker exotisch wakker worden, dat doe je met onze zijdeachtige kokosvariant. Heerlijk op je brood of in de smoothie.',
              stockCount: 1,
              expiryDate: DateTime.now().add(const Duration(days: 10)),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ItemCard(
            title: 'Douwe Egberts Moka Royal',
            subtitle: 'De warmste momenten van de dag beleef je met Douwe Egberts omdat...',
            statusLabel: 'USE SOON',
            statusColor: const Color(0xFFF7D9BD),
            stockCount: 4,
            onTap: () {
              // debug: confirm tap
              // ignore: avoid_print
              print('Tapped Douwe Egberts Moka Royal');
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ItemCard(
            title: 'Coca-Cola | Original taste',
            subtitle: 'De enige echte Coca-Cola. Al sinds 1886...',
            statusLabel: 'EXPIRED',
            statusColor: const Color(0xFFFFE6E6),
            borderColor: const Color(0xFFD32F2F),
            stockCount: 8,
            onTap: () {
              // debug: confirm tap
              // ignore: avoid_print
              print('Tapped Coca-Cola | Original taste');
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
      ],
    );
  }
}
