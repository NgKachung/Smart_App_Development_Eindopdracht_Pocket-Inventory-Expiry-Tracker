import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<void> showItemDetailSheet({
  required BuildContext context,
  required String title,
  required String description,
  String? imageUrl,
  required int stockCount,
  required DateTime expiryDate,
  Future<void> Function()? onEdit,
}) async {
  final now = DateTime.now();
  final daysDiff = expiryDate.difference(DateTime(now.year, now.month, now.day)).inDays;

  Color indicatorColor;
  String indicatorText;

  if (daysDiff < 0) {
    indicatorColor = Colors.red;
    indicatorText = '${-daysDiff} day(s) overdue';
  } else {
    if (daysDiff <= 2) {
      indicatorColor = Colors.red;
    } else if (daysDiff <= 7) {
      indicatorColor = Colors.orange;
    } else {
      indicatorColor = Colors.green.shade700;
    }
    indicatorText = '$daysDiff day(s) before it expires';
  }

  // Use a Cupertino-style popup to ensure compatibility with CupertinoApp
  await showCupertinoModalPopup<void>(
    context: context,
    builder: (ctx) {
      final height = MediaQuery.of(ctx).size.height * 0.6;
      return Container(
        height: height,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // drag handle
            Container(
              width: 48,
              height: 6,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // extra gap so content isn't right under the top
            const SizedBox(height: 12),

            // main scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(CupertinoIcons.photo, size: 56, color: Colors.grey),
                                ),
                              )
                            : const Center(
                                child: Icon(CupertinoIcons.photo, size: 56, color: Colors.grey),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(description, style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Stock: $stockCount', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 24),
                        Text('Expiry date: ${expiryDate.day.toString().padLeft(2, '0')}/${expiryDate.month.toString().padLeft(2, '0')}/${expiryDate.year}', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // indicator anchored at bottom with gap
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: indicatorColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                indicatorText,
                textAlign: TextAlign.center,
                style: TextStyle(color: indicatorColor, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),

            if (onEdit != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await onEdit();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Edit',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
