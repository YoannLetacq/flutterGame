import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/services/elo_service.dart';
import 'package:untitled/services/ranking_service.dart';

void main() {
  group('RankingService Tests', () {
    final eloService = EloService();
    late RankingService rankingService;

    setUp(() {
      rankingService = RankingService(eloService: eloService);
    });

    test('Compute Elo change for victory in placement phase', () {
      // Si le joueur a joué moins de 5 parties, on utilise kInit.
      double change = rankingService.computeEloChange(
        playerRating: 1000,
        opponentRating: 1000,
        score: 1.0,
        placementGamesPlayed: 3, // Partie de placement
      );
      // Pour deux joueurs de même classement, expected change = 200 * (1 - 0.5) = 100.
      expect(change, closeTo(100.0, 0.1));
    });

    test('Compute Elo change for victory in standard phase', () {
      // Si le joueur a joué 5 parties ou plus, on utilise kStandard.
      double change = rankingService.computeEloChange(
        playerRating: 1000,
        opponentRating: 1000,
        score: 1.0,
        placementGamesPlayed: 5, // Partie classique
      );
      // Pour deux joueurs de même classement, expected change = 60 * (1 - 0.5) = 30.
      expect(change, closeTo(30.0, 0.1));
    });

    test('Compute Elo change for defeat scenario', () {
      // Cas d'une défaite pour deux joueurs de même niveau.
      double change = rankingService.computeEloChange(
        playerRating: 1000,
        opponentRating: 1000,
        score: 0.0,
        placementGamesPlayed: 6, // Partie classique
      );
      // Expected change = 60 * (0 - 0.5) = -30.
      expect(change, closeTo(-30.0, 0.1));
    });
  });
}
