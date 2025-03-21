import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/services/elo_service.dart';

void main() {
  group('EloService', () {
    final eloService = EloService();

    test('calcule un gain Elo positif pour une victoire contre un adversaire de même niveau', () {
      double delta = eloService.calculateEloChange(
        playerRating: 1500,
        opponentRating: 1500,
        score: 1.0, // victoire
        kFactor: 60,
      );
      // Score attendu = 0.5, donc delta = 60 * (1 - 0.5) = 30.
      expect(delta, closeTo(30.0, 0.01));
    });

    test('calcule un delta nul pour une égalité entre joueurs de même niveau', () {
      double delta = eloService.calculateEloChange(
        playerRating: 1500,
        opponentRating: 1500,
        score: 0.5, // égalité
        kFactor: 60,
      );
      // Score attendu = 0.5, donc delta = 60 * (0.5 - 0.5) = 0.
      expect(delta, closeTo(0.0, 0.01));
    });

    test('calcule une perte Elo pour une défaite contre un adversaire de même niveau', () {
      double delta = eloService.calculateEloChange(
        playerRating: 1500,
        opponentRating: 1500,
        score: 0.0, // défaite
        kFactor: 60,
      );
      // Score attendu = 0.5, donc delta = 60 * (0 - 0.5) = -30.
      expect(delta, closeTo(-30.0, 0.01));
    });

    test('prend en compte la différence de classement dans le calcul', () {
      // Joueur moins bien classé bat un joueur mieux classé.
      double delta = eloService.calculateEloChange(
        playerRating: 1400,
        opponentRating: 1600,
        score: 1.0, // victoire du joueur moins bien classé
        kFactor: 60,
      );
      // Le gain devrait être supérieur au cas de niveaux égaux (car surprise).
      expect(delta, greaterThan(30.0));
    });
  });
}
