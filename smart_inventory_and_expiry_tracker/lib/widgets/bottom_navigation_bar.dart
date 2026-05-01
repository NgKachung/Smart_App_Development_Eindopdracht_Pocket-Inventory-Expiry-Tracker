import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Widget _buildItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final active = index == currentIndex;

    final activeBg = isDark ? const Color(0xFF1B3D1B) : const Color(0xFFD8F6E8);
    final activeText = isDark ? const Color(0xFF4CAF50) : const Color(0xFF0F6B4A);
    final inactiveText = isDark ? const Color(0xFF888888) : const Color(0xFF7A7A7A);

    final textStyle = TextStyle(
      fontSize: 12,
      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      color: active ? activeText : inactiveText,
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
                    color: activeBg,
                    borderRadius: BorderRadius.circular(24),
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: active ? activeText : inactiveText, size: 20),
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
    final theme = CupertinoTheme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: theme.scaffoldBackgroundColor,
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
