import 'package:firebase_database/firebase_database.dart';
import 'package:untitled/constants/app_constants.dart';
import 'package:untitled/repositories/game_repository_interface.dart';

class FirebaseGameRepository implements IGameRepository {
  final FirebaseDatabase _database;

  FirebaseGameRepository({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  @override
  Future<void> createGame(Map<String, dynamic> gameData) async {
    final String gameId = gameData['id'] as String;
    // Enregistre la partie sous "games/{id}" dans la Realtime Database.
    await _database.ref('${DBPaths.games}/$gameId').set(gameData);
  }

  @override
  Future<Map<String, dynamic>?> getGame(String gameId) async {
    final DataSnapshot snapshot =
    await _database.ref('${DBPaths.games}/$gameId').get();
    if (snapshot.exists) {
      // On suppose que les données de la partie sont stockées sous forme de Map.
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  @override
  Future<void> updateGame(String gameId, Map<String, dynamic> updates) async {
    // Mise à jour partielle du nœud de la partie.
    await _database.ref('${DBPaths.games}/$gameId').update(updates);
  }

  @override
  Future<void> deleteGame(String gameId) async {
    await _database.ref('${DBPaths.games}/$gameId').remove();
  }
}
