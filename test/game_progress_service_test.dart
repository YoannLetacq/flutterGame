import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/services/game_progress_service.dart';

void main() {
  group('GameProgressService Tests', () {
    final progressService = GameProgressService();

    test('Increment index when not at the end', () {
      // Cas : currentIndex inférieur à totalCards - 1
      int currentIndex = 2;
      int totalCards = 5;
      int newIndex = progressService.incrementCardIndex(currentIndex, totalCards);
      expect(newIndex, equals(3));
    });

    test('Do not increment index when at the end', () {
      // Cas : currentIndex est égal à totalCards - 1 (dernière carte)
      int currentIndex = 4;
      int totalCards = 5;
      int newIndex = progressService.incrementCardIndex(currentIndex, totalCards);
      expect(newIndex, equals(4));
    });

    test('Increment index from 0 when multiple cards exist', () {
      // Cas simple, de zéro à un
      int currentIndex = 0;
      int totalCards = 3;
      int newIndex = progressService.incrementCardIndex(currentIndex, totalCards);
      expect(newIndex, equals(1));
    });
  });
}
