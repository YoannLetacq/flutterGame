import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  final FirebaseAuth _firebaseAuth;

  UserProfileService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  /// Récupère le profil minimal de l'utilisateur connecté.
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
}
