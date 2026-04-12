import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.stockCount,
    required this.expiryDate,
    this.imageUrl,
    this.brand,
    this.quantity,
    this.barcode,
    this.source,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String? imageUrl;
  final String? brand;
  final String? quantity;
  final String? barcode;
  final String? source;
  final int stockCount;
  final DateTime expiryDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  bool get isUseSoon {
    final now = DateTime.now();
    final difference = expiryDate.difference(DateTime(now.year, now.month, now.day)).inDays;
    return difference >= 0 && difference <= 7;
  }

  factory InventoryItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    return InventoryItem(
      id: doc.id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true ? data['title'] as String : 'Untitled product',
      subtitle: (data['subtitle'] as String?)?.trim().isNotEmpty == true
          ? data['subtitle'] as String
          : (data['quantity'] as String?) ?? 'No subtitle',
      description: (data['description'] as String?)?.trim().isNotEmpty == true
          ? data['description'] as String
          : (data['subtitle'] as String?) ?? 'No description available.',
      imageUrl: data['imageUrl'] as String?,
      brand: data['brand'] as String?,
      quantity: data['quantity'] as String?,
      barcode: data['barcode'] as String?,
      source: data['source'] as String?,
      stockCount: _readInt(data['stockCount']) ?? 0,
      expiryDate: _readDateTime(data['expiryDate']) ?? DateTime.now(),
      createdAt: _readDateTime(data['createdAt']),
      updatedAt: _readDateTime(data['updatedAt']),
    );
  }

  static int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}