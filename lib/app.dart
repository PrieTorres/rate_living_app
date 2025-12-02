import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_gate.dart';
import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/map/map_page.dart';
import 'features/ranking/ranking_page.dart';
import 'features/property/property_detail_page.dart';
import 'features/user/user_profile_page.dart';
import 'models/rating.dart';

class RateLivingApp extends StatelessWidget {
  const RateLivingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rate Living',
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/map': (context) => const MapPage(),
        '/ranking': (context) => const RankingPage(),
        '/property': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Rating) {
            return PropertyDetailPage(rating: args);
          }
          if (args is Map && args['rating'] is Rating) {
            final r = args['rating'] as Rating;
            final reviews = args['reviews'] as List<Rating>?;
            return PropertyDetailPage(rating: r, reviews: reviews);
          }
          return const Scaffold(
            body: Center(child: Text('Imóvel não fornecido.')),
          );
        },
        '/profile': (context) => const UserProfilePage(),
      },
    );
  }
}
