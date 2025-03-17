import 'package:untitled/services/elo_service.dart';

class RankingService {
  final EloService eloService;

  RankingService({required this.eloService});

  /// Calcule la variation Elo pour une partie classée.
  /// Si [placementGamesPlayed] est inférieur à 5, on utilise [kInit] (ex: 200) pour la phase de placement.
  /// Sinon, on utilise [kStandard] (ex: 60) pour les parties classiques.
  double computeEloChange({
    required double playerRating,
    required double opponentRating,
    required double score, // 1 pour victoire, 0.5 pour égalité, 0 pour défaite.
    required int placementGamesPlayed,
    double kInit = 200,
    double kStandard = 60,
  }) {
    double kFactor = placementGamesPlayed < 5 ? kInit : kStandard;
    return eloService.calculateEloChange(
      playerRating: playerRating,
      opponentRating: opponentRating,
      score: score,
      kFactor: kFactor,
    );
  }
}
