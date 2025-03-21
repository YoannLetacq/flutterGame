import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/services/game_progress_service.dart';

void main() {
  group('GameProgressService', () {
    final progressService = GameProgressService();

    test('incrémente l\'index si ce n\'est pas la dernière carte', () {
      int currentIndex = 0;
      int totalCards = 5;
      int newIndex = progressService.incrementCardIndex(currentIndex, totalCards);
      expect(newIndex, currentIndex + 1);
    });

    test('ne change pas l\'index si la carte courante est la dernière', () {
      int currentIndex = 4;
      int totalCards = 5;
      int newIndex = progressService.incrementCardIndex(currentIndex, totalCards);
      expect(newIndex, currentIndex); // reste 4
    });

    test('gère le cas d\'un index initial à 0 correctement', () {
      int currentIndex = 0;
      int totalCards = 1;
      int newIndex = progressService.incrementCardIndex(currentIndex, totalCards);
      // Avec une seule carte, on reste sur l'index 0.
      expect(newIndex, 0);
    });
  });
}
