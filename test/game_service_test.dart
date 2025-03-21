import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/models/game_model.dart';
import 'package:untitled/models/player_model.dart';
import 'package:untitled/repositories/game_repository_interface.dart';
import 'package:untitled/services/game_service.dart';

// Fake repository stockant les jeux en mémoire.
class FakeGameRepository implements IGameRepository {
  final Map<String, Map<String, dynamic>> storage = {};

  @override
  Future<void> createGame(Map<String, dynamic> gameData) async {
    String gameId = gameData['id'] as String;
    storage[gameId] = Map<String, dynamic>.from(gameData);
  }

  @override
  Future<Map<String, dynamic>?> getGame(String gameId) async {
    if (storage.containsKey(gameId)) {
      // Cloner la map pour éviter les modifications externes.
      return Map<String, dynamic>.from(storage[gameId]!);
    }
    return null;
  }

  @override
  Future<void> updateGame(String gameId, Map<String, dynamic> updates) async {
    if (storage.containsKey(gameId)) {
      storage[gameId]!.addAll(updates);
    }
  }

  @override
  Future<void> deleteGame(String gameId) async {
    storage.remove(gameId);
  }
}

void main() {
  group('GameService', () {
    late FakeGameRepository fakeRepo;
    late GameService gameService;
    late GameModel sampleGame;

    setUp(() {
      fakeRepo = FakeGameRepository();
      gameService = GameService(gameRepository: fakeRepo);
      // Préparer un GameModel d'exemple.
      sampleGame = GameModel(
        id: 'game_test',
        cards: ['card1', 'card2'],
        mode: GameMode.CLASSIQUE,
        players: {
          'player1': PlayerModel(
            id: 'player1',
            cardsOrder: ['card1', 'card2'],
            currentCardIndex: 0,
            score: 0,
            status: 'in game',
            winner: null,
          ),
        },
      );
    });

    test('createGame stocke les données du jeu dans le repository', () async {
      await gameService.createGame(sampleGame);
      expect(fakeRepo.storage.containsKey('game_test'), isTrue);
      // Vérifier que l'entrée stockée correspond aux données du GameModel.
      final storedData = fakeRepo.storage['game_test']!;
      expect(storedData['id'], sampleGame.id);
      expect(storedData['cards'], sampleGame.cards);
      expect(storedData['mode'], 'CLASSIQUE'); // Le GameModel.toJson convertit l'enum en string.
      expect((storedData['players'] as Map)['player1'], isNotNull);
    });

    test('getGame retourne un GameModel valide si le jeu existe', () async {
      // Insérer d'abord le jeu via le fakeRepo.
      fakeRepo.storage['game_test'] = sampleGame.toJson();
      GameModel? fetchedGame = await gameService.getGame('game_test');
      expect(fetchedGame, isNotNull);
      expect(fetchedGame!.id, sampleGame.id);
      expect(fetchedGame.mode, sampleGame.mode);
      expect(fetchedGame.players.keys, contains('player1'));
    });

    test('getGame retourne null si le jeu n\'existe pas', () async {
      GameModel? fetchedGame = await gameService.getGame('inexistant');
      expect(fetchedGame, isNull);
    });

    test('updateGame modifie les données de la partie existante', () async {
      // Insérer le jeu initial.
      fakeRepo.storage['game_test'] = sampleGame.toJson();
      // Mettre à jour le mode de jeu et ajouter une carte.
      await gameService.updateGame('game_test', {
        'mode': 'CLASSEE',
        'cards': ['card1', 'card2', 'card3']
      });
      final updatedData = fakeRepo.storage['game_test']!;
      expect(updatedData['mode'], 'CLASSEE');
      expect(updatedData['cards'], ['card1', 'card2', 'card3']);
    });

    test('deleteGame supprime la partie du repository', () async {
      fakeRepo.storage['game_test'] = sampleGame.toJson();
      await gameService.deleteGame('game_test');
      expect(fakeRepo.storage.containsKey('game_test'), isFalse);
    });
  });
}
