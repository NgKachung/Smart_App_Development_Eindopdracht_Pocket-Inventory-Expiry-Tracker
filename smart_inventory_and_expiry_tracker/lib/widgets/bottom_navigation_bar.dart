import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A simple bottom navigation bar with three items: Dashboard, Expiration, Profile.
///
/// Items are equal width; icon is always above the label. Active item shows
/// a rounded pill background but does not change item width to prevent shifts.
class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  static const _activeBg = Color(0xFFD8F6E8);
  static const _activeText = Color(0xFF0F6B4A);
  static const _inactiveText = Color(0xFF7A7A7A);

  Widget _buildItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final active = index == currentIndex;
    final textStyle = TextStyle(
      fontSize: 12,
      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      color: active ? _activeText : _inactiveText,
      letterSpacing: 0.6,
    );

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: active
                ? BoxDecoration(
                    color: _activeBg,
                    borderRadius: BorderRadius.circular(24),
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(active ? icon : icon, color: active ? _activeText : _inactiveText, size: 20),
                const SizedBox(height: 6),
                Text(label.toUpperCase(), style: textStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: _buildItem(
                context: context,
                index: 0,
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
              ),
            ),
            Expanded(
              child: _buildItem(
                context: context,
                index: 1,
                icon: Icons.schedule,
                label: 'Expiration',
              ),
            ),
            Expanded(
              child: _buildItem(
                context: context,
                index: 2,
                icon: Icons.person_outline,
                label: 'Profile',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
