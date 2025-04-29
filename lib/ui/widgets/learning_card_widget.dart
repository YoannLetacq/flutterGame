import 'package:flutter/material.dart';
import 'package:untitled/models/card_model.dart';
import 'learning_view_mode.dart';

class LearningCard extends StatelessWidget {
  final CardModel card;
  final LearningViewMode viewMode;

  const LearningCard({super.key, required this.card, required this.viewMode});

  void _showExtended(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      title: Text(card.name),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (card.imageUrl.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Image.network(card.imageUrl, fit: BoxFit.cover),
              ),
            Text(card.explanation, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showExtended(context),
      child: Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: viewMode == LearningViewMode.list
              ? Text(card.name, style: Theme.of(context).textTheme.titleMedium)
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (card.imageUrl.isNotEmpty == true)
                Image.network(card.imageUrl, height: 80, fit: BoxFit.cover)
              else
                Text(
                  '${card.explanation.split(' ').take(10).join(' ')}…',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
