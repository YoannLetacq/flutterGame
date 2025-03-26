import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/game_model.dart';
import '../services/game_flow_service.dart';

/// Provider qui expose l'etat du jeu en cours.
/// Il ecoute le flux d'evenements via GameFlowService et notifie les listeners a chaque changement.
/// met a jour l'etat du jeu en cours.

class GameStateProvider extends ChangeNotifier {
  final GameFlowService gameFlowService;

  int _elapsedTime = 0;
  int get elapsedTime => _elapsedTime;

  int _currentCardIndex = 0;
  int get currentCardIndex => _currentCardIndex;

  late String _playerStatus = "in game";
  String get playerStatus => _playerStatus;

  bool? _gameResult;
  bool? get gameResult => _gameResult;

  late bool _isOnline = true;
  bool? get isOnline => _isOnline;

  late final Stream<DatabaseEvent> _gameStateStream;
  GameStateProvider({
    required this.gameFlowService,
  }) {
    _listenGameFlow();
  }

  void _listenGameFlow() {
    _gameStateStream = gameFlowService.listenGameState();
    _gameStateStream.listen((event) {
     final gameData = event.snapshot.value as Map?;
     if (gameData != null) {
       // Mise a jour de l'etat du joueur local
       final playerData = gameData['players'] as Map?;
       if (playerData != null) {
         final localData = playerData[gameFlowService.localPlayerId] as Map?;
         if (localData != null) {
           // Mise a jour de l'etat local a partir de la DB
            _currentCardIndex = localData['currentCardIndex'] ?? _currentCardIndex;
            _elapsedTime = localData['elapsedTime'] ?? _elapsedTime;
            _playerStatus = localData['status'] ?? _playerStatus;
            _gameResult = localData['gameResult'] ?? _gameResult;
            _isOnline = localData['isOnline'] ?? _isOnline;
         }
       }
       notifyListeners();
     }
       });
  }

  /// Met a jour le temps ecoule et notifie l'UI.
  void updateElapsedTime(int newElapsedTime) {
    _elapsedTime = newElapsedTime;
    notifyListeners();
  }

  /// Signale la fin de partie et enregistre le resultat.
  void endGame(bool gameResult) {
    _gameResult = gameResult;
    notifyListeners();
  }
}