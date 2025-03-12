import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';

/// Classe pour simuler GoogleSignIn avec la méthode signOut.
class MyMockGoogleSignIn extends MockGoogleSignIn {
  @override
  GoogleSignInAccount? currentUser;
  @override
  Future<GoogleSignInAccount?> signOut() async {
    currentUser = null;
    return null;
  }
}

void main() {
  group('AuthService Tests', () {
    late AuthService authService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MyMockGoogleSignIn mockGoogleSignIn;

    setUp(() async {
      // Initialisation des mocks pour FirebaseAuth et GoogleSignIn.
      mockGoogleSignIn = MyMockGoogleSignIn();
      final googleSignInAccount = await mockGoogleSignIn.signIn();
      final googleAuth = await googleSignInAccount!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final mockUser = MockUser(
        isAnonymous: false,
        uid: 'someuid',
        email: 'bob@somedomain.com',
        displayName: 'Bob',
      );

      mockFirebaseAuth = MockFirebaseAuth(mockUser: mockUser);
      await mockFirebaseAuth.signInWithCredential(credential);

      authService = AuthService(
        firebaseAuth: mockFirebaseAuth,
        googleSignIn: mockGoogleSignIn,
      );
    });

    test('Sign in with Google returns a valid UserCredential', () async {
      final userCredential = await authService.signInWithGoogle();
      expect(userCredential, isNotNull);
      expect(userCredential!.user, isNotNull);
      expect(userCredential.user!.email, equals('bob@somedomain.com'));
    });

    test('Sign out successfully signs out from Firebase and Google', () async {
      await authService.signOut();
      expect(mockFirebaseAuth.currentUser, isNull);
      expect(mockGoogleSignIn.currentUser, isNull);
    });
  });
}
