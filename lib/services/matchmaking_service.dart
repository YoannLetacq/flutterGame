import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:untitled/helpers/realtime_db_helper.dart';
import 'package:untitled/models/card_model.dart';
import 'package:untitled/models/game_model.dart';
import 'package:untitled/models/player_model.dart';
import 'package:untitled/services/card_service.dart';

/// Service de matchmaking en temps réel.
///
/// Cette classe permet de gérer l'appariement automatique de deux joueurs en temps réel
/// via Firebase Realtime Database.
/// - Le premier joueur qui entre en matchmaking est mis en attente.
/// - Le second joueur qui entre en matchmaking trouve le premier et crée la partie.
/// - Le joueur en attente est notifié automatiquement de la création de la partie.
class MatchmakingService with ChangeNotifier {
  StreamSubscription<DatabaseEvent>? _gameListener;
  bool _isWaiting = false;
  GameModel? _currentGame;
  String? _currentWaitingPath; // Pour l'annulation

  bool get isWaiting => _isWaiting;
  GameModel? get currentGame => _currentGame;

  /// Démarre le matchmaking pour un joueur donné
  Future<void> startMatchMaking(String userId, GameMode mode) async {
    final unifinishedGame = await _hasUnfinishedGame(userId);
    // Si le joueur a déjà une partie en cours, block la possibilité de relancer
    // le matchmaking via un bug
    if (unifinishedGame) {
      if (kDebugMode) print('[MatchmakingService] Unfinished game found, cancelling matchmaking');
      return;
    }
    final String modeKey = mode == GameMode.CLASSEE ? 'ranked' : 'casual';
    final String waitingPath = 'matchmaking/$modeKey/waiting';
    _currentWaitingPath = waitingPath;

    if (kDebugMode) print('[MatchmakingService] Starting matchmaking for $userId');
    String? opponentId;

    final result = await RealtimeDBHelper.ref('matchmaking/$modeKey/waiting')
        .runTransaction((currentData) {
      final data = currentData;

      if (data == null) {
        return Transaction.success(userId);
      } else if (data is String && data != userId) {
        opponentId = data;
        return Transaction.success(null);
      } else {
        return Transaction.abort();
      }
    });

    if (!result.committed) {
      if (kDebugMode) print('[MatchmakingService] Transaction aborted');
      return;
    }

    if (opponentId == null) {
      if (kDebugMode) print('[MatchmakingService] Waiting for opponent...');
      _isWaiting = true;
      notifyListeners();
      _listenForGame(userId);
    } else {
      if (kDebugMode) print('[MatchmakingService] Opponent found: $opponentId, creating game...');
      await _createGame(userId, opponentId!, mode);
    }
  }

  /// Ecoute les événements de création de partie
  void _listenForGame(String userId) {
    _gameListener = RealtimeDBHelper.ref('games').onChildAdded.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;
      if (data['cards'] is! List) return;
      final players = data['players'] as Map?;
      if (players == null) return;

      if (players.containsKey(userId)) {
            if (_currentGame != null) return;
            final stillExist = (event.snapshot.exists &&
                event.snapshot.child('cards').exists);
            if (!stillExist) return;

            if (kDebugMode) print('[MatchmakingService] Game Detected');
            _currentGame = GameModel.fromJson({...data, 'id': event.snapshot.key});
            _isWaiting = false;
            _gameListener?.cancel();
            _gameListener = null;
            notifyListeners();
      }
    });
  }

  /// Création de la partie associe le joueur 2 avec le joueur 1
  /// instancie les modèles de jeu et de joueur
  Future<void> _createGame(String userId, String opponentId, GameMode mode) async {
    final unifinishedGame = await _hasUnfinishedGame(userId);
    // Si le joueur a déjà une partie en cours, block la possibilité de relancer
    // le matchmaking via un bug
    if (unifinishedGame) {
      if (kDebugMode) print('[MatchmakingService] Unfinished game found, cancelling games creation');
      return;
    }
    final newGameRef = RealtimeDBHelper.push('games');
    final String newGameId = newGameRef.key!;

    final List<List<CardModel>> cards = CardService().dealCards(await CardService().fetchCards());

    final PlayerModel player1 = PlayerModel(
      id: opponentId,
      cardsOrder: cards[0].map((card) => card.id).toList(),
      currentCardIndex: 0,
      score: 0,
      status: 'in game',
      winner: null,
    );

    final PlayerModel player2 = PlayerModel(
      id: userId,
      cardsOrder: cards[1].map((card) => card.id).toList(),
      currentCardIndex: 0,
      score: 0,
      status: 'in game',
      winner: null,
    );

    final GameModel newGame = GameModel(
      players: {opponentId: player1, userId: player2},
      cards: cards.expand((e) => e).toList(),
      id: newGameId,
      mode: mode,
    );

    await RealtimeDBHelper.setData('games/$newGameId', newGame.toJson());

    _currentGame = newGame;
    _isWaiting = false;
    notifyListeners();
  }

  /// Stop matchmaking & clean
  Future<void> stopMatchmaking() async {
    if (_currentWaitingPath != null) {
      await RealtimeDBHelper.removeData(_currentWaitingPath!);
      if (kDebugMode) print('[MatchmakingService] Stopped matchmaking');
    }
    await _gameListener?.cancel();
    _gameListener = null;
    _isWaiting = false;
    notifyListeners();
  }

  Future<bool> _hasUnfinishedGame(String playerId) async {
    final snap = await RealtimeDBHelper.ref(
      'games',
    )
        .orderByChild('players/$playerId/status')
        .equalTo('in game')
        .once();

    if (snap.snapshot.exists) return true;

    final waitingSnap = await RealtimeDBHelper.ref('games')
        .orderByChild('players/$playerId/status')
        .equalTo('waitingOpponent')
        .once();

    final dc = await RealtimeDBHelper.ref('games')
        .orderByChild('players/$playerId/status')
        .equalTo('disconnected')
        .once();
    if (waitingSnap.snapshot.exists || dc.snapshot.exists) {
      if (kDebugMode) print('[MatchmakingService] Unfinished game found');
      return true;
    }
    return false;
  }

  void clear() {
    _currentGame  = null;
    _isWaiting    = false;
    _gameListener?.cancel();
    _gameListener = null;
    notifyListeners();
  }
}

