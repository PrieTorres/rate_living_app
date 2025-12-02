import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/rating.dart';
import '../map/map_controller.dart';
import '../auth/auth_providers.dart';
import '../../data/firestore_api.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(firebaseAuthProvider);
    final user = auth.currentUser;
    final areasAsync = ref.watch(areasProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Sair', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
      body: areasAsync.when(
        data: (areas) {
          final List<_UserRating> userRatings = [];
          for (final area in areas) {
            for (final rating in area.ratings) {
              if (rating.userId != null && user != null && rating.userId == user.uid) {
                userRatings.add(_UserRating(areaId: area.id, areaName: area.name, rating: rating));
              }
            }
          }
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user != null)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.orange.withOpacity(0.3),
                          child: Text(
                            (user.displayName?.isNotEmpty ?? false)
                                ? user.displayName!.substring(0, 1).toUpperCase()
                                : (user.email?.isNotEmpty ?? false)
                                    ? user.email!.substring(0, 1).toUpperCase()
                                    : 'U',
                            style: const TextStyle(color: Colors.orange, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName ?? user.email ?? 'Usuário',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              if (user.email != null)
                                Text(user.email!, style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  const Text('Minhas Avaliações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (userRatings.isEmpty)
                    const Text('Você ainda não avaliou nenhum local.', style: TextStyle(color: Colors.black54))
                  else
                    Column(
                      children: userRatings.map((item) {
                        final rating = item.rating;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withOpacity(0.1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.areaName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: List.generate(5, (i) {
                                            final filled = i < rating.score;
                                            return Icon(filled ? Icons.star : Icons.star_border, color: Colors.orange, size: 20);
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) {
                                          return AlertDialog(
                                            title: const Text('Excluir avaliação'),
                                            content: const Text('Tem certeza que deseja excluir esta avaliação?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                                              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir')),
                                            ],
                                          );
                                        },
                                      );
                                      if (confirm == true) {
                                        await FirebaseFirestore.instance.collection('areas').doc(item.areaId).collection('ratings').doc(rating.id).delete();
                                        ref.invalidate(areasProvider);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avaliação excluída.')));
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      final result = await showDialog<_EditRatingResult?>(
                                        context: context,
                                        builder: (ctx) {
                                          int newScore = rating.score;
                                          final commentController = TextEditingController(text: rating.comment ?? '');
                                          return AlertDialog(
                                            title: const Text('Editar avaliação'),
                                            content: StatefulBuilder(
                                              builder: (ctx2, setState2) {
                                                return Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: List.generate(5, (i) {
                                                        final filled = i < newScore;
                                                        return IconButton(
                                                          padding: EdgeInsets.zero,
                                                          visualDensity: VisualDensity.compact,
                                                          onPressed: () {
                                                            setState2(() => newScore = i + 1);
                                                          },
                                                          icon: Icon(filled ? Icons.star : Icons.star_border),
                                                          color: filled ? Colors.orange : Colors.grey,
                                                        );
                                                      }),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    TextField(
                                                      controller: commentController,
                                                      decoration: const InputDecoration(labelText: 'Comentário', border: OutlineInputBorder()),
                                                      maxLines: 3,
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(ctx).pop(_EditRatingResult(score: newScore, comment: commentController.text.trim()));
                                                },
                                                child: const Text('Salvar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (result != null) {
                                        final api = ref.read(firestoreApiProvider);
                                        await api.updateRating(
                                          areaId: item.areaId,
                                          ratingId: rating.id,
                                          score: result.score,
                                          comment: result.comment.isEmpty ? null : result.comment,
                                        );
                                        ref.invalidate(areasProvider);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avaliação atualizada.')));
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                  ),
                                ],
                              ),
                              if (rating.comment != null && rating.comment!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(rating.comment!, style: const TextStyle(color: Colors.black87)),
                              ],
                              const SizedBox(height: 4),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Erro ao carregar avaliações: $e')),
      ),
    );
  }
}

class _EditRatingResult {
  final int score;
  final String comment;
  _EditRatingResult({required this.score, required this.comment});
}

class _UserRating {
  final String areaId;
  final String areaName;
  final Rating rating;
  _UserRating({required this.areaId, required this.areaName, required this.rating});
}
