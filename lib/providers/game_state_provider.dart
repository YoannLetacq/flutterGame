import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled/models/card_model.dart';
import 'package:untitled/services/game_progress_service.dart';
import 'package:untitled/services/response_service.dart';
import 'package:untitled/services/timer_service.dart';
import '../services/game_flow_service.dart';

class GameStateProvider extends ChangeNotifier {
  final GameFlowService gameFlowService;
  final ResponseService responseService;
  final TimerService timerService;
  final GameProgressService gameProgressService;

  /// Liste de toutes les cartes du jeu (fixée lors de l'init).
  final List<CardModel> cards;

  /// Nombre total de cartes
  int get totalCards => cards.length;

  int _score = 0;
  int get score => _score;

  int _opponentScore = 0;
  int get opponentScore => _opponentScore;

  int _elapsedTime = 0;
  int get elapsedTime => _elapsedTime;

  int _currentCardIndex = 0;
  int get currentCardIndex => _currentCardIndex;

  int _opponentCardIndex = 0;
  int get opponentCardIndex => _opponentCardIndex;

  String _playerStatus = "in game";
  String get playerStatus => _playerStatus;

  String _opponentStatus = "in game";
  String get opponentStatus => _opponentStatus;

  bool _opponentOnline = true;
  bool get opponentIsOnline => _opponentStatus != 'abandon'
      && _opponentStatus != 'disconnected'
      && _opponentOnline;

  // event consummé par l'UI, par la nofication de deco
  bool _oppJustDisconnected = false;
  bool _oppJustReconnected = false;

  bool get opponentJustDisconnected {
    final v = _oppJustDisconnected;
    _oppJustDisconnected = false;
    return v;
  }
  bool get opponentJustReconnected {
    final v = _oppJustReconnected;
    _oppJustReconnected = false;
    return v;
  }

  String? _gameResult;
  String? get gameResult => _gameResult;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  late final Stream<DatabaseEvent> _gameStateStream;

  GameStateProvider({
    required this.gameFlowService,
    required this.responseService,
    required this.timerService,
    required this.gameProgressService,
    required this.cards,
  }) {
    _listenGameFlow();
  }

  /// Compare la réponse de l'utilisateur (index choisi) avec [currentCard.answer].
  /// Si c'est correct, on incrémente le score et on passe à la carte suivante.
  void submitResponse(int chosenIndex) {
    if (_currentCardIndex >= totalCards) return;
    final currentCard = cards[_currentCardIndex];
    final isCorrect = responseService.evaluateResponse(chosenIndex, currentCard.answer);

    if (isCorrect) {
      _score++;
      gameFlowService.updatePlayerScore(gameFlowService.localPlayerId, _score);
    }
    // Passage à la carte suivante
    nextCard();

  }

  /// Avance l'index de carte via [GameProgressService].
  void nextCard() {
    final newIndex = gameProgressService.incrementCardIndex(_currentCardIndex, totalCards);

    if (newIndex != _currentCardIndex) {
      // on met à jour en DB
      gameFlowService.updatePlayerCardIndex(gameFlowService.localPlayerId, newIndex);

      // local set
      _currentCardIndex = newIndex;

      // si on vient d’atteindre la fin
      if (_currentCardIndex >= totalCards) {
        final opponentStatus = _opponentStatus;
        if (kDebugMode) {
          print('[GameState] ${gameFlowService.localPlayerId} a terminé ses cartes. OpponentStatus=$opponentStatus');
        }

        //  On vérifie si l’adversaire est “waitingOpponent” OU déjà “finished”
        if (_opponentHasFinished()) {
          if (kDebugMode) {
            print('[GameState] Les deux joueurs ont fini => endGame local');
          }
          // On signale la fin côté local
          gameFlowService.endGame(gameFlowService.localPlayerId);
          // On ne finalise pas ici, on laisse le GameScreen faire finalizeMatch
        } else {
          // sinon, on se met en waiting
          if (kDebugMode) {
            print('[GameState] local terminé => statut=waitingOpponent');
          }
          gameFlowService.updatePlayerStatus(gameFlowService.localPlayerId, 'waitingOpponent');
        }
      }

      notifyListeners();
    }
  }

  bool _opponentHasFinished() {
    return _opponentStatus == 'waitingOpponent' || _opponentStatus == 'finished';
  }


  /// Écoute la DB, met à jour l'état local
  void _listenGameFlow() async {
    _gameStateStream = await gameFlowService.listenGameState();
    _gameStateStream.listen((event) {

      final gameData = event.snapshot.value as Map?;
      if (gameData == null) return;
      final playersData = gameData['players'] as Map?;
      if (playersData == null) return;

      final localData = playersData[gameFlowService.localPlayerId] as Map?;
      final opponentData = playersData[gameFlowService.opponentPlayerId] as Map?;

      if (localData == null || opponentData == null) return;

      final newIndex = localData['currentCardIndex'] ?? _currentCardIndex;
      final newElapsed = localData['elapsedTime'] ?? _elapsedTime;
      final newStatus = localData['status'] ?? _playerStatus;
      final newIsOnline = localData['isOnline'] ?? _isOnline;
      final newScore = localData['score'] ?? _score;
      final newResult = localData['gameResult'] ?? _gameResult;

      final newOpponentIndex = opponentData['currentCardIndex'] ?? _opponentCardIndex;

      final newOpponentStatus = (opponentData['status'] ?? _opponentStatus) as String;
      final newOpponentOnline = (opponentData['isOnline'] ?? _opponentOnline) as bool;
      final newOpponentScore = (opponentData['score'] as int?) ?? _opponentScore;

      // delta de status reseau adversaire
      final wasOnline = _opponentOnline;
      if (wasOnline && !newOpponentOnline) {
        _oppJustDisconnected = true;
      } else if (!wasOnline && newOpponentOnline) {
        _oppJustReconnected = true;
      }


      bool hasChanged = (newIndex != _currentCardIndex) ||
          (newElapsed != _elapsedTime) ||
          (newStatus != _playerStatus) ||
          (newIsOnline != _isOnline) ||
          (newScore != _score) ||
          (newResult != _gameResult) ||
          (newOpponentIndex != _opponentCardIndex) ||
          (newOpponentStatus != _opponentStatus) ||
          (newOpponentScore != _opponentScore) ||
          (newOpponentOnline != _opponentOnline);

      if (hasChanged) {
        _currentCardIndex = newIndex;
        _elapsedTime = newElapsed;
        _playerStatus = newStatus;
        _isOnline = newIsOnline;
        _score = newScore;
        _gameResult = newResult;

        _opponentCardIndex = newOpponentIndex;
        _opponentStatus = newOpponentStatus;
        _opponentScore = newOpponentScore;
        _opponentOnline = newOpponentOnline;
        if (newStatus == 'finished') {
          if (kDebugMode) {
            print('[Sync] ${gameFlowService.localPlayerId} est passé à finished');
          }
        }

        notifyListeners();
      }
    });
  }

  /// Appelé chaque seconde par [GameScreen], on met à jour la DB + local.
  void updateElapsedTime(int secs) {
    _elapsedTime = secs;
    gameFlowService.updateElapsedTime(gameFlowService.localPlayerId, secs);
    notifyListeners();
  }

  /// Carte courante, ou null si on a dépassé la limite
  CardModel? get currentCard =>
      (_currentCardIndex < cards.length) ? cards[_currentCardIndex] : null;
}

