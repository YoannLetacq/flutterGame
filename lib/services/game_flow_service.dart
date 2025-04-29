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
  }) async {
    try {
      timerService.startTimer(
        onTick: onTick,
        onSpeedUp: () async {
          await RealtimeDBHelper.updateData(
            'games/${game.id}',
            {'modeSpeedUp': true},
          );
          if (kDebugMode) print('Mode speed-up activé.');
          onSpeedUp?.call();
        },
        onForcedEnd: onForcedEnd,
      );

      if (kDebugMode) print('Chronomètre démarré.');

      // 🟦 Initialisation DB
      await RealtimeDBHelper.updateData(
        'games/${game.id}',
        {
          'startTime': DateTime.now().millisecondsSinceEpoch,
          'modeSpeedUp': false,
        },
      );

      // 🟪 MàJ statut joueur
      await updatePlayerScore(playerId, 0);
      await updatePlayerOnlineStatus(playerId, true);

      // 🔁 Proprement enregistrer `onDisconnect()` (⚠️ cancel first!)
      final ref = RealtimeDBHelper.ref('games/${game.id}/players/$playerId');
      await ref.onDisconnect().cancel();
      await ref.onDisconnect().update({'isOnline': false});

      await updatePlayerStatus(playerId, 'in game');
      await updatePlayerCardIndex(playerId, 0);
      await updateElapsedTime(playerId, 0);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur startGame : $e');
        print(stackTrace);
      }
      rethrow;
    }
  }


  /// Verifie si l'adversaire est en ligne et met à jour son statut
  Future<bool> checkAndMarkOpponentDisconnected(String opponentId) async {
    try {
      final opponentRef =
      RealtimeDBHelper.ref('games/${game.id}/players/$opponentId');
      final snap = await opponentRef.get();

      final isOnline       = (snap.child('isOnline').value ?? true) == true;
      final currentStatus  = snap.child('status').value?.toString() ?? 'in game';

      // ───────── 1) premier passage : on marque disconnected ─────────
      if (!isOnline &&
          currentStatus != 'disconnected' &&
          currentStatus != 'finished') {

        if (kDebugMode) {
          print('[Disconnection] Opponent offline → status=disconnected');
        }

        await opponentRef.update({'status': 'disconnected'});
        return true;                          // vient d’être marqué
      }

      // ───────── 2) déjà marqué auparavant ─────────
      if (!isOnline && currentStatus == 'disconnected') {
        if (kDebugMode) {
          print('[Disconnection] Opponent already disconnected → skip');
        }
        return true;                          // déjà traité
      }

      return false;                           // toujours en ligne
    } catch (e) {
      if (kDebugMode) {
        print('Erreur checkAndMarkOpponentDisconnected : $e');
      }
      rethrow;
    }
  }



  /// Met à jour le statut de connexion du joueur dans la DB
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
    final ref = RealtimeDBHelper.ref('games/${game.id}');
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
    bool isAbandon = false,
  }) async {
    try {
      // 0)  Mutex : si on a déjà un gameResult on s’arrête.
      final localRef = RealtimeDBHelper.ref(
          'games/${game.id}/players/$localPlayerId');
      final snap = await localRef.child('gameResult').get();
      if (snap.exists) {
        if (kDebugMode) print('[Finalize] déjà finalisé → skip');
        return true;
      }

        timerService.stopTimer();
        isGameEnded = true;

        // 1)  Calcul victoire/défaite
        String localResult    = 'loss';
        String opponentResult = 'win';

        bool opponentDisconnected = false;
        if (!isAbandon) {
          opponentDisconnected =
          await checkAndMarkOpponentDisconnected(opponentPlayerId);
        }

        if (isAbandon) {
          /* rien à changer : défaite auto */
        } else if (opponentDisconnected) {
          localResult = 'win';
          opponentResult = 'loss';
        } else if (localScore > opponentScore) {
          localResult = 'win';
          opponentResult = 'loss';
        } else if (localScore == opponentScore) {
          localResult = 'tie';
          opponentResult = 'tie';
        }

        // 2)  Écritures atomiques
        await localRef.update({
          'status'     : isAbandon ? 'abandon' : 'finished',
          'gameResult' : localResult,
        });

        final oppRef = RealtimeDBHelper.ref(
            'games/${game.id}/players/$opponentPlayerId');
        final oppSnap = await oppRef.child('status').get();
        final alreadyAbandon = oppSnap.value == 'abandon';

        await oppRef.update({
          if (!alreadyAbandon) 'status': 'finished',
          'gameResult'        : opponentResult,
        });

        // 3)  Historique
        await historyService.recordGameHistory(localPlayerId, {
          'date'          : DateTime.now(),
          'score'         : localScore,
          'opponentScore' : opponentScore,
          'result'        : localResult,
          'mode'          : wasRanked ? 'ranked' : 'casual',
        });

        if (kDebugMode) {
          print('[Result] Local=$localScore Opp=$opponentScore '
              '→ $localResult / $opponentResult');
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

  // / Supprime le noeud de la partie si tous les joueurs sont déconnectés
  Future<void> _tryDeleteGameNodeIfFinished() async {
    final ref = RealtimeDBHelper.ref('games/${game.id}');
    await ref.runTransaction((data) {
      if (data is! Map) return Transaction.abort();

      final  players = data['players'] as Map?;
      if (players is! Map) return Transaction.abort();

      final everyoneDone = players.values.every((p) {
        final status = (p as Map)['status'] as String?;
        return status == 'finished' || status == 'abandon' || status == 'disconnected';
      });

      if (everyoneDone) {
        // en retournant `null` sur tout le noued games/gameId
        return Transaction.success(null);
      }
      return Transaction.abort();
    });
  }

  Future<void> tryDeleteGameNodeIfFinished() => _tryDeleteGameNodeIfFinished();
}