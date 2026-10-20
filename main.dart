import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'onboarding_screen.dart';
import 'dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY'] ?? '',
        authDomain: "zennie-app.firebaseapp.com",
        projectId: "zennie-app",
        storageBucket: "zennie-app.firebasestorage.app",
        messagingSenderId: "546448751194",
        appId: "1:546448751194:web:9f76c0e9cc34b8b7683663",
        measurementId: "G-ZN623HKCZM",
      ),
    );
    print("✅ Firebase initialized successfully!");
  } catch (e) {
    print("❌ CRITICAL INITIALIZATION ERROR: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  final showHome = prefs.getBool('showHome') ?? false;

  runApp(ZennieApp(showHome: showHome));
}

class ZennieApp extends StatelessWidget {
  final bool showHome;
  const ZennieApp({super.key, required this.showHome});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZENnie',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF009688)),
        scaffoldBackgroundColor: const Color(
          0xFFF8FFFE,
        ), // CHANGED: Added global background color
        useMaterial3: true,
      ),
      // We use a custom function to decide which screen to show
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    // 1. If they haven't seen onboarding, send them there first!
    if (!showHome) {
      return const OnboardingScreen();
    }

    // 2. If onboarding is done, listen to Firebase to see if they are logged in!
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While Firebase is checking, show a quick loading spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4FBF9),
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }

        // If Firebase says they are logged in, go straight to the Dashboard!
        if (snapshot.hasData) {
          return const HomeTab();
        }

        // Otherwise, ask them to log in.
        return const LoginPage();
      },
    );
  }
}
