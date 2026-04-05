import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'itemCard.dart';

class ItemCardsList extends StatelessWidget {
  const ItemCardsList({super.key});

  @override
  Widget build(BuildContext context) {
    // Example colors matching Fresh / Use Soon / Expired
    final freshBg = const Color(0xFFDFF7D9);
    final soonBg = const Color(0xFFF7D9BD);
    final expiredBg = const Color(0xFFF4C6C6);

    return Column(
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: ItemCard(
            title: 'Mild & Creamy Naturel met Kokos',
            subtitle: 'Lekker exotisch wakker worden, dat doe je met onze zijdeachtige...',
            statusLabel: 'FRESH',
            statusColor: Color(0xFFDFF7D9),
            stockCount: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: ItemCard(
            title: 'Douwe Egberts Moka Royal',
            subtitle: 'De warmste momenten van de dag beleef je met Douwe Egberts omdat...',
            statusLabel: 'USE SOON',
            statusColor: Color(0xFFF7D9BD),
            stockCount: 4,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: ItemCard(
            title: 'Coca-Cola | Original taste',
            subtitle: 'De enige echte Coca-Cola. Al sinds 1886...',
            statusLabel: 'EXPIRED',
            statusColor: Color(0xFFF4C6C6),
            stockCount: 8,
          ),
        ),
      ],
    );
  }
}
