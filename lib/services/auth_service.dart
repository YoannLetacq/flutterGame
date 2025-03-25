import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:untitled/services/user_profile_service.dart';

/// Service d'authentification gérant la connexion et la déconnexion de l'utilisateur.
///
/// - Dépendances :
///    - [FirebaseAuth] pour l'authentification Firebase.
///    - [GoogleSignIn] pour OAuth Google.
/// - Fournit un getter [currentUser] pour récupérer l'utilisateur actuellement connecté.
/// - Lors d'une première connexion, crée le profil utilisateur dans Firestore.
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  /// Retourne l'utilisateur actuellement connecté.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Tente la connexion via Google OAuth.
  /// Retourne un [UserCredential] en cas de succès, ou null si l'utilisateur annule.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Déclenche le flux de connexion Google.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // L'utilisateur a annulé la connexion.
        return null;
      }
      // Récupère l'authentification Google.
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      // Crée les credentials pour Firebase.
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // Connecte à Firebase avec ces credentials.
      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      // À la première connexion, créer un profil utilisateur Firestore.
      final User? user = userCredential.user;
      if (user != null) {
        await UserProfileService().createUserProfile(user);
      }
      return userCredential;
    } catch (e, stack) {
      if (kDebugMode) {
        print('Erreur lors de la connexion Google: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Déconnecte l'utilisateur de Firebase (et de Google si connecté via Google).
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
    } catch (e, stack) {
      if (kDebugMode) {
        print('Erreur lors de la déconnexion: $e');
        print(stack);
      }
      rethrow;
    }
  }

  /// Indique si un utilisateur est actuellement connecté.
  bool get isLoggedIn => _firebaseAuth.currentUser != null;
}
