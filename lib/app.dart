import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_gate.dart';
import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/map/map_page.dart';
import 'features/ranking/ranking_page.dart';

class RateLivingApp extends StatelessWidget {
  const RateLivingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rate Living',
      debugShowCheckedModeBanner: false,

      // Tela inicial (sem usar rota nomeada, é a "home")
      home: const AuthGate(),

      // AQUI ficam as rotas nomeadas que você usa com pushNamed
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/map': (context) => const MapPage(),
        '/ranking': (context) => const RankingPage(),
        // futuramente: '/user': (context) => const UserPage(),
      },
    );
  }
}
