abstract class IGameRepository {
  /// Crée une nouvelle partie dans la base de données.
  Future<void> createGame(Map<String, dynamic> gameData);

  /// Récupère les données d'une partie en fonction de son identifiant.
  Future<Map<String, dynamic>?> getGame(String gameId);

  /// Met à jour les données d'une partie.
  Future<void> updateGame(String gameId, Map<String, dynamic> gameData);

  /// Supprime une partie à partir de son identifiant.
  Future<void> deleteGame(String gameId);
}
