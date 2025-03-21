import 'package:flutter/material.dart';
import 'package:untitled/models/card_model.dart';

class CardWidget extends StatelessWidget {
  final CardModel card;
  final ValueChanged<String> onAnswerSelected;

  const CardWidget({super.key, required this.card, required this.onAnswerSelected});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre ou nom de la carte (éventuellement pas utilisé comme question directement).
            if (card.name.isNotEmpty)
              Text(card.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Texte de la question/definition.
            Text(card.definition, style: const TextStyle(fontSize: 18)),
            if (card.imageUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: Image.network(card.imageUrl, height: 150),
              ),
            ],
            const SizedBox(height: 16),
            // Liste des options de réponse.
            ...card.options.map((option) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ElevatedButton(
                  onPressed: () => onAnswerSelected(option),
                  child: Text(option),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
