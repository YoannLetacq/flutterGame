import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/models/game_model.dart';
import 'package:untitled/services/timer_service.dart';
import 'package:untitled/services/game_progress_service.dart';
import 'package:untitled/services/abandon_service.dart';
import 'package:untitled/services/elo_service.dart';
import 'package:untitled/services/game_flow_service.dart';
import 'package:firebase_database/firebase_database.dart';

/// Implémentation factice minimale de FirebaseDatabase pour les tests.
class FakeFirebaseDatabase implements FirebaseDatabase {
  final FakeDatabaseReference _root = FakeDatabaseReference();
  @override
  DatabaseReference ref([String? path]) => _root.child(path ?? '');
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDatabaseReference implements DatabaseReference {
  Map<String, dynamic> data = {};

  @override
  Future<void> set(dynamic value) async {
    data = value as Map<String, dynamic>;
  }

  @override
  Future<void> update(dynamic value) async {
    data.addAll(value as Map<String, dynamic>);
  }

  @override
  Future<void> remove() async {
    data.clear();
  }

  @override
  DatabaseReference child(String path) {
    // Pour simuler une hiérarchie, on retourne une nouvelle instance partageant le même Map.
    return FakeDatabaseReference()..data = data;
  }

  @override
  Stream<DatabaseEvent> get onValue async* {
    yield FakeDatabaseEvent(data);
  }

  @override
  Future<DatabaseEvent> once([DatabaseEventType eventType = DatabaseEventType.value]) async {
    return FakeDatabaseEvent(data);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDatabaseEvent implements DatabaseEvent {
  final Map<String, dynamic> data;
  FakeDatabaseEvent(this.data);
  @override
  DataSnapshot get snapshot => FakeDataSnapshot(data);
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDataSnapshot implements DataSnapshot {
  final dynamic _value;
  FakeDataSnapshot(this._value);
  @override
  dynamic get value => _value;
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('GameFlowService Tests', () {
    late TimerService timerService;
    late GameProgressService progressService;
    late AbandonService abandonService;
    late EloService eloService;
    late GameModel game;
    late FakeFirebaseDatabase fakeDatabase;
    late DatabaseReference gameRef;
    late GameFlowService gameFlowService;

    setUp(() {
      timerService = TimerService();
      progressService = GameProgressService();
      abandonService = AbandonService();
      eloService = EloService();
      game = GameModel(
        id: 'gameFlow1',
        cards: ['card1', 'card2', 'card3', 'card4', 'card5'],
        mode: GameMode.CLASSIQUE,
        players: {},
      );
      fakeDatabase = FakeFirebaseDatabase();
      // Simuler la référence de la partie sous "games/gameFlow1"
      gameRef = fakeDatabase.ref('games/gameFlow1');
      gameFlowService = GameFlowService(
        timerService: timerService,
        progressService: progressService,
        abandonService: abandonService,
        eloService: eloService,
        game: game,
        gameRef: gameRef,
      );
    });

    test('Progression through cards', () async {
      expect(gameFlowService.currentCardIndex, equals(0));
      await gameFlowService.nextCard('player1');
      expect(gameFlowService.currentCardIndex, equals(1));
      await gameFlowService.nextCard('player1');
      expect(gameFlowService.currentCardIndex, equals(2));
      await gameFlowService.nextCard('player1');
      await gameFlowService.nextCard('player1');
      // Avec 5 cartes, le dernier index est 4.
      expect(gameFlowService.currentCardIndex, equals(4));
      await gameFlowService.nextCard('player1');
      expect(gameFlowService.currentCardIndex, equals(4));
    });

    test('Calculate ranking change', () {
      double delta = gameFlowService.calculateRankingChange(
        playerRating: 1000,
        opponentRating: 1000,
        score: 1.0,
        kFactor: 60,
      );
      expect(delta, closeTo(30.0, 0.1));
    });

    test('End game stops timer and updates player status to finished', () async {
      gameFlowService.startGame(
        onTick: (_) {},
        onSpeedUp: () {},
        playerId: 'player1',
      );
      await gameFlowService.endGame('player1');
      expect(gameFlowService.isGameEnded, isTrue);
      final event = await gameRef.child('players').child('player1').once();
      final Map data = event.snapshot.value as Map;
      expect(data['status'], equals('finished'));
    });

    // Tests pour checkAbandon
    test('checkAbandon returns none when conditions are normal', () {
      final now = DateTime.now();
      final result = gameFlowService.checkAbandon(
        lastActive: now,
        lastConnected: now,
        modalConfirmed: false,
        timeout: const Duration(minutes: 1),
      );
      expect(result, equals(AbandonType.none));
    });

    test('checkAbandon returns modal when modalConfirmed is true', () {
      final now = DateTime.now();
      final result = gameFlowService.checkAbandon(
        lastActive: now,
        lastConnected: now,
        modalConfirmed: true,
        timeout: const Duration(minutes: 1),
      );
      expect(result, equals(AbandonType.modal));
    });

    test('checkAbandon returns inactive when lastActive is too old', () {
      final now = DateTime.now();
      final lastActive = now.subtract(const Duration(minutes: 2));
      final result = gameFlowService.checkAbandon(
        lastActive: lastActive,
        lastConnected: now,
        modalConfirmed: false,
        timeout: const Duration(minutes: 1),
      );
      expect(result, equals(AbandonType.inactive));
    });

    test('checkAbandon returns disconnect when lastConnected is too old', () {
      final now = DateTime.now();
      final lastConnected = now.subtract(const Duration(minutes: 2));
      final result = gameFlowService.checkAbandon(
        lastActive: now,
        lastConnected: lastConnected,
        modalConfirmed: false,
        timeout: const Duration(minutes: 1),
      );
      expect(result, equals(AbandonType.disconnect));
    });
  });
}