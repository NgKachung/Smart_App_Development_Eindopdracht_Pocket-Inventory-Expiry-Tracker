import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/inventory_item.dart';
import 'notification_service.dart';

class FirestoreInventoryService {
  FirestoreInventoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService = NotificationService();

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _itemsCollection {
    final userId = _userId;
    if (userId == null) {
      return null;
    }

    return _firestore.collection('users').doc(userId).collection('inventory_items');
  }

  Stream<List<InventoryItem>> watchAllItems() {
    final collection = _itemsCollection;
    if (collection == null) {
      return Stream.value(const <InventoryItem>[]);
    }

    return collection
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs.map(InventoryItem.fromFirestore).toList();
          items.sort((left, right) => left.expiryDate.compareTo(right.expiryDate));
          return items;
        });
  }

  Future<void> deleteItem(String id) async {
    final collection = _itemsCollection;
    if (collection == null) {
      throw StateError('No signed-in user found.');
    }

    await _notificationService.cancelNotifications(id);
    return collection.doc(id).delete();
  }

  Future<void> addItem({
    required String title,
    required String subtitle,
    required String description,
    required DateTime expiryDate,
    required int stockCount,
    required String barcode,
    required String brand,
    required String quantity,
    required String imageUrl,
    String source = 'manual',
  }) async {
    final collection = _itemsCollection;
    if (collection == null) {
      throw StateError('No signed-in user found.');
    }

    final now = DateTime.now();
    final normalizedImageUrl = imageUrl.trim().isEmpty ? null : imageUrl.trim();

    final docRef = await collection.add({
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'expiryDate': expiryDate,
      'stockCount': stockCount,
      'barcode': barcode,
      'brand': brand,
      'quantity': quantity,
      'imageUrl': normalizedImageUrl,
      'source': source,
      'createdAt': now,
      'updatedAt': now,
    });

    final item = InventoryItem(
      id: docRef.id,
      title: title,
      subtitle: subtitle,
      description: description,
      stockCount: stockCount,
      expiryDate: expiryDate,
      imageUrl: normalizedImageUrl,
      brand: brand,
      quantity: quantity,
      barcode: barcode,
      source: source,
      createdAt: now,
      updatedAt: now,
    );

    await _notificationService.scheduleExpiryNotifications(item);
  }

  Future<void> updateItem({
    required String id,
    required String title,
    required String subtitle,
    required String description,
    required DateTime expiryDate,
    required int stockCount,
    required String barcode,
    required String brand,
    required String quantity,
    required String imageUrl,
  }) async {
    final collection = _itemsCollection;
    if (collection == null) {
      throw StateError('No signed-in user found.');
    }

    final normalizedImageUrl = imageUrl.trim().isEmpty ? null : imageUrl.trim();

    await collection.doc(id).update({
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'expiryDate': expiryDate,
      'stockCount': stockCount,
      'barcode': barcode,
      'brand': brand,
      'quantity': quantity,
      'imageUrl': normalizedImageUrl,
      'updatedAt': DateTime.now(),
    });

    final item = InventoryItem(
      id: id,
      title: title,
      subtitle: subtitle,
      description: description,
      stockCount: stockCount,
      expiryDate: expiryDate,
      imageUrl: normalizedImageUrl,
      brand: brand,
      quantity: quantity,
      barcode: barcode,
    );

    // Cancel old notifications and re-schedule
    await _notificationService.cancelNotifications(id);
    await _notificationService.scheduleExpiryNotifications(item);
  }
}