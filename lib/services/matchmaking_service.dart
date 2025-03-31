import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:untitled/helpers/realtime_db_helper.dart';
import 'package:untitled/models/card_model.dart';
import 'package:untitled/services/card_service.dart';
import '../models/game_model.dart';
import '../models/player_model.dart';

/// Service de matchmaking en temps réel.
///
/// Rôle : Apparier automatiquement les joueurs deux par deux via la Realtime Database de Firebase.
/// Dépendances : [FirebaseDatabase] pour accéder à la DB en temps réel.
/// Retourne un [GameModel] nouvellement créé si un adversaire est trouvé, ou null si le joueur est placé en attente.
class MatchmakingService with ChangeNotifier {
  /// Lance la recherche d'une partie pour le joueur [userId] en mode [mode] (CLASSIQUE ou CLASSEE).
  ///
  /// Si un autre joueur est déjà en attente, retire cette attente et crée une partie partagée.
  /// Sinon, place le joueur dans la file d'attente et retourne null.
  Future<GameModel?> findMatch(String userId, GameMode mode) async {
    final String modeKey = mode == GameMode.CLASSEE ? 'ranked' : 'casual';
    final String waitingRefPath = 'matchmaking/$modeKey/waiting';

    // Variable locale où on stocke l'ID de l'adversaire si trouvé
    String? foundOpponentId;

    // On exécute la transaction
    TransactionResult transactionResult = await RealtimeDBHelper.runTransaction(
      waitingRefPath,
          (currentData) {
        if (currentData == null) {
          // Personne dans la file -> on place ce joueur
          return Transaction.success(userId);
        } else {
          final existingUser = currentData as String?;
          if (existingUser == userId) {
            // Le joueur local est déjà en attente
            if (kDebugMode) {
              print('[MatchmakingService] Player $userId is already waiting');
            }
            // On peut choisir de le laisser en attente (Transaction.success(userId)),
            // ou de "nettoyer" la file (Transaction.success(null)).
            return Transaction.abort();
          } else {
            // On a trouvé un adversaire distinct
            foundOpponentId = existingUser; // on stocke son ID localement
            if (kDebugMode) {
              print('[MatchmakingService] Player $userId found opponent $existingUser');
            }
            // On retire la file d'attente en la passant à null
            return Transaction.success(null);
          }
        }
      },
    );

    if (!transactionResult.committed) {
      // La transaction a échoué ou a été abort
      if (kDebugMode) {
        print('[MatchmakingService] Transaction failed');
      }
      return null;
    }

    // Vérifions la valeur finale
    final snapshotValue = transactionResult.snapshot.value;

    // Si snapshotValue == userId => ce joueur vient d'être mis en attente
    if (snapshotValue == userId) {
      if (kDebugMode) {
        print('[MatchmakingService] Player $userId is now waiting');
      }
      // Pas d'adversaire pour l'instant, on retourne null => on signale "en attente"
      return null;
    }

    // Sinon, on a potentiellement un adversaire => foundOpponentId
    if (foundOpponentId == null) {
      // Cas anormal : la transaction a mis waitingRef à null
      // mais on n'a pas trouvé d'adversaire
      if (kDebugMode) {
        print('[MatchmakingService] Unexpected: foundOpponentId is null');
      }
      return null;
    }

    // À ce stade, foundOpponentId != null => on crée une partie
    final newGameRef = await RealtimeDBHelper.push('games');
    final String newGameId = newGameRef.key!;

    // on recupere la listes des cartes
    final List<List<CardModel>> cards = CardService().dealCards(await CardService().fetchCards());

    // on crée les deux joueurs
    final PlayerModel player1 = PlayerModel(
      id: userId,
      cardsOrder: cards[0].map((card) => card.id).toList(),
      currentCardIndex: 0,
      score: 0,
      status: 'in game',
      winner: null,
    );

    final PlayerModel player2 = PlayerModel(
      id: foundOpponentId!,
      cardsOrder: cards[1].map((card) => card.id).toList(),
      currentCardIndex: 0,
      score: 0,
      status: 'in game',
      winner: null,
    );

    if (kDebugMode) {
      print('[MatchmakingService] Players created: $userId vs $foundOpponentId');
    }

    // On construit la nouvelle partie
    final GameModel newGame = GameModel(
      players: {userId: player1, foundOpponentId!: player2},
      cards: cards.expand((element) => element).toList(),
      id: newGameId,
      mode: mode,
    );

    // On enregistre la partie en DB
    await RealtimeDBHelper.setData('games/$newGameId', newGame.toJson());

    if (kDebugMode) {
      print('[MatchmakingService] New game created: $newGameId');
    }

    return newGame;
  }


  StreamSubscription<DatabaseEvent>? _waitingSubscribtion;
  GameModel? _currentgame;
  bool _isWaiting = false;

  /// StartMatchmaking
  /// - Lance la recherche d'une partie pour le joueur [userId] en mode [mode] (CLASSIQUE ou CLASSEE).

  Future<void> startMatchMaking(String userId, GameMode mode) async {
    // Si findmatch retourne un GameModel non null, on est en partie
    // Sinon on est en attente, dans les deux cas on le signal a l'ui.

    final game = await findMatch(userId, mode);
    if (game != null) {
       _currentgame = game;
      _isWaiting = false;
      notifyListeners();
      return;
    } else {
      _isWaiting = true;
      notifyListeners();

      _listenForOpponent(userId, mode);
    }
  }

 void _listenForOpponent(String userId, GameMode mode) {
    final String modeKey = mode == GameMode.CLASSEE ? 'ranked' : 'casual';
    final DatabaseReference waitingRef = FirebaseDatabase.instance.ref('matchmaking/$modeKey/waiting');

   _waitingSubscribtion = waitingRef.onValue.listen((event) async {
     final data = event.snapshot.value;
     if (data != null && data is String  && data != userId) {
       // relancer findMatch si un adversaire est trouvé
        final game = await findMatch(userId, mode);
        if (game != null) {
          _currentgame = game;
          _isWaiting = false;
          // on arrete l'ecoute
          await _waitingSubscribtion?.cancel();
          _waitingSubscribtion = null;
          notifyListeners();
        }
     }
   });
 }

 Future<void> stopMatchmaking(String userId, GameMode mode) async {
    // Annule la recherche de partie en cours
   await _waitingSubscribtion?.cancel();
    _waitingSubscribtion = null;
    _isWaiting = false;
    notifyListeners();
 }

  bool get isWaiting => _isWaiting;
  GameModel? get currentGame => _currentgame;
}


