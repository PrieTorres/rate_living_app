import 'package:flutter/material.dart';
import 'features/map/map_page.dart';

class RateLivingApp extends StatelessWidget {
  const RateLivingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const MapPage(),
    );
  }
}
