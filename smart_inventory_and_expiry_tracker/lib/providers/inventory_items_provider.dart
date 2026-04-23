import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_item.dart';
import '../services/firestore_inventory_service.dart';

final inventoryServiceProvider = Provider<FirestoreInventoryService>((ref) {
  return FirestoreInventoryService();
});

final inventoryItemsProvider = StreamProvider<List<InventoryItem>>((ref) {
  final inventoryService = ref.watch(inventoryServiceProvider);
  return inventoryService.watchAllItems();
});