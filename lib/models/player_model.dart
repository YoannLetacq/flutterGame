class PlayerModel {
  final String id;
  final List<String> cardsOrder;
  final int currentCardIndex;
  final int score;
  final String status; // "waitingOpponent", "in game", "finished", "abandon", "disconnected"
  final String? winner; // Peut être null en cas d'égalité ou si la partie n'est pas terminée

  PlayerModel({
    required this.id,
    required this.cardsOrder,
    required this.currentCardIndex,
    required this.score,
    required this.status,
    this.winner,
  });

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] as String,
      cardsOrder: List<String>.from(json['cardsOrder'] ?? []),
      currentCardIndex: json['currentCardIndex'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      winner: json['winner'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardsOrder': cardsOrder,
      'currentCardIndex': currentCardIndex,
      'score': score,
      'status': status,
      'winner': winner,
    };
  }
}
