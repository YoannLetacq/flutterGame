import 'package:untitled/models/card_model.dart';

import 'player_model.dart';

/// Enumération des modes de jeu disponibles.
enum GameMode {
  CLASSIQUE,
  CLASSEE,
}

/// Modèle de données représentant une partie de jeu.
///
/// - [id] : identifiant unique de la partie.
/// - [cards] : liste d'identifiants de cartes utilisées dans la partie.
/// - [mode] : mode de jeu (CLASSIQUE ou CLASSEE).
/// - [players] : map des joueurs participant à la partie, indexée par leur UID.
class GameModel {
  final String id;
  final List<CardModel> cards;
  final GameMode mode;
  final Map<String, PlayerModel> players;

  GameModel({
    required this.id,
    required this.cards,
    required this.mode,
    required this.players,
  });

  /// Crée une instance de [GameModel] à partir d'une Map.
  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'] as String,
      cards: (json['cards'] as List<dynamic>).map((e) => CardModel.fromJson(e)).toList(),
      mode: (json['mode'] as String).toUpperCase() == "CLASSEE" ? GameMode.CLASSEE : GameMode.CLASSIQUE,
      players: (json['players'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, PlayerModel.fromJson(value)),
      ),
    );
  }

  /// Convertit l'instance en Map pour stockage dans Firebase.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cards': cards.map((card) => card.toJson()).toList(),
      'mode': mode == GameMode.CLASSEE ? "CLASSEE" : "CLASSIQUE",
      'players': players.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}
