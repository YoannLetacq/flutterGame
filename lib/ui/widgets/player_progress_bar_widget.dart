import 'package:flutter/material.dart';

/// Widget de barre de progression pour le joueur local.
/// - Rôle : indiquer la progression du joueur à travers ses cartes.
/// - Dépendances : aucune (fonctionne sur les valeurs passées en paramètre).
/// - Affiche une barre de progression avec le pourcentage de cartes complétées.
class PlayerProgressBarWidget extends StatelessWidget {
  final int currentIndex;
  final int totalCards;

  const PlayerProgressBarWidget({
    super.key,
    required this.currentIndex,
    required this.totalCards,
  });

  @override
  Widget build(BuildContext context) {
    double progress = totalCards > 0 ? currentIndex / totalCards : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vous', style: TextStyle(fontWeight: FontWeight.bold)),
        LinearProgressIndicator(value: progress, minHeight: 8),
        const SizedBox(height: 4),
        Text('${(progress * 100).toStringAsFixed(0)}%'),
      ],
    );
  }
}
