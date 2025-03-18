import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/services/session_management_service.dart';

// Implémentation factice minimale de DataSnapshot.
class FakeDataSnapshot implements DataSnapshot {
  final dynamic _value;
  FakeDataSnapshot(this._value);

  @override
  dynamic get value => _value;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Implémentation factice minimale de DatabaseEvent.
class FakeDatabaseEvent implements DatabaseEvent {
  final FakeDataSnapshot _snapshot;
  FakeDatabaseEvent(this._snapshot);

  @override
  DataSnapshot get snapshot => _snapshot;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Implémentation factice minimale de DatabaseReference.
class FakeDatabaseReference implements DatabaseReference {
  final Map<String, dynamic> _data = {};

  @override
  DatabaseReference child(String path) {
    // Pour simplifier, on renvoie la même instance, peu importe le chemin.
    return this;
  }

  @override
  Future<void> set(dynamic value) async {
    _data.clear();
    _data.addAll(value as Map<String, dynamic>);
  }

  @override
  Future<void> remove() async {
    _data.clear();
  }

  // Retourne null plutôt qu'un map vide si _data est vide.
  @override
  Future<DatabaseEvent> once([DatabaseEventType eventType = DatabaseEventType.value]) async {
    if (_data.isEmpty) {
      return FakeDatabaseEvent(FakeDataSnapshot(null));
    } else {
      return FakeDatabaseEvent(
          FakeDataSnapshot(Map<String, dynamic>.from(_data))
      );
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Implémentation factice minimale de FirebaseDatabase.
class FakeFirebaseDatabase implements FirebaseDatabase {
  final FakeDatabaseReference _root = FakeDatabaseReference();

  @override
  DatabaseReference ref([String? path]) => _root;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SessionManagementService Tests', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late FakeFirebaseDatabase fakeFirebaseDatabase;
    late SessionManagementService sessionManagementService;

    setUp(() async {
      // On crée un utilisateur factice avec l'e-mail souhaitée
      final mockUser = MockUser(
        uid: 'user123',
        email: 'user@example.com',
        photoURL: 'https://example.com/avatar.png',
      );

      // On indique qu’il est connecté (signedIn: true)
      mockFirebaseAuth = MockFirebaseAuth(
        mockUser: mockUser,
        signedIn: true,
      );

      // On instancie la DB simulée
      fakeFirebaseDatabase = FakeFirebaseDatabase();

      // Puis on instancie notre service
      sessionManagementService = SessionManagementService(
        firebaseAuth: mockFirebaseAuth,
        firebaseDatabase: fakeFirebaseDatabase,
      );
    });

    test('initializeSession creates a new session', () async {
      final sessionId = await sessionManagementService.initializeSession();
      expect(sessionId, isNotNull);

      final snapshot = await fakeFirebaseDatabase
          .ref()
          .child('user_sessions')
          .child(mockFirebaseAuth.currentUser!.uid)
          .once()
          .then((event) => event.snapshot);

      final data = snapshot.value as Map;
      expect(data['sessionId'], equals(sessionId));
      expect(data['email'], equals('user@example.com'));
    });

    test('endSession removes the session', () async {
      await sessionManagementService.initializeSession();
      await sessionManagementService.endSession();

      final snapshot = await fakeFirebaseDatabase
          .ref()
          .child('user_sessions')
          .child(mockFirebaseAuth.currentUser!.uid)
          .once()
          .then((event) => event.snapshot);

      expect(snapshot.value, isNull);
    });
  });
}
