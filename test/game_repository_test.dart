import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:untitled/repositories/game_repository_interface.dart';
import 'package:untitled/repositories/game_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late IGameRepository gameRepository;

  setUp(() {
    // Instanciation du Firestore simulé
    fakeFirestore = FakeFirebaseFirestore();
    // Injection de l'instance mockée dans le repository
    gameRepository = GameRepository(firestore: fakeFirestore);
  });

  group('GameRepository Tests', () {
    test('createGame', () async {
      const gameId = 'testGameId';
      final sampleGameData = {
        'id': gameId,
        'cards': ['card1', 'card2'],
        'mode': 'CLASSIQUE',
        'players': {}
      };

      await gameRepository.createGame(sampleGameData);

      // Vérifier que le document a été créé avec l'ID fourni.
      final docSnapshot = await fakeFirestore.collection('games').doc(gameId).get();
      expect(docSnapshot.exists, isTrue);
      final createdData = docSnapshot.data()!;
      expect(createdData['id'], equals(gameId));
      expect(createdData['cards'], equals(['card1', 'card2']));
      expect(createdData['mode'], equals('CLASSIQUE'));
      expect(createdData['players'], equals({}));
    });

    test('getGame', () async {
      final gameId = 'myGameId';
      await fakeFirestore.collection('games').doc(gameId).set({
        'id': gameId,
        'cards': ['cardA', 'cardB'],
        'mode': 'RAPIDE',
        'players': {}
      });

      final result = await gameRepository.getGame(gameId);
      expect(result, isNotNull);
      expect(result!['id'], equals(gameId));
      expect(result['cards'], equals(['cardA', 'cardB']));
      expect(result['mode'], equals('RAPIDE'));
    });

    test('updateGame', () async {
      final gameId = 'updateTest';
      await fakeFirestore.collection('games').doc(gameId).set({
        'id': gameId,
        'cards': ['card1'],
        'mode': 'CLASSIQUE',
        'players': {}
      });

      await gameRepository.updateGame(gameId, {
        'cards': ['card1', 'card2', 'card3']
      });

      final updatedSnapshot = await fakeFirestore.collection('games').doc(gameId).get();
      final updatedData = updatedSnapshot.data()!;
      expect(updatedData['cards'], equals(['card1', 'card2', 'card3']));
      expect(updatedData['mode'], equals('CLASSIQUE'));
    });

    test('deleteGame', () async {
      const gameId = 'deleteTest';
      await fakeFirestore.collection('games').doc(gameId).set({
        'id': gameId,
        'cards': ['cardX'],
        'mode': 'MODE_X',
        'players': {}
      });

      await gameRepository.deleteGame(gameId);

      final deletedSnapshot = await fakeFirestore.collection('games').doc(gameId).get();
      expect(deletedSnapshot.exists, isFalse, reason: 'Le document doit être supprimé.');
    });
  });
}
