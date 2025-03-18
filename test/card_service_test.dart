import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/services/card_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:untitled/models/card_model.dart';

void main() {
  group('CardService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late CardService cardService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      cardService = CardService(firestore: fakeFirestore);
    });

    test('fetchCards returns list of cards', () async {
      // Créer un document de test dans la collection "cards"
      await fakeFirestore.collection('cards').add({
        'id': 'card1',
        'name': 'Test Card',
        'definition': 'Test Definition',
        'type': 'definition',
        'options': ['Option 1', 'Option 2'],
        'hints': ['Hint 1', 'Hint 2'],
        'answer': 'Answer',
        'imageUrl': 'https://example.com/image.jpg',
        'explanation': 'Explanation',
      });

      final fetchedCards = await cardService.fetchCards();
      expect(fetchedCards, isNotEmpty);
      expect(fetchedCards.first, isA<CardModel>());
      expect(fetchedCards.first.name, equals('Test Card'));
    });
  });
}
