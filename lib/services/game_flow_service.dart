import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled/helpers/realtime_db_helper.dart';
import 'package:untitled/providers/connectivity_provider.dart';
import 'package:untitled/services/response_service.dart';
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

  // Identifiant pour le joueur local et l'adversaire
  late final String localPlayerId;
  late final String opponentPlayerId;

  int currentCardIndex = 0;
  bool isGameEnded = false;

  // initialise connectivity provider to get the status of the connection
  final ConnectivityProvider connectivityProvider = ConnectivityProvider();

  GameFlowService({
    required this.timerService,
    required this.progressService,
    required this.abandonService,
    required this.eloService,
    required this.game,
    required this.gameRef,
  }) {
    localPlayerId = game.players.keys.first;
    opponentPlayerId = game.players.keys.last;
  }

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
      // Mise à jour de l'état du joueur local dans la DB.
      RealtimeDBHelper.updateData(
        'games/${game.id}',
        {
          'startTime': DateTime.now().millisecondsSinceEpoch,
          'modeSpeedUp': false,
        },
      );
      // Mettre a  joueur l'etat du local
      updatePlayerScore(playerId);
      updatePlayerOnlineStatus(playerId);
      updatePlayerStatus(playerId);
      updatePlayerCardIndex(playerId);
      updateElapsedTime(playerId);


      if (kDebugMode) {
        print('État du joueur local mis à jour dans la DB.');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur lors du démarrage du chronomètre: $e');
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Met à jour le statut en ligne du joueur dans la RTDB.
  /// /// [game] est l'objet de la partie en cours.
  /// /// [playerId] est l'identifiant du joueur local.
  /// /// [isOnline] est le statut à mettre à jour.
  /// [connectivityProvider] est le provider de connectivité réseau.
  /// Il donne isConnected qui indique si le joueur local a connection active..
  Future<void> updatePlayerOnlineStatus(String playerId) async {
    try {
      // Mettre à jour le statut en ligne dans la DB
      RealtimeDBHelper.updateData(
        'games/${game.id}/players/$playerId',
        {'isOnline': connectivityProvider.isConnected},
      );
      if (kDebugMode) {
        print("Statut en ligne mis à jour pour le joueur $playerId.");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour du statut en ligne: $e");
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Met à jour le temps écoulé dans la RTDB.
  /// [game] est l'objet de la partie en cours.
  /// [playerId] est l'identifiant du joueur local.
  /// [elapsedTime] est le temps écoulé à mettre à jour.
 Future<void> updateElapsedTime(String playerId) async {
    try {
      // Mettre a jour le temps ecoule dans la DB
      RealtimeDBHelper.updateData(
        'games/${game.id}/players/$playerId',
        {'elapsedTime': TimerService().elapsedSeconds },
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour du temps écoulé: $e");
        print(stackTrace);
      }
      rethrow;
    }
 }


  /// Met à jour l'index de la carte du joueur dans la RTDB.
  /// [game] est l'objet de la partie en cours.
  /// [playerId] est l'identifiant du joueur local.
  /// [currentCardIndex] est l'index de la carte à mettre à jour.
  Future<void> updatePlayerCardIndex(String playerId) async {
    try {
      // Mettre à jour l'index de la carte du joueur dans la DB
      RealtimeDBHelper.updateData(
        'games/${game.id}/players/$playerId',
        {'currentCardIndex': currentCardIndex},
      );
      if (kDebugMode) {
        print("Index de la carte mis à jour pour le joueur $playerId.");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour de l'index de la carte: $e");
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Met à jour le status du joueur dans la RTDB.
  /// [game] est l'objet de la partie en cours.
  /// [player] est l'identifiant du joueur local.
  /// [status] est le statut à mettre à jour.
 Future<void> updatePlayerStatus(String player) async {
    try {
      // Mettre à jour le statut du joueur dans la DB
      RealtimeDBHelper.updateData(
        'games/${game.id}/players/$player',
        {'status': 'in game'},
      );
      if (kDebugMode) {
        print("Statut du joueur $player mis à jour.");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour du statut du joueur: $e");
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Met a jour le score du joueur dans la RTDB.
  /// [game] est l'objet de la partie en cours.
  /// [playerId] est l'identifiant du joueur local.
  /// [score] est le score à mettre à jour.
  Future<void> updatePlayerScore(String playerId) async {
    try {
      final int score = ResponseService().answerCount;
      // Mettre à jour le score dans la DB
      RealtimeDBHelper.updateData(
        'games/${game.id}/players/$playerId',
        {'score': score},
      );
      if (kDebugMode) {
        print("Score mis à jour: $score");
      }
    } catch (e, stackTrace) {
        if (kDebugMode) {
          print("Erreur lors de la mise à jour du score: $e");
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
      await  RealtimeDBHelper.updateData('games/${game.id}/players/$playerId',
          {'status': 'finished'}
      );
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

  /// Met à jour le résultat du joueur dans la RTDB.
  /// [game] est l'objet de la partie en cours.
  /// [playerId] est l'identifiant du joueur local.
  /// [gameResult] est le résultat à mettre à jour.
  Future<void> updateGameResult(String playerId, String gameResult) async {
    try {
      // Mettre à jour le résultat du joueur dans la DB
      RealtimeDBHelper.updateData(
        'games/${game.id}/players/$playerId',
        {'gameResult': gameResult},
      );
      if (kDebugMode) {
        print("Résultat du joueur $playerId mis à jour: $gameResult");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Erreur lors de la mise à jour du résultat du joueur: $e");
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Écoute en temps réel les mises à jour de l'état de la partie (sous-arbre complet).
  /// Permet d'être notifié dès qu'un changement intervient (ex: l'autre joueur a fini ses cartes ou a abandonné).
  Future<Stream<DatabaseEvent>> listenGameState() async {
    final DatabaseReference ref = await RealtimeDBHelper.ref('games/${game.id}');
    return ref.onValue;
  }
}
