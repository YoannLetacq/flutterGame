abstract class IGameRepository {
  /// Crée une nouvelle partie avec les données fournies.
  Future<void> createGame(Map<String, dynamic> gameData);

  /// Récupère les données d'une partie par son [gameId].
  /// Retourne un Map des données de la partie ou `null` si non trouvée.
  Future<Map<String, dynamic>?> getGame(String gameId);

  /// Met à jour les données partielles de la partie [gameId] avec [updates].
  Future<void> updateGame(String gameId, Map<String, dynamic> updates);

  /// Supprime la partie identifiée par [gameId].
  Future<void> deleteGame(String gameId);
}
