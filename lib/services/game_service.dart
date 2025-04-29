import '../repositories/game_repository.dart';
import '../repositories/game_repository_interface.dart';

/// Service de gestion des parties.
/// - Rôle : orchestrer la création, la récupération et la suppression des parties en s'appuyant sur le dépôt de données.
/// - Dépendances : [IGameRepository] pour effectuer les opérations sur la base de données (Firestore).
/// - Retourne des objets [GameModel] ou void selon l'opération effectuée.
class GameService {
  final IGameRepository _gameRepository = GameRepository();

  /// Crée une nouvelle partie persistante (sauvegardée en Firestore).
  /// [gameData] est une map représentant le GameModel à stocker (par ex: issue de game.toJson()).
  Future<void> createGame(Map<String, dynamic> gameData) async {
    await _gameRepository.createGame(gameData);
  }

  /// Récupère les données d'une partie à partir de son [gameId].
  /// Retourne les données sous forme de Map (contenant par exemple les players, scores, etc.), ou null si non trouvé.
  Future<Map<String, dynamic>?> getGame(String gameId) async {
    return await _gameRepository.getGame(gameId);
  }

  /// Met à jour les données de la partie [gameId] avec les nouvelles valeurs [gameData].
  Future<void> updateGame(String gameId, Map<String, dynamic> gameData) async {
    await _gameRepository.updateGame(gameId, gameData);
  }

  /// Supprime la partie identifiée par [gameId].
  Future<void> deleteGame(String gameId) async {
    await _gameRepository.deleteGame(gameId);
  }
}
