import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../widgets/bottom_navigation_bar.dart';
import '../widgets/itemCardsList.dart';
import '../widgets/expiration_list.dart';
import 'profile_screen.dart';
import '../widgets/top_navigation_bar.dart';
import 'camera_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // Logout helper removed (not referenced). Use AuthService().signOut() where needed.

  @override
  Widget build(BuildContext context) {
    final navTitle = _selectedIndex == 2
        ? 'My profile'
        : (_selectedIndex == 1 ? 'Expiration' : 'Inventory');

    return CupertinoPageScaffold(
      navigationBar: CupertinoTopNavigationBar(
        title: navTitle,
        showSearch: _selectedIndex == 0,
        onSearch: _selectedIndex == 0 ? (query) {
          // TODO: pass search query to cards list when implemented
        } : null,
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
                        child: Column(children: const [ItemCardsList()]),
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
                onTap: (i) => setState(() => _selectedIndex = i),
              ),
            ],
          ),

          // Floating QR button — always above bottom bar, bottom-right
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
