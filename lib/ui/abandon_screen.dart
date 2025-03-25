import 'package:flutter/material.dart';

/// Écran de confirmation d'abandon de partie.
/// - Affiche un message de confirmation et deux boutons (Confirmer ou Annuler).
/// - Si confirmé, notifie la logique de jeu que le joueur souhaite abandonner.
class AbandonScreen extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const AbandonScreen({super.key, required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Abandonner la partie'),
      content: const Text('Êtes-vous sûr de vouloir abandonner ?'),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Continuer la partie'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('Abandonner'),
        ),
      ],
    );
  }
}
