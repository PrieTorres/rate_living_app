import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';
import '../map/map_page.dart';
import 'welcome_page.dart';

/// Widget que observa o estado de auth:
/// - user == null  → mostra WelcomePage
/// - user != null  → mostra MapPage
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateChangesProvider);

    return authAsync.when(
      data: (user) {
        if (user == null) {
          return const WelcomePage();
        }
        return const MapPage();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erro de autenticação: $e')),
      ),
    );
  }
}
