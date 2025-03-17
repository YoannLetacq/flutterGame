import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/services/history_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('HistoryService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late HistoryService historyService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      historyService = HistoryService(firestore: fakeFirestore);
    });

    test('Record game history successfully', () async {
      const userId = 'user123';
      final historyData = {
        'date': DateTime.now().toIso8601String(),
        'result': 'victoire',
        'score': 100,
        'exp': 50,
        'eloChange': 30,
      };

      await historyService.recordGameHistory(userId, historyData);

      final snapshot = await fakeFirestore
          .collection('game_history')
          .doc(userId)
          .collection('history')
          .get();

      expect(snapshot.docs.length, equals(1));
      expect(snapshot.docs.first.data()['result'], equals('victoire'));
    });
  });
}
