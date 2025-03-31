import 'package:flutter/material.dart';
import 'package:untitled/models/card_model.dart';

/// Affiche la carte courante avec animation en slide.
/// On affiche soit le champ "name" (si type = definition),
/// soit le champ "definition" (si type = complement).
class AnimatedCardDisplay extends StatelessWidget {
  final CardModel? cardModel; // null => en attente

  const AnimatedCardDisplay({super.key, required this.cardModel});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(animation);
        return ClipRect(
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      child: cardModel == null
          ? Container(
        key: const ValueKey('empty'),
        alignment: Alignment.center,
        child: const Text(
          'En attente de la carte...',
          style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
        ),
      )
          : _buildCardWidget(cardModel!, key: ValueKey(cardModel!.id)),
    );
  }

  Widget _buildCardWidget(CardModel card, {Key? key}) {
    // Selon le type
    final displayText = (card.type == 'definition')
        ? card.name
        : card.definition.isNotEmpty
        ? card.definition
        : card.name; // fallback

    return Container(
      key: key,
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        displayText,
        style: const TextStyle(fontSize: 22),
      ),
    );
  }
}
