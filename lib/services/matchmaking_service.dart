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
class MatchmakingService {

  /// Lance la recherche d'une partie pour le joueur [userId] en mode [mode] (CLASSIQUE ou CLASSEE).
  ///
  /// Si un autre joueur est déjà en attente, retire cette attente et crée une partie partagée.
  /// Sinon, place le joueur dans la file d'attente et retourne null.
  Future<GameModel?> findMatch(String userId, GameMode mode) async {
    final String modeKey = mode == GameMode.CLASSEE ? 'ranked' : 'casual';
    final String waitingRef = 'matchmaking/$modeKey/waiting';

    // On tente une transaction pour verifer si un joueur est déjà en attente
    TransactionResult transactionResult = await RealtimeDBHelper.runTransaction(
      waitingRef,
        (currentData) {
          if (currentData == null) {
            // Pas de joueur en attente, on place le joueur actuel en attente
            return Transaction.success(userId);
          } else {
            // un joueur est déjà en attente
            final existingUser = currentData as String?;
            if (existingUser == userId) {
              // match sois même, stop la transaction
              if (kDebugMode) {
                print('[MatchmakingService] Player $userId is already waiting');
              }
              return Transaction.abort();
            } else {
              // Adversaire trouvé -> on retire la file d'attente
              if (kDebugMode) {
                print('[MatchmakingService] Player $userId found opponent $existingUser');
              }
              return Transaction.success(null);
            }
          }
        },
    );

    if (!transactionResult.committed) {
      // transaction echouée
      if (kDebugMode) {
        print('[MatchmakingService] Transaction failed');
      }
      return null;
    }

    // On regarde le snapshot final
    DataSnapshot? snapshot = transactionResult.snapshot;
    // si snap.value == userId, alors on est en attente
    if (snapshot.value == userId) {
      if (kDebugMode) {
        print('[MatchmakingService] Player $userId is waiting');
      }
      return null;
    }

    // Adversaire trouvé
    // On crée une nouvelle partie
    final Future<DatabaseReference> newGameRef = RealtimeDBHelper.push('games');
    final String newGameId = (await newGameRef).key!;

    // on recupere la listes des cartes
    final List<List<CardModel>> cards = CardService().dealCards(await CardService().fetchCards());

    // on crée les deux joueurs
    final PlayerModel player1 = PlayerModel(id: userId,
        cardsOrder: cards[0].map((card) => card.id).toList(),
        currentCardIndex: 0,
        score: 0,
        status: 'in game',
        winner: null);

    final PlayerModel player2 = PlayerModel(id: snapshot.value as String,
        cardsOrder: cards[1].map((card) => card.id).toList(),
        currentCardIndex: 0,
        score: 0,
        status: 'in game',
        winner: null);

    if (kDebugMode) {
      print('[MatchmakingService] Players created: current : $userId, opponent : ${snapshot.value}');
    }

    // on construit la nouvelle partie
    final GameModel newGame = GameModel(
      players: {userId: player1, snapshot.value as String: player2},
      cards: cards.expand((element) => element).toList(),
      id: newGameId,
      mode: mode
    );

    // Enregistre la nouvelle partie dans la Realtime Database
    await RealtimeDBHelper.setData('games/$newGameId', newGame.toJson());
    if (kDebugMode) {
      print('[MatchmakingService] New game created: $newGameId');
    }
    return newGame;
  }
}


