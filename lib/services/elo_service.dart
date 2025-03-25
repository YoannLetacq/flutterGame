import 'dart:math';

/// Service de calcul Elo.
/// - Rôle : calculer la variation de classement selon la formule Elo standard.
/// - Dépendances : aucune (calcul purement mathématique).
/// - Retourne la variation d'Elo (positive ou négative) en fonction du résultat de la partie.
class EloService {
  /// Calcule le changement de classement Elo.
  ///
  /// [playerRating] : classement actuel du joueur.
  /// [opponentRating] : classement de l'adversaire.
  /// [score] : score de la partie (1 pour victoire, 0.5 pour égalité, 0 pour défaite).
  /// [kFactor] : coefficient K (200 pour partie de placement, 60 pour partie classique).
  ///
  /// Retourne la variation de classement à appliquer au joueur (positive si gain, négative si perte).
  double calculateEloChange({
    required double playerRating,
    required double opponentRating,
    required double score,
    required double kFactor,
  }) {
    // Probabilité de victoire attendue du joueur (formule Elo).
    double expectedScore = 1 / (1 + pow(10, (opponentRating - playerRating) / 400));
    return kFactor * (score - expectedScore);
  }
}
