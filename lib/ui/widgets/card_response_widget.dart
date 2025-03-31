import 'package:flutter/material.dart';
import 'package:untitled/models/card_model.dart';
import '../../services/security_service.dart';

/// Widget de réponse pour une carte de type [CardModel].
/// On affiche les options sous forme de RadioListTile.
/// Lorsque l'utilisateur clique sur "Valider", on appelle [onAnswer] avec l'index sélectionné.
class CardResponseWidget extends StatefulWidget {
  final CardModel? card;
  final ValueChanged<int> onAnswer;

  const CardResponseWidget({
    super.key,
    required this.card,
    required this.onAnswer,
  });

  @override
  State<CardResponseWidget> createState() => _CardResponseWidgetState();
}

class _CardResponseWidgetState extends State<CardResponseWidget> {
  final _security = SecurityService();
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    // Si pas de carte, on n'affiche rien
    if (widget.card == null) {
      return const SizedBox.shrink();
    }

    final cardModel = widget.card!;
    final options = cardModel.options;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Liste de RadioListTile pour chaque option
          for (int i = 0; i < options.length; i++)
            RadioListTile<int>(
              title: Text(options[i]),
              value: i,
              groupValue: _selectedIndex,
              onChanged: (val) {
                setState(() {
                  _selectedIndex = val;
                });
              },
            ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              // Vérification via SecurityService si tu le souhaites
              if (_selectedIndex != null &&
                  _security.validatePlayerResponse(options[_selectedIndex!])) {
                widget.onAnswer(_selectedIndex!);
                setState(() {
                  _selectedIndex = null; // réinitialise la sélection
                });
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}
