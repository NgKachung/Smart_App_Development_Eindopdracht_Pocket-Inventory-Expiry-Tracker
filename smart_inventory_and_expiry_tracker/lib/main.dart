import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';
 
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // We initialiseren Firebase eerst, maar vangen eventuele fouten op
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  
  // Start de app DIRECT
  runApp(ProviderScope(child: const MainApp()));
  
  // Voer de rest van de initialisatie uit NADAT de app is gestart
  _initializeBackgroundServices();
}

Future<void> _initializeBackgroundServices() async {
  try {
    // Initialize notifications
    final notificationService = NotificationService();
    await notificationService.init();
    // Vraag permissies pas later aan, niet tijdens het opstarten
    await notificationService.requestPermissions();
  } catch (e) {
    debugPrint("Background services error: $e");
  }
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeProvider);

    // Determine brightness based on theme mode
    Brightness? brightness;
    if (themeMode == AppThemeMode.system) {
      // Follow system theme
      brightness = MediaQuery.platformBrightnessOf(context);
    } else {
      brightness = themeMode == AppThemeMode.dark ? Brightness.dark : Brightness.light;
    }

    final primaryColor = brightness == Brightness.dark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final scaffoldBackgroundColor = brightness == Brightness.dark 
        ? AppColors.darkScaffoldBackground 
        : AppColors.lightScaffoldBackground;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorSchemeSeed: primaryColor,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      builder: (context, child) {
        return CupertinoTheme(
          data: CupertinoThemeData(
            brightness: brightness,
            primaryColor: primaryColor,
            scaffoldBackgroundColor: scaffoldBackgroundColor,
          ),
          child: Material(
            child: child!,
          ),
        );
      },
      home: authState.when(
        loading: () => const CupertinoPageScaffold(
          child: Center(child: CupertinoActivityIndicator()),
        ),
        error: (error, stackTrace) => CupertinoPageScaffold(
          child: Center(
            child: Text('Auth error: $error'),
          ),
        ),
        data: (user) {
          return user == null ? const LoginScreen() : const DashboardScreen();
        },
      ),
    );
  }
}
