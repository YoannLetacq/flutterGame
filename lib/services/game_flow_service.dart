import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'timer_service.dart';
import 'game_progress_service.dart';
import 'abandon_service.dart';
import 'elo_service.dart';
import '../models/game_model.dart';

/// Service orchestrant le déroulement d'une partie en temps réel.
/// - Rôle : démarrer et arrêter la partie, mettre à jour l'état des joueurs dans la Realtime Database, et écouter l'état global du jeu.
/// - Dépendances : [TimerService] pour le chronomètre, [GameProgressService] pour la progression dans les cartes,
///   [AbandonService] pour détecter les abandons, [EloService] pour calculer le Elo en fin de partie classée,
///   et un [DatabaseReference] (gameRef) pointant sur la partie dans la Realtime DB.
/// - Retourne des flux d'événements (via `listenGameState`) ou des opérations asynchrones (démarrage/fin de partie).
class GameFlowService {
  final TimerService timerService;
  final GameProgressService progressService;
  final AbandonService abandonService;
  final EloService eloService;
  final GameModel game;
  final DatabaseReference gameRef; // Référence à la partie dans Firebase Realtime Database

  int currentCardIndex = 0;
  bool isGameEnded = false;

  GameFlowService({
    required this.timerService,
    required this.progressService,
    required this.abandonService,
    required this.eloService,
    required this.game,
    required this.gameRef,
  });

  /// Démarre la partie : lance le chronomètre et initialise l'état de départ dans la DB.
  /// [onTick] est appelé chaque seconde avec le temps écoulé.
  /// [onSpeedUp] est appelé lorsque 5 minutes se sont écoulées (accélération du jeu, ex: réduire le temps de réponse).
  /// [playerId] correspond à l'identifiant du joueur local qui démarre le jeu.
  void startGame({
    required void Function(int elapsedSeconds) onTick,
    void Function()? onSpeedUp,
    required String playerId,
  }) {
    try {
      timerService.startTimer(onTick: onTick, onSpeedUp: onSpeedUp);
      if (kDebugMode) {
        print('Chronomètre démarré.');
      }
      // Enregistre l'heure de début et désactive le mode speed-up initialement.
      gameRef.update({
        'startTime': DateTime.now().millisecondsSinceEpoch,
        'modeSpeedUp': false,
      });
      // Initialise l'état du joueur local dans la DB.
      updatePlayerState(playerId);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur lors du démarrage du chronomètre: $e');
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Met à jour l'état du joueur [playerId] dans la partie (par ex. score, index courant, statut) dans la DB Realtime.
  Future<void> updatePlayerState(String playerId) async {
    try {
      await gameRef.child('players').child(playerId).update({
        'currentCardIndex': currentCardIndex,
        'score': 0,    // initialisé à 0 au départ
        'status': 'in game',
      });
      if (kDebugMode) {
        print("État du joueur $playerId mis à jour dans la DB.");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour de l'état du joueur: $e");
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Termine la partie pour le joueur [playerId] : arrête le chronomètre et met à jour son statut dans la DB.
  Future<void> endGame(String playerId) async {
    try {
      timerService.stopTimer();
      isGameEnded = true;
      await gameRef.child('players').child(playerId).update({
        'status': 'finished',
      });
      if (kDebugMode) {
        print('Partie terminée pour $playerId, chronomètre arrêté.');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Erreur lors de l'arrêt du chronomètre: $e");
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Écoute en temps réel les mises à jour de l'état de la partie (sous-arbre complet).
  /// Permet d'être notifié dès qu'un changement intervient (ex: l'autre joueur a fini ses cartes ou a abandonné).
  Stream<DatabaseEvent> listenGameState() {
    return gameRef.onValue;
  }
}
