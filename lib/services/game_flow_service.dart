import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:untitled/models/game_model.dart';
import 'package:untitled/services/timer_service.dart';
import 'package:untitled/services/game_progress_service.dart';
import 'package:untitled/services/abandon_service.dart';
import 'package:untitled/services/elo_service.dart';

class GameFlowService {
  final TimerService timerService;
  final GameProgressService progressService;
  final AbandonService abandonService;
  final EloService eloService;
  final GameModel game;

  int currentCardIndex = 0;
  bool isGameEnded = false;
  Timer? _gameTimer;

  GameFlowService({
    required this.timerService,
    required this.progressService,
    required this.abandonService,
    required this.eloService,
    required this.game,
  });

  /// Démarre le chronomètre de la partie.
  /// [onTick] est appelé chaque seconde avec le temps écoulé.
  /// [onSpeedUp] est appelé dès que 5 minutes se sont écoulées.
  void startGame({
    required void Function(int elapsedSeconds) onTick,
    void Function()? onSpeedUp,
  }) {
    try {
      timerService.startTimer(onTick: onTick, onSpeedUp: onSpeedUp);
      if (kDebugMode) {
        print('Chronomètre démarré.');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur lors du démarrage du chronomètre: $e');
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Passe à la carte suivante.
  void nextCard() {
    try {
      int previousIndex = currentCardIndex;
      currentCardIndex = progressService.incrementCardIndex(currentCardIndex, game.cards.length);
      if (kDebugMode) {
        print('Progression de la carte: de $previousIndex à $currentCardIndex');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur lors du passage à la carte suivante: $e');
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Vérifie les conditions d'abandon.
  /// Retourne le type d'abandon détecté.
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
      }
      if (kDebugMode) {
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
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Arrête le chronomètre et marque la fin de la partie.
  void endGame() {
    try {
      timerService.stopTimer();
      isGameEnded = true;
      if (kDebugMode) {
        print('Partie terminée, chronomètre arrêté.');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur lors de l\'arrêt du chronomètre: $e');
      }
      if (kDebugMode) {
        print(stackTrace);
      }
      rethrow;
    }
  }
}
