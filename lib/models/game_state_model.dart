class GameStateModel {
  final String state; // "in game", "waitingOpponent", "finished", "abandon", "disconnected"
  final DateTime startTime;
  final DateTime? finishTime;

  GameStateModel({
    required this.state,
    required this.startTime,
    this.finishTime,
  });

  factory GameStateModel.fromJson(Map<String, dynamic> json) {
    return GameStateModel(
      state: json['state'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      finishTime: json['finishTime'] != null ? DateTime.parse(json['finishTime'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'startTime': startTime.toIso8601String(),
      'finishTime': finishTime?.toIso8601String(),
    };
  }
}
