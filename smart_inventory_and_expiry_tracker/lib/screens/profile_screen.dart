import 'package:flutter/cupertino.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = AuthService().currentUser?.email ?? 'Unknown user';

    // This widget renders only the profile body. The parent (e.g. Dashboard)
    // should provide the app-level navigation bar to avoid duplicate bars.
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Signed in as', style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14)),
          const SizedBox(height: 6),
          Text(email, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),

          const Spacer(),

          GestureDetector(
            onTap: () async {
              await AuthService().signOut();
              if (!Navigator.of(context).mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                CupertinoPageRoute(builder: (context) => const LoginScreen()),
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
                child: Text('Sign out', style: TextStyle(color: CupertinoColors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
