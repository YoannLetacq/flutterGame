import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service de profil utilisateur.
/// - Rôle : gestion du document utilisateur dans Firestore (création et lecture du profil).
/// - Dépendances : [FirebaseAuth] pour obtenir l'utilisateur courant, [FirebaseFirestore] pour stocker le profil.
/// - Retourne les informations de profil de l'utilisateur connecté.
class UserProfileService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  UserProfileService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Récupère le profil de base de l'utilisateur connecté (id, email, displayName, avatarUrl).
  /// Lance une exception si aucun utilisateur n'est connecté.
  Map<String, String> getUserProfile() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception("Aucun utilisateur connecté");
    }
    return {
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'avatarUrl': user.photoURL ?? '',
    };
  }

  /// Crée le document utilisateur dans Firestore à la première connexion, si inexistant.
  /// Le document est stocké dans `users/{uid}` avec les champs id, displayName, email, avatarUrl, elo.
  Future<void> createUserProfile(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final exists = await docRef.get();
    if (!exists.exists) {
      await docRef.set({
        'id': user.uid,
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'avatarUrl': user.photoURL ?? '',
        'elo': 1000, // Elo initial par défaut
      });
      if (kDebugMode) {
        print('Profil créé pour ${user.uid}');
      }
    }
  }
}
