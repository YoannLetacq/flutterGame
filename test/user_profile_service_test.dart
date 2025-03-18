import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/services/user_profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

void main() {
  group('UserProfileService Tests', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late UserProfileService userProfileService;

    setUp(() async {
      // Création d'un utilisateur simulé
      final mockUser = MockUser(
        uid: 'user123',
        email: 'user@example.com',
        displayName: 'Test User',
        photoURL: 'https://example.com/avatar.png',
      );
      // Créer une instance de MockFirebaseAuth avec le mockUser
      mockFirebaseAuth = MockFirebaseAuth(mockUser: mockUser);

      // Assurez-vous que l'utilisateur est bien connecté en appelant signInWithCredential.
      await mockFirebaseAuth.signInWithCredential(
        EmailAuthProvider.credential(email: 'user@example.com', password: 'password'),
      );

      userProfileService = UserProfileService(firebaseAuth: mockFirebaseAuth);
    });

    test('getUserProfile returns valid profile data', () {
      final profile = userProfileService.getUserProfile();
      expect(profile['uid'], equals('user123'));
      expect(profile['email'], equals('user@example.com'));
      expect(profile['displayName'], equals('Test User'));
      expect(profile['avatarUrl'], equals('https://example.com/avatar.png'));
    });

    test('getUserProfile throws exception if no user is connected', () async {
      await mockFirebaseAuth.signOut();
      expect(() => userProfileService.getUserProfile(), throwsException);
    });
  });
}
