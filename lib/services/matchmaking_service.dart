import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/game_model.dart';
import '../models/player_model.dart';

/// Service de matchmaking en temps réel.
///
/// Rôle : Apparier automatiquement les joueurs deux par deux via la Realtime Database de Firebase.
/// Dépendances : [FirebaseDatabase] pour accéder à la DB en temps réel.
/// Retourne un [GameModel] nouvellement créé si un adversaire est trouvé, ou null si le joueur est placé en attente.
class MatchmakingService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Lance la recherche d'une partie pour le joueur [userId] en mode [mode] (CLASSIQUE ou CLASSEE).
  ///
  /// Si un autre joueur est déjà en attente, retire cette attente et crée une partie partagée.
  /// Sinon, place le joueur dans la file d'attente et retourne null.
  Future<GameModel?> findMatch(String userId, GameMode mode) async {
    final String modeKey = mode == GameMode.CLASSEE ? 'ranked' : 'casual';
    final DatabaseReference waitingRef = _db.ref('matchmaking/$modeKey/waiting');

    DataSnapshot snapshot = await waitingRef.get();
    if (!snapshot.exists) {
      // Aucun joueur n'est en attente, on place ce joueur dans la file d'attente.
      await waitingRef.set(userId);
      if (kDebugMode) {
        print('$userId est placé en attente dans la file $modeKey.');
      }
      return null; // Le joueur doit attendre un adversaire.
    } else {
      // Un joueur est en attente.
      final String opponentId = snapshot.value as String;
      if (opponentId == userId) {
        // Se jumeler avec soi-même n'est pas autorisé, donc continuer à attendre.
        if (kDebugMode) {
          print('Le joueur $userId est déjà en attente.');
        }
        return null;
      }
      // Un adversaire est trouvé, on retire la valeur de la file d'attente.
      await waitingRef.remove();

      // Créer une nouvelle partie dans la Realtime Database.
      final DatabaseReference newGameRef = _db.ref('games').push();
      final String gameId = newGameRef.key!;
      // Pour cet exemple, on suppose que la liste de cartes sera fournie ultérieurement par le CardService.
      List<String> cards = []; // À compléter dans une version réelle.

      // Construire le GameModel avec les données initiales.
      GameModel game = GameModel(
        id: gameId,
        cards: cards,
        mode: mode,
        players: {
          userId: PlayerModel(
            id: userId,
            cardsOrder: cards,
            currentCardIndex: 0,
            score: 0,
            status: 'in game',
            winner: null,
          ),
          opponentId: PlayerModel(
            id: opponentId,
            cardsOrder: cards,
            currentCardIndex: 0,
            score: 0,
            status: 'in game',
            winner: null,
          ),
        },
      );
      // Enregistrer la partie dans la DB.
      await newGameRef.set(game.toJson());
      if (kDebugMode) {
        print('Match trouvé ! Partie $gameId créée entre $userId et $opponentId.');
      }
      return game;
    }
  }
}
