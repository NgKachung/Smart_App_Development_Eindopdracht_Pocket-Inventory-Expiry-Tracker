import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String statusLabel;
  final Color statusColor;
  final int stockCount;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? deleteButtonColor;

  const ItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    required this.statusLabel,
    required this.statusColor,
    required this.stockCount,
    this.onDelete,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.deleteButtonColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: borderColor != null ? Border(left: BorderSide(width: 6, color: borderColor!)) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image / thumbnail
            Container(
              width: 84,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? Image.network(imageUrl!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(CupertinoIcons.photo))
                    : const Icon(CupertinoIcons.photo, size: 40, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),

            // Text area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),

                  // Status label with stock below
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel.toUpperCase(),
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('In stock: $stockCount', style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),

            // Delete button
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: deleteButtonColor ?? Colors.green.shade700,
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.delete, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
