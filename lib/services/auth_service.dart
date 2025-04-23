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

/// Service d'authentification gérant la connexion et la déconnexion de l'utilisateur.
/// Single session : l'utilisateur ne peut être connecté qu'une seule fois à la fois.
/// - Dépendances :
///    - [FirebaseAuth] pour l'authentification Firebase.
///    - [GoogleSignIn] pour OAuth Google.
/// - Fournit un getter [currentUser] pour récupérer l'utilisateur actuellement connecté.
/// - Lors d'une première connexion, crée le profil utilisateur dans Firestore.
class AuthService with ChangeNotifier {
  // ─── dépendances ──────────────────────────────────────────────────────────
  final FirebaseAuth     _firebaseAuth;
  final GoogleSignIn     _googleSignIn;

  AuthService({
    FirebaseAuth?  firebaseAuth,
    GoogleSignIn?  googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // ─── identifiant unique de CETTE session ─────────────────────────────────
  final String sessionId = const Uuid().v4();

  // ─── écouteurs « single-session » ─────────────────────────────────────────
  StreamSubscription<DocumentSnapshot>? _fsSub;
  StreamSubscription<DatabaseEvent>?     _rtdbSub;

  // ─── helpers publics ──────────────────────────────────────────────────────
  User? get currentUser => _firebaseAuth.currentUser;
  bool  get isLoggedIn  => currentUser != null;

  // ──────────────────────────────────────────────────────────────────────────
  //  SIGN-IN
  // ──────────────────────────────────────────────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 1) flux Google
      final GoogleSignInAccount? gUser = await _googleSignIn.signIn();
      if (gUser == null) return null; // cancel

      final gAuth = await gUser.authentication;
      final cred  = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken    : gAuth.idToken,
      );

      // 2) Firebase sign-in
      final uc = await _firebaseAuth.signInWithCredential(cred);
      final user = uc.user!;
      final uid  = user.uid;

      // 3) profil Firestore si 1ʳᵉ fois
      if (!(await FirestoreHelper.documentExists(collection: 'users', docId: uid))) {
        await UserProfileService().createUserProfile(user);
      }

      // 4) synchro session (écrase l’éventuelle précédente)
      await _syncSession(uid);

      // 5) démarrage des watchers pour détecter qu’on devient « obsolète »
      _startSessionWatch(uid);

      notifyListeners();
      return uc;
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ signInWithGoogle error: $e');
        print(st);
      }
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  SIGN-OUT  (local ou forcé)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      final uid = currentUser?.uid;

      _stopSessionWatch();                       // coupe les listeners locaux

      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();

      if (uid != null) {
        // Indique au back qu’il n’y a plus de session active
        await FirestoreHelper.updateDocument(
          collection: 'users',
          docId    : uid,
          data     : {
            'sessionId'   : '',
            'isOnline'    : false,
            'lastActivity': DateTime.now(),
          },
        );
        await RealtimeDBHelper.ref('users/$uid').set({
          'isOnline' : false,
          'sessionId': null,
        });
      }

      notifyListeners();
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ signOut error: $e');
        print(st);
      }
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  PRIVÉ : écrit la session courante dans Firestore + RTDB
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> _syncSession(String uid) async {
    // Firestore
    await FirestoreHelper.updateDocument(
      collection: 'users',
      docId    : uid,
      data     : {
        'sessionId'   : sessionId,
        'isOnline'    : true,
        'lastActivity': DateTime.now(),
      },
    );

    // RTDB (présence)
    final rtdb = RealtimeDBHelper.ref('users/$uid');
    await rtdb.onDisconnect().update({'isOnline': false, 'sessionId': null});
    await rtdb.set({'isOnline': true, 'sessionId': sessionId});
  }

  // ──────────────────────────────────────────────────────────────────────────
  //  PRIVÉ : met en place les watchers « single-session »
  // ──────────────────────────────────────────────────────────────────────────
  void _startSessionWatch(String uid) {
    // firestore
    _fsSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      final serverId = snap.data()?['sessionId'] as String? ?? '';
      _checkServerSession(serverId);
    });

    // rtdb
    _rtdbSub = FirebaseDatabase.instance
        .ref('users/$uid/sessionId')
        .onValue
        .listen((e) {
      final serverId = e.snapshot.value as String? ?? '';
      _checkServerSession(serverId);
    });
  }

  void _stopSessionWatch() {
    _fsSub?.cancel();
    _rtdbSub?.cancel();
    _fsSub = null;
    _rtdbSub = null;
  }

  // ───────── si le serverId ≠ notre sessionId → logout forcé ───────────────
  void _checkServerSession(String serverId) {
    if (serverId.isEmpty) return;           // déconnexion normale
    if (serverId == sessionId) return;      // nous sommes la session active
    // Une nouvelle session est active → on se déconnecte
    if (kDebugMode) {
      print('👋 Session remplacée par $serverId → logout forcé');
    }
    signOut();                              // ignore l await : on se ferme
  }
}
