import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:untitled/models/game_model.dart';
import 'package:untitled/repositories/game_repository.dart';
import 'package:untitled/services/game_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late GameService gameService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    final gameRepository = GameRepository(firestore: fakeFirestore);
    gameService = GameService(gameRepository: gameRepository);
  });

  group('GameService Tests', () {
    test('createGame and getGame', () async {
      // Créer un GameModel de test
      final game = GameModel(
        id: 'game1',
        cards: ['card1', 'card2'],
        mode: GameMode.CLASSIQUE,
        players: {},
      );

      // Créer la partie via le service
      await gameService.createGame(game);

      // Récupérer la partie et vérifier les données
      final retrievedGame = await gameService.getGame('game1');
      expect(retrievedGame, isNotNull);
      expect(retrievedGame!.id, equals('game1'));
      expect(retrievedGame.cards, equals(['card1', 'card2']));
    });

    test('updateGame', () async {
      // Préparation : insérer une partie initiale
      final game = GameModel(
        id: 'game2',
        cards: ['card1'],
        mode: GameMode.CLASSIQUE,
        players: {},
      );
      await gameService.createGame(game);

      // Mettre à jour la partie
      final updates = {'cards': ['card1', 'card2', 'card3']};
      await gameService.updateGame('game2', updates);

      // Vérifier la mise à jour
      final updatedGame = await gameService.getGame('game2');
      expect(updatedGame, isNotNull);
      expect(updatedGame!.cards, equals(['card1', 'card2', 'card3']));
    });

    test('deleteGame', () async {
      // Préparation : insérer une partie
      final game = GameModel(
        id: 'game3',
        cards: ['cardX'],
        mode: GameMode.CLASSIQUE,
        players: {},
      );
      await gameService.createGame(game);

      // Supprimer la partie
      await gameService.deleteGame('game3');

      // Vérifier la suppression
      final deletedGame = await gameService.getGame('game3');
      expect(deletedGame, isNull);
    });
  });
}
