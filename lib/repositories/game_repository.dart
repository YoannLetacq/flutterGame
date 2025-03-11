import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_repository_interface.dart';

class GameRepository implements IGameRepository {
  final FirebaseFirestore _firestore;

  GameRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createGame(Map<String, dynamic> gameData) async {
    // Utilisation de l'ID fourni dans gameData pour créer le document.
    final String gameId = gameData['id'] as String;
    await _firestore.collection('games').doc(gameId).set(gameData);
  }

  @override
  Future<Map<String, dynamic>?> getGame(String gameId) async {
    final DocumentSnapshot snapshot =
    await _firestore.collection('games').doc(gameId).get();
    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    }
    return null;
  }

  @override
  Future<void> updateGame(String gameId, Map<String, dynamic> gameData) async {
    await _firestore.collection('games').doc(gameId).update(gameData);
  }

  @override
  Future<void> deleteGame(String gameId) async {
    await _firestore.collection('games').doc(gameId).delete();
  }
}
