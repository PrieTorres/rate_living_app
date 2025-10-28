import 'package:flutter/material.dart';

class AddRatingResult {
  final int score;
  final String? comment;
  const AddRatingResult({required this.score, this.comment});
}

class AddRatingSheet extends StatefulWidget {
  final String areaName;
  const AddRatingSheet({super.key, required this.areaName});

  @override
  State<AddRatingSheet> createState() => _AddRatingSheetState();
}

class _AddRatingSheetState extends State<AddRatingSheet> {
  int _score = 5;
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8 + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nova avaliação em ${widget.areaName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          const Text('Nota'),
          Row(
            children: List.generate(5, (i) {
              final filled = i < _score;
              return IconButton(
                onPressed: () => setState(() => _score = i + 1),
                icon: Icon(filled ? Icons.star : Icons.star_border),
                color: filled ? Colors.amber[700] : Colors.grey[600],
              );
            }),
          ),
          const SizedBox(height: 8),

          const Text('Comentário (opcional)'),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Escreva um comentário curto...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop(AddRatingResult(
                  score: _score,
                  comment: _controller.text.isEmpty ? null : _controller.text.trim(),
                ));
              },
              child: const Text('Salvar avaliação'),
            ),
          ),
        ],
      ),
    );
  }
}
