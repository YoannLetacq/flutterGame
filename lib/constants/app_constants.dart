/// Constantes d'application (chemins de DB, statuts, etc.)
class DBPaths {
  static const String games = 'games';
  static const String players = 'players';
}

class FirestoreCollections {
  static const String cards = 'cards';
}

class GameStatus {
  static const String waitingOpponent = 'waitingOpponent';
  static const String inGame = 'in game';
  static const String finished = 'finished';
  static const String abandon = 'abandon';
  static const String disconnected = 'disconnected';
}
