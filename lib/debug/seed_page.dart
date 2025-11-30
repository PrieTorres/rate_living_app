import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/mock_seed.dart';
import '../debug_firestore_ping.dart';

class SeedPage extends StatefulWidget {
  const SeedPage({super.key});

  @override
  State<SeedPage> createState() => _SeedPageState();
}

class _SeedPageState extends State<SeedPage> {
  String _log = '';

  void _append(String msg) {
    setState(() {
      _log += msg + '\n';
    });
    // também loga no console
    // ignore: avoid_print
    print(msg);
  }

  Future<void> _runPing() async {
    _append('🧪 Rodando ping Firestore...');
    try {
      final db = FirebaseFirestore.instance;
      await db.collection('debug').doc('ping').set({
        'ok': true,
        'time': FieldValue.serverTimestamp(),
      });
      _append('✅ Ping OK (escreveu /debug/ping)');
    } catch (e, st) {
      _append('❌ ERRO no ping: $e');
      _append('$st');
    }
  }

  Future<void> _runSeed() async {
    _append('🔥 Rodando seed...');
    await seedMockAreasToFirestore();
    _append('🎉 Seed terminado (veja console do Firebase).');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Firestore')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _runPing,
                  child: const Text('Ping Firestore'),
                ),
                ElevatedButton(
                  onPressed: _runSeed,
                  child: const Text('Rodar seed'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _log,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
