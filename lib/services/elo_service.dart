import 'dart:math';

class EloService {
  /// Calcule le changement de classement selon la formule Elo.
  /// [playerRating] : le classement actuel du joueur.
  /// [opponentRating] : le classement de l'adversaire.
  /// [score] : le score réel de la partie (1 pour victoire, 0.5 pour égalité, 0 pour défaite).
  /// [kFactor] : le coefficient K (par exemple 200 pour les parties de placement, 60 pour les parties classiques).
  ///
  /// Retourne la variation de classement, positive ou négative.
  double calculateEloChange({
    required double playerRating,
    required double opponentRating,
    required double score,
    required double kFactor,
  }) {
    // Calcul de la probabilité de victoire attendue.
    double expectedScore = 1 / (1 + pow(10, ((opponentRating - playerRating) / 400)));
    return kFactor * (score - expectedScore);
  }
}
