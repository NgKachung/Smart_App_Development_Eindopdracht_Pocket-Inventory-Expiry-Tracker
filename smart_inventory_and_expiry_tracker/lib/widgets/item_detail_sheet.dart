import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:io';

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
  final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

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
      indicatorColor = isDark ? Colors.green.shade400 : Colors.green.shade700;
    }
    indicatorText = '$daysDiff day(s) before it expires';
  }

  Widget buildContent(BuildContext ctx) {
    final theme = CupertinoTheme.of(ctx);
    final height = MediaQuery.of(ctx).size.height * 0.6;
    
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(CupertinoIcons.photo, size: 56, color: isDark ? Colors.grey.shade700 : Colors.grey),
                              ),
                            )
                          : Center(
                              child: Icon(CupertinoIcons.photo, size: 56, color: isDark ? Colors.grey.shade700 : Colors.grey),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  Text(
                    title, 
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      description, 
                      style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600), 
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Stock: ', 
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$stockCount', 
                        style: const TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        'Expiry date: ${expiryDate.day.toString().padLeft(2, '0')}/${expiryDate.month.toString().padLeft(2, '0')}/${expiryDate.year}', 
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

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
                    color: isDark ? Colors.green.shade600 : Colors.green.shade700,
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
  }

  if (Platform.isIOS) {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => buildContent(ctx),
    );
  } else {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => buildContent(ctx),
    );
  }
}
