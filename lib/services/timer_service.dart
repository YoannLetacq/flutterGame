import 'dart:async';

class TimerService {
  Timer? _timer;
  int _elapsedSeconds = 0;

  /// Démarre le chronomètre.
  /// Le callback [onTick] est appelé à chaque seconde avec le nombre total de secondes écoulées.
  /// Si [onSpeedUp] est fourni, il est appelé dès que le temps atteint 300 secondes (5 minutes).
  void startTimer({
    required void Function(int elapsedSeconds) onTick,
    void Function()? onSpeedUp,
  }) {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      onTick(_elapsedSeconds);
      if (_elapsedSeconds == 300 && onSpeedUp != null) {
        onSpeedUp();
      }
    });
  }

  /// Arrête le chronomètre.
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Retourne le nombre de secondes écoulées.
  int get elapsedSeconds => _elapsedSeconds;
}
