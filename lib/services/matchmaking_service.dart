import 'package:cloud_firestore/cloud_firestore.dart';

class MatchmakingService {
  final FirebaseFirestore firestore;
  final int eloTolerance;

  MatchmakingService({
    required this.firestore,
    this.eloTolerance = 100,
  });

  /// Lance ou rejoint une partie pour l'utilisateur [userId] ayant [userElo].
  /// Retourne l'ID de la partie (gameId) si un match est trouvé/créé.
  Future<String> findMatch(String userId, int userElo) async {
    final CollectionReference requests = firestore.collection('match_requests');

    // 1) Chercher une requête existante compatible.
    final QuerySnapshot query = await requests
        .where('status', isEqualTo: 'waiting')
        .where('elo', isGreaterThanOrEqualTo: userElo - eloTolerance)
        .where('elo', isLessThanOrEqualTo: userElo + eloTolerance)
        .orderBy('timestamp', descending: false)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      // Une requête compatible existe.
      final DocumentSnapshot doc = query.docs.first;
      final String opponentId = doc.id;
      final int opponentElo = doc['elo'];

      // Créer une nouvelle partie dans Firestore.
      final DocumentReference gameRef = firestore.collection('games').doc();
      await gameRef.set({
        'players': [opponentId, userId],
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'ongoing',
        'ranked': true, // Indique une partie classée.
      });
      final String newGameId = gameRef.id;

      // Mettre à jour la requête de l'adversaire.
      await doc.reference.update({
        'status': 'matched',
        'matchedWith': userId,
        'gameId': newGameId,
      });

      // Optionnel : nettoyer la requête de l'adversaire.
      await doc.reference.delete();

      return newGameId;
    } else {
      // 2) Aucune requête compatible : créer sa propre requête.
      final DocumentReference myRequestRef = requests.doc(userId);
      await myRequestRef.set({
        'elo': userElo,
        'status': 'waiting',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Attendre qu'un autre joueur matche cette requête.
      final gameId = await _waitForMatch(userId);
      await myRequestRef.delete();
      return gameId;
    }
  }

  /// Attend via le stream que la requête de [userId] soit matchée et renvoie l'ID de la partie.
  Future<String> _waitForMatch(String userId) async {
    final docRef = firestore.collection('match_requests').doc(userId);
    return docRef.snapshots().asyncMap((snap) {
      if (snap.exists && snap.data() is Map<String, dynamic>) {
        final data = snap.data() as Map<String, dynamic>;
        if (data['status'] == 'matched' && data['gameId'] != null) {
          return data['gameId'] as String;
        }
      }
      return null;
    }).firstWhere((gameId) => gameId != null) as String;
  }
}
