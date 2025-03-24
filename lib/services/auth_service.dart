import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _firebaseAuth.currentUser;

  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Tente la connexion via Google OAuth.
  /// Retourne un [UserCredential] en cas de succès, ou null si l'utilisateur annule.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Déclenche le flow de connexion Google.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // L'utilisateur a annulé la connexion.
        return null;
      }
      // Récupère l'authentification Google.
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      // Crée les credentials pour Firebase.
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // Connecte à Firebase avec ces credentials.
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur lors de la connexion Google: $e');
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Déconnecte l'utilisateur de Firebase et de Google.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur lors de la déconnexion: $e');
        print(stackTrace);
      }
      rethrow;
    }
  }
}
