class PlayerModel {
  final String id;
  final List<String> cardsOrder;
  final int currentCardIndex;
  final int score;
  final String status;
  final String? winner;

  PlayerModel({
    required this.id,
    required this.cardsOrder,
    required this.currentCardIndex,
    required this.score,
    required this.status,
    this.winner,
  });

  /// Permet de créer une copie de l'instance en modifiant certains champs.
  PlayerModel copyWith({
    String? id,
    List<String>? cardsOrder,
    int? currentCardIndex,
    int? score,
    String? status,
    String? winner,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      cardsOrder: cardsOrder ?? this.cardsOrder,
      currentCardIndex: currentCardIndex ?? this.currentCardIndex,
      score: score ?? this.score,
      status: status ?? this.status,
      winner: winner ?? this.winner,
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
}
