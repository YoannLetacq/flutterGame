import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:untitled/helpers/firestore_helper.dart';
import 'package:untitled/helpers/realtime_db_helper.dart';
import 'package:untitled/services/user_profile_service.dart';
import 'package:uuid/uuid.dart';

/// Service d’authentification :
/// – login Google
/// – session unique (1 seul appareil connecté à la fois)
/// – présence temps-réel (RTDB)
/// – expose un flag `kickedByOtherDevice` consommable par l’UI
class AuthService extends ChangeNotifier {
  // ───────────────────────── constructors & fields ──────────────────────────
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Id unique de **cette** session
  final String sessionId = const Uuid().v4();

  /// stream qui surveille le champ `sessionId` dans Firestore
  StreamSubscription<DocumentSnapshot>? _sessionSub;

  /// utilisé par l’UI pour afficher une notif « éjecté »
  bool _kicked = false;
  bool get kickedByOtherDevice {
    final v = _kicked;
    _kicked = false; // évite répétitions
    return v;
  }

  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // ──────────────────────────── getters helpers ─────────────────────────────
  User? get currentUser => _firebaseAuth.currentUser;
  bool  get isLoggedIn  => currentUser != null;

  // ───────────────────────────────── login ──────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1. Google OAuth
      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
      if (gUser == null) return null; // annulé

      final gAuth = await gUser.authentication;
      final cred  = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken   : gAuth.idToken,
      );

      // 2. Firebase auth
      final userCred = await _firebaseAuth.signInWithCredential(cred);
      final user     = userCred.user!;
      final uid      = user.uid;

      // 3. Profil Firestore (si 1ʳᵉ fois)
      if (!await FirestoreHelper.documentExists(collection: 'users', docId: uid)) {
        await UserProfileService().createUserProfile(user);
      }

      // 4. Unique session ▶ maj `sessionId`
      await _syncSession(uid);

      // 5. Watcher kick
      _startSessionWatcher(uid);

      return userCred;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Auth error: $e');
        debugPrintStack(stackTrace: st);
      }
      rethrow;
    }
  }

  // ───────────────────────────────── logout ────────────────────────────────
  Future<void> signOut({bool fromWatcher = false}) async {
    try {
      final uid = currentUser?.uid;

      // stop watcher
      await _sessionSub?.cancel();
      _sessionSub = null;

      // Firebase / Google sign-out
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();

      // Firestore clean seulement si c’est un logout volontaire
      if (!fromWatcher && uid != null) {
        await FirestoreHelper.updateDocument(
          collection: 'users',
          docId: uid,
          data: {
            'sessionId'   : '',
            'isOnline'    : false,
            'lastActivity': DateTime.now(),
          },
        );
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Sign-out error: $e');
        debugPrintStack(stackTrace: st);
      }
      rethrow;
    }
  }

  // ────────────────────────────── private ──────────────────────────────────
  Future<void> _syncSession(String uid) async {
    // Firestore
    await FirestoreHelper.updateDocument(
      collection: 'users',
      docId: uid,
      data: {
        'sessionId'   : sessionId,
        'isOnline'    : true,
        'lastActivity': DateTime.now(),
      },
    );

    // RTDB presence
    final rtdbRef = RealtimeDBHelper.ref('users/$uid');
    await rtdbRef.onDisconnect().update({'isOnline': false, 'sessionId': null});
    await rtdbRef.set({'isOnline': true, 'sessionId': sessionId});
  }

  void _startSessionWatcher(String uid) {
    _sessionSub?.cancel(); // au cas où

    _sessionSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) async {
      final remote = doc.data()?['sessionId'] ?? '';
      if (remote.isNotEmpty && remote != sessionId) {
        // ▶ session ouverte ailleurs → kick local
        _kicked = true;
        notifyListeners();
        await signOut(fromWatcher: true);
      }
    });
  }
}
