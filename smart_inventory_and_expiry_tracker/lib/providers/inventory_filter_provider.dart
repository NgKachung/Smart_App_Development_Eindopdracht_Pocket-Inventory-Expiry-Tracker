import 'package:flutter_riverpod/flutter_riverpod.dart';

enum InventoryDisplayMode {
  all,
  expiringSoon,
  lowStock,
}

class InventoryDisplayModeNotifier extends Notifier<InventoryDisplayMode> {
  @override
  InventoryDisplayMode build() => InventoryDisplayMode.all;

  void setMode(InventoryDisplayMode mode) {
    state = mode;
  }
}

final inventoryDisplayModeProvider =
    NotifierProvider<InventoryDisplayModeNotifier, InventoryDisplayMode>(
  InventoryDisplayModeNotifier.new,
);