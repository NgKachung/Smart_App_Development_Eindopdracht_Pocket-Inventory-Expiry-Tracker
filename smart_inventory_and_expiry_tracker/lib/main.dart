import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        scaffoldBackgroundColor: Color(0xFFF8FAF8),
      ),
      home: LoginScreen(),
    );
  }
}

//test om te kunnnen comitten zonder dat er iets veranderd in de code, zodat ik kan pushen naar github