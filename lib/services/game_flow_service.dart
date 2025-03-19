import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled/models/game_model.dart';
import 'package:untitled/services/timer_service.dart';
import 'package:untitled/services/game_progress_service.dart';
import 'package:untitled/services/abandon_service.dart';
import 'package:untitled/services/elo_service.dart';

/// Service de gestion du déroulement de la partie.
class GameFlowService {
  final TimerService timerService;
  final GameProgressService progressService;
  final AbandonService abandonService;
  final EloService eloService;
  final GameModel game;
  final DatabaseReference gameRef; // Référence à la partie dans la Realtime Database

  int currentCardIndex = 0;
  bool isGameEnded = false;
  Timer? _gameTimer;

  GameFlowService({
    required this.timerService,
    required this.progressService,
    required this.abandonService,
    required this.eloService,
    required this.game,
    required this.gameRef,
  });

  /// Démarre le chronomètre de la partie et met à jour l'état initial dans la DB.
  /// [onTick] est appelé chaque seconde avec le temps écoulé.
  /// [onSpeedUp] est appelé dès que 5 minutes se sont écoulées.
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
      // Initialiser l'état du joueur dans la partie.
      updatePlayerState(playerId);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur lors du démarrage du chronomètre: $e');
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Met à jour l'état du joueur dans la partie (score, index, etc.) dans la DB Realtime.
  Future<void> updatePlayerState(String playerId) async {
    try {
      await gameRef.child('players').child(playerId).update({
        'currentCardIndex': currentCardIndex,
        'score': 0, // À initialiser
        'status': 'in game',
      });
      if (kDebugMode) {
        print('Etat du joueur $playerId mis à jour dans la DB.');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur lors de la mise à jour de l\'état du joueur: $e');
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Passe à la carte suivante et met à jour l'état dans la DB.
  Future<void> nextCard(String playerId) async {
    try {
      int previousIndex = currentCardIndex;
      currentCardIndex = progressService.incrementCardIndex(currentCardIndex, game.cards.length);
      if (kDebugMode) {
        print('Progression de la carte: de $previousIndex à $currentCardIndex');
      }
      // Mise à jour de l'index du joueur dans la DB.
      await gameRef.child('players').child(playerId).update({
        'currentCardIndex': currentCardIndex,
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur lors du passage à la carte suivante: $e');
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Vérifie les conditions d'abandon.
  AbandonType checkAbandon({
    required DateTime lastActive,
    required DateTime lastConnected,
    required bool modalConfirmed,
    Duration timeout = const Duration(minutes: 1),
  }) {
    try {
      final type = abandonService.getAbandonType(
        lastActive: lastActive,
        lastConnected: lastConnected,
        modalConfirmed: modalConfirmed,
        timeout: timeout,
      );
      if (kDebugMode) {
        print('Type d\'abandon détecté: $type');
      }
      return type;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur lors de la vérification des conditions d\'abandon: $e');
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Calcule la variation du classement (Elo) pour une partie classée.
  double calculateRankingChange({
    required double playerRating,
    required double opponentRating,
    required double score, // 1 pour victoire, 0.5 pour égalité, 0 pour défaite.
    required double kFactor,
  }) {
    try {
      final delta = eloService.calculateEloChange(
        playerRating: playerRating,
        opponentRating: opponentRating,
        score: score,
        kFactor: kFactor,
      );
      if (kDebugMode) {
        print('Changement de classement calculé: $delta');
      }
      return delta;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur lors du calcul du changement de classement: $e');
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Arrête le chronomètre et marque la fin de la partie, puis met à jour le statut dans la DB.
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
        print('Erreur lors de l\'arrêt du chronomètre: $e');
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Permet d'écouter les mises à jour en temps réel de l'état de la partie.
  Stream<DatabaseEvent> listenGameState() {
    return gameRef.onValue;
  }
}
