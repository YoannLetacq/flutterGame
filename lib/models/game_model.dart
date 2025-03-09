import 'player_model.dart';

enum GameMode {
  CLASSIQUE,
  CLASSEE,
}

class GameModel {
  final String id;
  final List<String> cards;
  final GameMode mode;
  final Map<String, PlayerModel> players;

  GameModel({
    required this.id,
    required this.cards,
    required this.mode,
    required this.players,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'] as String,
      cards: List<String>.from(json['cards'] ?? []),
      mode: (json['mode'] as String).toUpperCase() == "CLASSEE" ? GameMode.CLASSEE : GameMode.CLASSIQUE,
      players: (json['players'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, PlayerModel.fromJson(value)),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cards': cards,
      'mode': mode == GameMode.CLASSEE ? "CLASSEE" : "CLASSIQUE",
      'players': players.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}
