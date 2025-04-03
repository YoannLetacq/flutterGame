import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled/helpers/realtime_db_helper.dart';
import 'package:untitled/services/timer_service.dart';
import 'package:untitled/services/game_progress_service.dart';
import 'package:untitled/services/abandon_service.dart';
import 'package:untitled/services/elo_service.dart';
import '../models/game_model.dart';
import 'history_service.dart';

/// Gère le déroulement d'une partie (mise à jour DB, chrono, etc.)
class GameFlowService {
  final TimerService timerService;
  final GameProgressService progressService;
  final AbandonService abandonService;
  final EloService eloService;

  final GameModel game;
  final DatabaseReference gameRef;

  late final String localPlayerId;
  late final String opponentPlayerId;

  bool isGameEnded = false;

  GameFlowService({
    required this.timerService,
    required this.progressService,
    required this.abandonService,
    required this.eloService,
    required this.game,
    required this.gameRef,
    required String userId,
  }) {
    localPlayerId = userId;
    opponentPlayerId = game.players.keys.firstWhere(
          (id) => id != userId,
          orElse: () => throw Exception('Opponent not found in games players.'),
    );
  }

  void startGame({
    required void Function(int elapsedSeconds) onTick,
    required void Function()? onSpeedUp,
    required void Function()? onForcedEnd,
    required String playerId,
  }) {
    try {
      timerService.startTimer(
        onTick: onTick,
        onSpeedUp:() async {
          // Passage du mode normal au mode speed-up + ecrit dans la DB
          await RealtimeDBHelper.updateData(
            'games/${game.id}',
            {'modeSpeedUp': true},
          );
          if (kDebugMode) {print('Mode speed-up activé.');}
          if (onSpeedUp != null) { onSpeedUp(); }

        },
        onForcedEnd: onForcedEnd,
      );
      if (kDebugMode) {
        print('Chronomètre démarré.');
      }
      // Écrit un état initial
      RealtimeDBHelper.updateData(
        'games/${game.id}',
        {
          'startTime': DateTime.now().millisecondsSinceEpoch,
          'modeSpeedUp': false,
        },
      );
      // MàJ locales
      updatePlayerScore(playerId, 0);
      updatePlayerOnlineStatus(playerId, true);
      updatePlayerStatus(playerId, 'in game');
      updatePlayerCardIndex(playerId, 0);
      updateElapsedTime(playerId, 0);

    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur startGame : $e');
        print(stackTrace);
      }
      rethrow;
    }
  }

  Future<void> updatePlayerOnlineStatus(String playerId, bool isOnline) async {
    try {
      RealtimeDBHelper.updateData(
        'games/${game.id}/players/$playerId',
        {'isOnline': isOnline},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateElapsedTime(String playerId, int elapsedTime) async {
    try {
      RealtimeDBHelper.updateData(
        'games/${game.id}/players/$playerId',
        {'elapsedTime': elapsedTime},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePlayerCardIndex(String playerId, int cardIndex) async {
    try {
      RealtimeDBHelper.updateData(
        'games/${game.id}/players/$playerId',
        {'currentCardIndex': cardIndex},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePlayerStatus(String playerId, String status) async {
    try {
      RealtimeDBHelper.updateData(
        'games/${game.id}/players/$playerId',
        {'status': status},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Met à jour le score dans la DB
  Future<void> updatePlayerScore(String playerId, int newScore) async {
    try {
      RealtimeDBHelper.updateData(
        'games/${game.id}/players/$playerId',
        {'score': newScore},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> endGame(String playerId) async {
    try {
      timerService.stopTimer();
      isGameEnded = true;
      await RealtimeDBHelper.updateData(
        'games/${game.id}/players/$playerId',
        {'status': 'finished'},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateGameResult(String playerId, String gameResult) async {
    try {
      RealtimeDBHelper.updateData(
        'games/${game.id}/players/$playerId',
        {'gameResult': gameResult},
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Stream<DatabaseEvent>> listenGameState() async {
    final ref = await RealtimeDBHelper.ref('games/${game.id}');
    return ref.onValue;
  }

  /// Méthode qui termine la partie et enregistre le résultat final.
  /// 1) Stoppe le timer
  /// 2) Compare les scores localScore et opponentScore pour désigner le vainqueur
  /// 3) Met à jour la DB (statut = finished, gameResult = "win"/"loss"/"tie")
  /// 4) Enregistre l'historique via [historyService] pour le joueur local
  /// 5) Retourne true si tout se passe bien
  Future<bool> finalizeMatch({
    required int localScore,
    required int opponentScore,
    required String localPlayerId,
    required String opponentPlayerId,
    required bool wasRanked,
    required HistoryService historyService,
  }) async {
    try {
      timerService.stopTimer();
      isGameEnded = true;

      // 1) Déterminer vainqueur
      String localResult = 'loss';
      String opponentResult = 'win';
      if (localScore > opponentScore) {
        localResult = 'win';
        opponentResult = 'loss';
      } else if (localScore == opponentScore) {
        localResult = 'tie';
        opponentResult = 'tie';
      }

      // 2) Mettre à jour la DB pour les 2 joueurs
      // "finished" + gameResult ("win"/"loss"/"tie")
      await RealtimeDBHelper.updateData(
        'games/${game.id}/players/$localPlayerId',
        {
          'status': 'finished',
          'gameResult': localResult,
        },
      );
      await RealtimeDBHelper.updateData(
        'games/${game.id}/players/$opponentPlayerId',
        {
          'status': 'finished',
          'gameResult': opponentResult,
        },
      );

      // 3) Enregistrement historique
      //   - On peut décider d'enregistrer uniquement pour le joueur local
      await historyService.recordGameHistory(localPlayerId, {
        'date': DateTime.now(),
        'score': localScore,
        'opponentScore': opponentScore,
        'result': localResult,
        'mode': wasRanked ? 'ranked' : 'casual',
      });

      if (kDebugMode) {
        print('Partie finalisée : local=$localResult / opp=$opponentResult');
      }
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        print('Erreur finalizeMatch : $e');
        print(st);
      }
      return false;
    }
  }
}
