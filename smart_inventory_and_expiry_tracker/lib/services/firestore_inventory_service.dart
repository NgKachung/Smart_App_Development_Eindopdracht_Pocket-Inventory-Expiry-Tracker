import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/inventory_item.dart';

class FirestoreInventoryService {
  FirestoreInventoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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

  Future<void> deleteItem(String id) {
    final collection = _itemsCollection;
    if (collection == null) {
      throw StateError('No signed-in user found.');
    }

    return collection.doc(id).delete();
  }
}