import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:untitled/services/timer_service.dart';

void main() {
  group('TimerService Tests', () {
    late TimerService timerService;

    setUp(() {
      timerService = TimerService();
    });

    test('Timer increments elapsed seconds', () async {
      // Utilisation de FakeAsync pour simuler le passage du temps.
      fakeAsync((async) {
        int tickCount = 0;
        timerService.startTimer(onTick: (elapsed) {
          tickCount = elapsed;
        });
        // Simuler 3 secondes d'écoulement.
        async.elapse(const Duration(seconds: 3));
        expect(tickCount, equals(3));
        timerService.stopTimer();
      });
    });

    test('SpeedUp callback is triggered at 300 seconds', () async {
      fakeAsync((async) {
        int speedUpCalled = 0;
        timerService.startTimer(
          onTick: (_) {},
          onSpeedUp: () {
            speedUpCalled++;
          },
        );
        // Simuler 300 secondes d'écoulement.
        async.elapse(const Duration(seconds: 300));
        expect(speedUpCalled, equals(1));
        timerService.stopTimer();
      });
    });
  });
}
