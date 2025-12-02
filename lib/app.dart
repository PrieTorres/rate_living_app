import 'package:flutter/material.dart';

import 'features/auth/auth_gate.dart';
import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/map/map_page.dart';

class RateLivingApp extends StatelessWidget {
  const RateLivingApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFE46B3F);
    const bgLight = Color(0xFFF8F6F6);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: bgLight,
        fontFamily: 'Work Sans', // se quiser registrar depois no pubspec
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,

      // Roteamento
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/map': (context) => const MapPage(),
      },
    );
  }
}
