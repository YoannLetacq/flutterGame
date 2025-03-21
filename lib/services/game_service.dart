import 'package:untitled/repositories/game_repository_interface.dart';
import 'package:untitled/models/game_model.dart';

class GameService {
  final IGameRepository _gameRepository;

  GameService({required IGameRepository gameRepository})
      : _gameRepository = gameRepository;

  /// Crée une nouvelle partie à partir d'une instance de [GameModel].
  /// On suppose que l'ID est déjà présent dans le modèle.
  Future<void> createGame(GameModel game) async {
    final gameData = game.toJson();
    await _gameRepository.createGame(gameData);
  }

  /// Récupère une partie (sous forme de [GameModel]) à partir de son [gameId].
  Future<GameModel?> getGame(String gameId) async {
    final data = await _gameRepository.getGame(gameId);
    if (data != null) {
      return GameModel.fromJson(data);
    }
    return null;
  }

  /// Met à jour une partie avec les données fournies.
  Future<void> updateGame(String gameId, Map<String, dynamic> updates) async {
    await _gameRepository.updateGame(gameId, updates);
  }

  /// Supprime une partie à partir de son [gameId].
  Future<void> deleteGame(String gameId) async {
    await _gameRepository.deleteGame(gameId);
  }
}
