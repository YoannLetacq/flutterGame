import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class SessionManagementService {
  final FirebaseAuth _firebaseAuth;
  final DatabaseReference _dbReference;
  // Utilisation d'une instance statique finale pour Uuid.
  static const Uuid _uuid = Uuid();

  SessionManagementService({FirebaseAuth? firebaseAuth, FirebaseDatabase? firebaseDatabase})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _dbReference = (firebaseDatabase ?? FirebaseDatabase.instance)
            .ref()
            .child('user_sessions');

  /// Initialise une nouvelle session pour l'utilisateur connecté.
  /// Si une session existe déjà pour cet utilisateur, déconnecte la plus ancienne.
  Future<String> initializeSession() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception("Aucun utilisateur connecté.");
    }
    final String uid = user.uid;
    final String avatarUrl = user.photoURL ?? '';
    final String email = user.email ?? '';

    // Génère un nouvel identifiant de session.
    final String newSessionId = _uuid.v4();
    final int timestamp = DateTime.now().millisecondsSinceEpoch;

    // Vérifie s'il existe déjà une session pour cet utilisateur.
    final DatabaseEvent event = await _dbReference.child(uid).once();
    if (event.snapshot.value != null) {
      final Map existingSession = event.snapshot.value as Map;
      final int existingTimestamp = existingSession['timestamp'] as int;
      // Si une session existe et qu'elle est plus ancienne, on la supprime.
      if (timestamp > existingTimestamp) {
        await _dbReference.child(uid).remove();
        if (kDebugMode) {
          print('Session existante déconnectée pour $uid');
        }
      }
    }

    // Enregistre la nouvelle session.
    await _dbReference.child(uid).set({
      'sessionId': newSessionId,
      'timestamp': timestamp,
      'avatarUrl': avatarUrl,
      'email': email,
    });

    if (kDebugMode) {
      print('Nouvelle session créée pour $uid avec sessionId: $newSessionId');
    }
    return newSessionId;
  }

  /// Supprime la session de l'utilisateur lors de la déconnexion.
  Future<void> endSession() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    final String uid = user.uid;
    await _dbReference.child(uid).remove();
    if (kDebugMode) {
      print('Session supprimée pour $uid');
    }
  }
}
