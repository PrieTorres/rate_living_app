import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'data/mock_seed.dart'; // 👈 importa o seed

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // roda o seed só em debug
  assert(() {
    seedMockAreasToFirestore();
    return true;
  }());

  runApp(const ProviderScope(child: RateLivingApp()));
}
