import 'dart:async';
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
  /// Le callback [onTick] est appelé à chaque seconde avec le temps écoulé.
  /// [onSpeedUp] est appelé dès que 5 minutes se sont écoulées.
  void startGame({required void Function(int elapsedSeconds) onTick, void Function()? onSpeedUp}) {
    timerService.startTimer(onTick: onTick, onSpeedUp: onSpeedUp);
  }

  /// Passe à la carte suivante.
  void nextCard() {
    currentCardIndex = progressService.incrementCardIndex(currentCardIndex, game.cards.length);
  }

  /// Vérifie les conditions d'abandon.
  /// - [lastActive] : dernier instant d'activité.
  /// - [lastConnected] : dernier instant de connexion.
  /// - [modalConfirmed] : indique si le joueur a validé l'abandon via modal.
  AbandonType checkAbandon({
    required DateTime lastActive,
    required DateTime lastConnected,
    required bool modalConfirmed,
    Duration timeout = const Duration(minutes: 1),
  }) {
    return abandonService.getAbandonType(
      lastActive: lastActive,
      lastConnected: lastConnected,
      modalConfirmed: modalConfirmed,
      timeout: timeout,
    );
  }

  /// Calcule la variation du classement (Elo) pour une partie classée.
  /// Cette méthode doit être appelée uniquement pour les parties classées.
  double calculateRankingChange({
    required double playerRating,
    required double opponentRating,
    required double score,  // 1 pour victoire, 0.5 pour égalité, 0 pour défaite.
    required double kFactor,
  }) {
    return eloService.calculateEloChange(
      playerRating: playerRating,
      opponentRating: opponentRating,
      score: score,
      kFactor: kFactor,
    );
  }

  /// Arrête le chronomètre et marque la fin de la partie.
  void endGame() {
    timerService.stopTimer();
    isGameEnded = true;
  }
}
