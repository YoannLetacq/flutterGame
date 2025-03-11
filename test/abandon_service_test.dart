import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/services/abandon_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:clock/clock.dart';

void main() {
  group('AbandonService Tests', () {
    final abandonService = AbandonService();

    test('No abandon when modal not confirmed and within timeout', () {
      final now = DateTime.now();
      expect(
        abandonService.getAbandonType(
          lastActive: now,
          lastConnected: now,
          modalConfirmed: false,
          timeout: const Duration(minutes: 1),
        ),
        equals(AbandonType.none),
      );
    });

    test('Abandon by modal when confirmed', () {
      final now = DateTime.now();
      expect(
        abandonService.getAbandonType(
          lastActive: now,
          lastConnected: now,
          modalConfirmed: true,
          timeout: const Duration(minutes: 1),
        ),
        equals(AbandonType.modal),
      );
    });

    test('Abandon by inactivity after timeout', () {
      fakeAsync((async) {
        final initialTime = DateTime(2023, 1, 1, 0, 0, 0);
        withClock(Clock(() => initialTime.add(async.elapsed)), () {
          async.elapse(const Duration(minutes: 2));
          async.flushTimers(); // S'assurer que le temps simulé est appliqué
          expect(
            abandonService.isAbandonedByInactivity(initialTime, timeout: const Duration(minutes: 1)),
            isTrue,
          );
        });
      });
    });

    test('Abandon by disconnection after timeout', () {
      fakeAsync((async) {
        final initialTime = DateTime(2023, 1, 1, 0, 0, 0);
        withClock(Clock(() => initialTime.add(async.elapsed)), () {
          async.elapse(const Duration(seconds: 90));
          async.flushTimers();
          expect(
            abandonService.isAbandonedByDisconnection(initialTime, timeout: const Duration(minutes: 1)),
            isTrue,
          );
        });
      });
    });

    test('Priority of abandonment: modal over others', () {
      // Même si l'inactivité serait dépassée, si modal est confirmé, le type modal doit être retourné.
      final now = DateTime.now().subtract(const Duration(minutes: 2)); // inactivité déjà dépassée
      expect(
        abandonService.getAbandonType(
          lastActive: now,
          lastConnected: now,
          modalConfirmed: true,
          timeout: const Duration(minutes: 1),
        ),
        equals(AbandonType.modal),
      );
    });
  });
}
