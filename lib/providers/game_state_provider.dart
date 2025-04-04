import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  int _elapsedTime = 0;
  int get elapsedTime => _elapsedTime;

  int _currentCardIndex = 0;
  int get currentCardIndex => _currentCardIndex;

  int _opponentCardIndex = 0;
  int get opponentCardIndex => _opponentCardIndex;

  String _playerStatus = "in game";
  String get playerStatus => _playerStatus;

  bool? _gameResult;
  bool? get gameResult => _gameResult;

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
      gameFlowService.updatePlayerCardIndex(gameFlowService.localPlayerId, newIndex);
      // On met à jour l'index local
      _currentCardIndex = newIndex;
      if (_currentCardIndex >= totalCards) {
        // On a dépassé le nombre de cartes => on met à jour la DB
        gameFlowService.updatePlayerStatus(gameFlowService.localPlayerId, 'waitingOpponent');
      }
      notifyListeners();
    }
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


      bool hasChanged = (newIndex != _currentCardIndex) ||
          (newElapsed != _elapsedTime) ||
          (newStatus != _playerStatus) ||
          (newIsOnline != _isOnline) ||
          (newScore != _score) ||
          (newResult != _gameResult) ||
          (newOpponentIndex != _opponentCardIndex);

      if (hasChanged) {
        _currentCardIndex = newIndex;
        _elapsedTime = newElapsed;
        _playerStatus = newStatus;
        _isOnline = newIsOnline;
        _score = newScore;
        _gameResult = newResult;
        _opponentCardIndex = newOpponentIndex;
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

  /// Déclare la fin de partie, ex. on fait un booleen pour la victoire/défaite
  void endGame(bool didWin) {
    _gameResult = didWin;
    notifyListeners();
    gameFlowService.endGame(gameFlowService.localPlayerId);
  }

  /// Carte courante, ou null si on a dépassé la limite
  CardModel? get currentCard =>
      (_currentCardIndex < cards.length) ? cards[_currentCardIndex] : null;
}

