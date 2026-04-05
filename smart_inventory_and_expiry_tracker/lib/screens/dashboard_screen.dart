import 'package:flutter/cupertino.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../widgets/itemCardsList.dart';
import 'profile_screen.dart';
import '../widgets/top_navigation_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  Future<void> _logout(BuildContext context) async {
    await AuthService().signOut();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService().currentUser?.email ?? 'Unknown user';
    final navTitle = _selectedIndex == 2
        ? 'Profile'
        : (_selectedIndex == 1 ? 'Expiration' : 'Inventory');

    return CupertinoPageScaffold(
      navigationBar: CupertinoTopNavigationBar(
        title: navTitle,
        showSearch: _selectedIndex == 0,
        onSearch: _selectedIndex == 0 ? (query) {
          // TODO: pass search query to cards list when implemented
        } : null,
      ),
      child: Column(
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

                  // Expiration placeholder
                  const Center(child: Text('Expiration - coming soon')),

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
    );
  }
}
