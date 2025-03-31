import 'package:flutter/material.dart';

/// Widget de barre de progression pour l'adversaire.
/// - Rôle : indiquer l'avancement de l'adversaire dans ses cartes.
/// - Dépendances : aucune (prend les valeurs en entrée).
/// - Affiche une barre de progression représentant le pourcentage de cartes terminées par l'adversaire.
class OpponentProgressBarWidget extends StatelessWidget {
  final int currentIndex;
  final int totalCards;

  const OpponentProgressBarWidget({
    super.key,
    required this.currentIndex,
    required this.totalCards,
  });

  @override
  Widget build(BuildContext context) {
    double progress = totalCards > 0 ? currentIndex / totalCards : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('Adversaire', style: TextStyle(fontWeight: FontWeight.bold)),
        LinearProgressIndicator(value: progress, minHeight: 8),
        const SizedBox(height: 4),
        Text('${(progress * 100).toStringAsFixed(0)}%'),
      ],
    );
  }
}
