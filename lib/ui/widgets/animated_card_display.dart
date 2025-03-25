import 'package:flutter/material.dart';

/// Widget d'affichage animé de la carte de jeu courante.
/// - Rôle : afficher la carte actuelle avec une transition en slide à chaque changement de carte.
/// - Dépendances : aucune (affichage pur, la nouvelle carte est fournie via [cardId] qui déclenche le changement).
/// - Retourne l'affichage de la carte (placeholder si [cardId] est null).
class AnimatedCardDisplay extends StatelessWidget {
  final String? cardId;
  const AnimatedCardDisplay({super.key, required this.cardId});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        // Transition en slide horizontale
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0), // slide in from right
          end: Offset.zero,
        ).animate(animation);
        return ClipRect(
          child: SlideTransition(position: offsetAnimation, child: child),
        );
      },
      child: cardId == null
          ? Container(
        key: const ValueKey('empty'),
        alignment: Alignment.center,
        child: const Text(
          'En attente de la carte...',
          style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
        ),
      )
          : _buildCardWidget(cardId!, key: ValueKey(cardId)),
    );
  }

  Widget _buildCardWidget(String cardId, {Key? key}) {
    // Pour simplifier, on affiche juste l'ID de la carte.
    // Dans une vraie application, on afficherait question, image, etc. en fonction de cardId.
    return Container(
      key: key,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8.0)),
      child: Text(
        'Carte: $cardId',
        style: const TextStyle(fontSize: 22),
      ),
    );
  }
}
