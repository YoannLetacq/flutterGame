import 'package:flutter/material.dart';

/// Service pour gérer la barre de recherche dans l'écran d'apprentissage.
/// Il contient un [TextEditingController] pour gérer le texte de la barre de recherche
/// Micro service pour gérer la propagation des modifications de texte
class LearningSearchBarService {
  final TextEditingController controller = TextEditingController();

  void onChanged(String value, void Function(String) onSearch) {
    onSearch(value);
  }

  void dispose() => controller.dispose();
}