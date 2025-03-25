import 'package:flutter/material.dart';
import '../../services/security_service.dart';

/// Widget de réponse à une carte.
/// - Rôle : offrir une interface (champ texte, bouton) pour la réponse du joueur à la carte courante.
/// - Dépendances : [SecurityService] pour valider la réponse.
/// - Retourne l'entrée de l'utilisateur via le callback [onAnswer] une fois validée.
class CardResponseWidget extends StatefulWidget {
  final String? cardId;
  final ValueChanged<String> onAnswer;

  const CardResponseWidget({super.key, required this.cardId, required this.onAnswer});

  @override
  _CardResponseWidgetState createState() => _CardResponseWidgetState();
}

class _CardResponseWidgetState extends State<CardResponseWidget> {
  final _controller = TextEditingController();
  final _security = SecurityService();

  @override
  Widget build(BuildContext context) {
    if (widget.cardId == null) {
      // Pas de carte actuelle, on désactive le champ de réponse.
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Votre réponse'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              final response = _controller.text;
              if (_security.validatePlayerResponse(response)) {
                widget.onAnswer(response);
                _controller.clear();
              }
            },
            child: const Text('Valider'),
          )
        ],
      ),
    );
  }
}
