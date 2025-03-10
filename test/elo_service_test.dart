import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/services/elo_service.dart';

void main() {
  group('EloService Tests', () {
    final eloService = EloService();

    test('Victory scenario (score = 1)', () {
      // Cas d'une victoire contre un adversaire avec un classement similaire.
      double playerRating = 1000;
      double opponentRating = 1000;
      double score = 1.0;
      double kFactor = 60;

      double eloChange = eloService.calculateEloChange(
        playerRating: playerRating,
        opponentRating: opponentRating,
        score: score,
        kFactor: kFactor,
      );

      // Pour deux joueurs de même classement, expectedScore = 0.5.
      // Ainsi, eloChange devrait être kFactor * (1 - 0.5) = 60 * 0.5 = 30.
      expect(eloChange, closeTo(30.0, 0.1));
    });

    test('Defeat scenario (score = 0)', () {
      // Cas d'une défaite contre un adversaire de même classement.
      double playerRating = 1000;
      double opponentRating = 1000;
      double score = 0.0;
      double kFactor = 60;

      double eloChange = eloService.calculateEloChange(
        playerRating: playerRating,
        opponentRating: opponentRating,
        score: score,
        kFactor: kFactor,
      );

      // Pour deux joueurs de même classement, eloChange = 60 * (0 - 0.5) = -30.
      expect(eloChange, closeTo(-30.0, 0.1));
    });

    test('Draw scenario (score = 0.5)', () {
      // Cas d'une égalité entre deux joueurs.
      double playerRating = 1000;
      double opponentRating = 1000;
      double score = 0.5;
      double kFactor = 60;

      double eloChange = eloService.calculateEloChange(
        playerRating: playerRating,
        opponentRating: opponentRating,
        score: score,
        kFactor: kFactor,
      );

      // Pour une égalité, eloChange devrait être proche de 0.
      expect(eloChange, closeTo(0.0, 0.1));
    });

    test('Victory against higher-rated opponent', () {
      // Cas où un joueur gagne contre un adversaire mieux classé.
      double playerRating = 1000;
      double opponentRating = 1200;
      double score = 1.0;
      double kFactor = 60;

      double eloChange = eloService.calculateEloChange(
        playerRating: playerRating,
        opponentRating: opponentRating,
        score: score,
        kFactor: kFactor,
      );

      // Dans ce cas, expectedScore est inférieur à 0.5, donc le gain devrait être plus important.
      expect(eloChange, greaterThan(30.0));
    });
  });
}
