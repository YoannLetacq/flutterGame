import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'elo_service.dart';

/// Service de classement des joueurs par Elo.
/// - Rôle : gérer le calcul du nouvel Elo et le classement des joueurs.
/// - Dépendances : [EloService] pour effectuer le calcul Elo, [FirebaseFirestore] pour les données utilisateurs.
/// - Retourne la variation Elo calculée et peut mettre à jour les Elo des joueurs en base.
class RankingService {
  final EloService eloService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RankingService({required this.eloService});

  /// Calcule la variation d'Elo pour une partie classée.
  /// Si [placementGamesPlayed] < 5, utilise [kInit] (ex: 200) pour phase de placement.
  /// Sinon, utilise [kStandard] (ex: 60) pour une partie classique.
  double computeEloChange({
    required double playerRating,
    required double opponentRating,
    required double score,        // 1 = victoire, 0.5 = égalité, 0 = défaite
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

  /// Met à jour les Elo des deux joueurs en fin de partie classée dans Firestore.
  /// [playerId] et [opponentId] : identifiants des deux joueurs.
  /// [playerScore] et [opponentScore] : scores finaux (1 = victoire du joueur, 0 = défaite, 0.5 = égalité).
  /// Calcule les nouveaux Elo et les enregistre dans `users/{uid}.elo` pour chaque joueur.
  Future<void> updateEloAfterGame({
    required String playerId,
    required String opponentId,
    required double playerScore,
    required double opponentScore,
  }) async {
    // Récupère les Elo actuels depuis Firestore.
    DocumentSnapshot playerDoc = await _firestore.collection('users').doc(playerId).get();
    DocumentSnapshot opponentDoc = await _firestore.collection('users').doc(opponentId).get();
    double playerElo = playerDoc['elo']?.toDouble() ?? 1000;
    double opponentElo = opponentDoc['elo']?.toDouble() ?? 1000;

    // Calcule les variations Elo pour chaque joueur.
    double deltaPlayer = computeEloChange(
      playerRating: playerElo,
      opponentRating: opponentElo,
      score: playerScore,
      placementGamesPlayed: 5, // exemple : considéré hors placement
    );
    double deltaOpponent = computeEloChange(
      playerRating: opponentElo,
      opponentRating: playerElo,
      score: opponentScore,
      placementGamesPlayed: 5,
    );

    // Calcule les nouveaux classements Elo.
    double newPlayerElo = playerElo + deltaPlayer;
    double newOpponentElo = opponentElo + deltaOpponent;

    // Met à jour les documents utilisateurs avec les nouveaux Elo.
    await _firestore.collection('users').doc(playerId).update({'elo': newPlayerElo});
    await _firestore.collection('users').doc(opponentId).update({'elo': newOpponentElo});
    if (kDebugMode) {
      print('Elo mis à jour: $playerId -> $newPlayerElo, $opponentId -> $newOpponentElo');
    }
  }
}
