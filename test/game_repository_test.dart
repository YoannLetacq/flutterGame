import 'package:flutter_test/flutter_test.dart';
// On importe le paquet "fake_cloud_firestore"
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:untitled/repositories/game_repository_interface.dart';
import 'package:untitled/repositories/game_repository.dart';

void main() {
  late IGameRepository gameRepository;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    // On instancie un Firestore simulé (fake) avant chaque test.
    fakeFirestore = FakeFirebaseFirestore();

    // On injecte l'instance mockée dans GameRepository
    gameRepository = GameRepository(firestore: fakeFirestore);
  });

  group('GameRepository Tests', () {
    test('createGame', () async {
      final sampleGameData = {
        'cards': ['card1', 'card2'],
        'mode': 'CLASSIQUE',
        'players': {}
      };

      // On appelle la méthode createGame
      await gameRepository.createGame(sampleGameData);

      // Vérifions que le document a bien été créé dans la collection 'games'
      final gamesCollection = fakeFirestore.collection('games');
      final querySnapshot = await gamesCollection.get();
      final docs = querySnapshot.docs;
      expect(docs.length, 1, reason: 'Un seul document doit être créé.');

      final createdData = docs.first.data();
      expect(createdData['cards'], equals(['card1', 'card2']));
      expect(createdData['mode'], equals('CLASSIQUE'));
      expect(createdData['players'], equals({}));
    });

    test('getGame', () async {
      // Créons d'abord un document Firestore dans le fake
      final docRef = fakeFirestore.collection('games').doc('myGameId');
      await docRef.set({
        'cards': ['cardA', 'cardB'],
        'mode': 'RAPIDE',
        'players': {}
      });

      // On appelle la méthode getGame du repository
      final result = await gameRepository.getGame('myGameId');
      expect(result, isNotNull);
      expect(result!['cards'], equals(['cardA', 'cardB']));
      expect(result['mode'], equals('RAPIDE'));
    });

    test('updateGame', () async {
      final docRef = fakeFirestore.collection('games').doc('updateTest');
      await docRef.set({
        'cards': ['card1'],
        'mode': 'CLASSIQUE',
        'players': {}
      });

      await gameRepository.updateGame('updateTest', {
        'cards': ['card1', 'card2', 'card3']
      });

      final updatedSnapshot = await docRef.get();
      final updatedData = updatedSnapshot.data()!;
      expect(updatedData['cards'], equals(['card1', 'card2', 'card3']));
      expect(updatedData['mode'], equals('CLASSIQUE'));
    });

    test('deleteGame', () async {
      final docRef = fakeFirestore.collection('games').doc('deleteTest');
      await docRef.set({
        'cards': ['cardX'],
        'mode': 'MODE_X',
        'players': {}
      });

      await gameRepository.deleteGame('deleteTest');

      final deletedSnapshot = await docRef.get();
      expect(deletedSnapshot.exists, isFalse,
          reason: 'Le document doit être supprimé.');
    });
  });
}
