import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'kitchen_display_screen.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = AuthService().currentUser;
    final email = user?.email ?? 'Unknown user';
    final createdAt = _formatDateTime(user?.metadata.creationTime);
    final lastSignInAt = _formatDateTime(user?.metadata.lastSignInTime);
    final accountId = user?.uid ?? 'Unavailable';
    final themeMode = ref.watch(themeProvider);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'My profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your account details and sign-in information.',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                _InfoCard(
                  title: 'App Theme',
                  children: [
                    const Text(
                      'Choose how the app looks for you.',
                      style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
                    ),
                    const SizedBox(height: 12),
                    CupertinoSlidingSegmentedControl<AppThemeMode>(
                      groupValue: themeMode,
                      children: const {
                        AppThemeMode.light: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('Light'),
                        ),
                        AppThemeMode.dark: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('Dark'),
                        ),
                        AppThemeMode.system: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('System'),
                        ),
                      },
                      onValueChanged: (value) {
                        if (value != null) {
                          ref.read(themeProvider.notifier).setTheme(value);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Account overview',
                  children: [
                    _InfoRow(
                      label: 'Signed in as',
                      value: email,
                      emphasize: true,
                      isDarkMode: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Security and activity',
                  children: [
                    _InfoRow(label: 'User ID', value: accountId, isDarkMode: isDark),
                    _InfoRow(label: 'Account created', value: createdAt, isDarkMode: isDark),
                    _InfoRow(label: 'Last sign in', value: lastSignInAt, isDarkMode: isDark),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'App modes',
                  children: [
                    const Text(
                      'Switch to a specialized view for tablet or kitchen hub use.',
                      style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const KitchenDisplayScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.square_grid_2x2, color: Colors.green.shade800),
                            const SizedBox(width: 8),
                            Text(
                              'Open Kitchen Mode',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    await AuthService().signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      CupertinoPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 138, 15, 15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Sign out',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'Unavailable';
    }

    final localValue = value.toLocal();
    final parts = localValue.toIso8601String().split('T');
    final date = parts.first;
    final time = parts.last.substring(0, 5);
    return '$date at $time';
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF333333) : const Color(0xFFDDE5DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    required this.isDarkMode,
  });

  final String label;
  final String value;
  final bool emphasize;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasize ? 17 : 15,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              color: isDarkMode ? AppColors.darkText : AppColors.lightText,
            ),
          ),
        ],
      ),
    );
  }
}
