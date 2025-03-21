import 'dart:async';

class TimerService {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _speedUpTriggered = false;

  /// Démarre le chronomètre. [onTick] est appelé à chaque seconde avec le temps écoulé.
  /// [onSpeedUp] est appelé une fois quand 5 minutes se sont écoulées.
  void startTimer({
    required void Function(int elapsedSeconds) onTick,
    void Function()? onSpeedUp,
  }) {
    stopTimer(); // Assure qu'aucun autre timer ne tourne.
    _elapsedSeconds = 0;
    _speedUpTriggered = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      onTick(_elapsedSeconds);
      // Au bout de 5 minutes (300 secondes), déclenche l'accélération si pas déjà fait.
      if (!_speedUpTriggered && _elapsedSeconds >= 300) {
        _speedUpTriggered = true;
        if (onSpeedUp != null) {
          onSpeedUp();
        }
      }
    });
  }

  /// Arrête le chronomètre.
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
    _speedUpTriggered = false;
  }
}
