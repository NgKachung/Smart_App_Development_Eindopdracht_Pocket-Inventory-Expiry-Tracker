import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/inventory_filter_provider.dart';
import '../providers/inventory_items_provider.dart';
import '../services/notification_service.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/itemCardsList.dart';
import '../widgets/expiration_list.dart';
import 'profile_screen.dart';
import '../widgets/top_navigation_bar.dart';
import 'camera_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;
  String _searchQuery = '';
  bool _notificationsSynced = false;

  void _syncNotificationsOnce() {
    if (_notificationsSynced) return;

    ref.listenManual(inventoryItemsProvider, (previous, next) {
      if (next.hasValue && !_notificationsSynced) {
        NotificationService().rescheduleAllNotifications(next.value!);
        setState(() => _notificationsSynced = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncNotificationsOnce();

    final navTitle = _selectedIndex == 2
        ? 'My profile'
        : (_selectedIndex == 1 ? 'Expiration' : 'Inventory');
    final displayMode = ref.watch(inventoryDisplayModeProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoTopNavigationBar(
        title: navTitle,
        showSearch: _selectedIndex == 0,
        onSearch: (query) {
          setState(() => _searchQuery = query);
        },
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SafeArea(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      // Dashboard (cards list)
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: CupertinoSlidingSegmentedControl<InventoryDisplayMode>(
                                groupValue: displayMode,
                                children: const {
                                  InventoryDisplayMode.all: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text('All'),
                                  ),
                                  InventoryDisplayMode.expiringSoon: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text('Use soon'),
                                  ),
                                  InventoryDisplayMode.lowStock: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Text('Low stock'),
                                  ),
                                },
                                onValueChanged: (value) {
                                  if (value == null) return;
                                  ref.read(inventoryDisplayModeProvider.notifier).setMode(value);
                                },
                              ),
                            ),
                            ItemCardsList(searchQuery: _searchQuery),
                          ],
                        ),
                      ),

                      // Expiration: show only soon-to-expire cards
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Column(children: const [ExpirationList()]),
                      ),

                      // Profile
                      const ProfileScreen(),
                    ],
                  ),
                ),
              ),

              // Bottom navigation bar
              AppBottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (i) => setState(() {
                  _selectedIndex = i;
                  if (i != 0) {
                    _searchQuery = '';
                  }
                  ref.read(inventoryDisplayModeProvider.notifier).setMode(
                        InventoryDisplayMode.all,
                      );
                }),
              ),
            ],
          ),

          if (_selectedIndex != 2)
            // Floating QR button — shown on non-profile tabs, above bottom bar.
            Positioned(
              right: 18,
              bottom: 110,
              child: GestureDetector(
                onTap: () async {
                  // Open camera screen for QR scanning (implementation later)
                  if (!mounted) return;
                  Navigator.of(context).push(CupertinoPageRoute(builder: (_) => const CameraScreen()));
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
                  ),
                  child: const Icon(Icons.qr_code, color: Colors.white, size: 30),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
