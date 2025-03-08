import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_repository_interface.dart';

class GameRepository implements IGameRepository {
  final FirebaseFirestore _firestore;

  GameRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createGame(Map<String, dynamic> gameData) async {
    // On suppose que les parties sont stockées dans la collection 'games'.
    await _firestore.collection('games').add(gameData);
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
