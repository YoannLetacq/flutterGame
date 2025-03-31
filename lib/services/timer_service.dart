import 'dart:async';

/// Service de chronométrage de partie.
/// - Rôle : gérer un chronomètre de jeu, notifier chaque seconde écoulée
///          et déclencher un mode "speed-up" après 5 minutes.
/// - Retourne le temps écoulé via [onTick], déclenche [onSpeedUp] à 300 sec
///   et prévoit un arrêt forcé si on dépasse 6 minutes (360 sec).
class TimerService {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _speedUpActivated = false;

  /// Lance le chrono
  /// [onTick]: callback chaque seconde
  /// [onSpeedUp]: callback quand on atteint 5 minutes (300 sec)
  /// [onForcedEnd]: callback quand on atteint 6 minutes (360 sec)
  void startTimer({
    required void Function(int elapsedSeconds) onTick,
    required void Function()? onSpeedUp,
    required void Function()? onForcedEnd,
  }) {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _speedUpActivated = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      onTick(_elapsedSeconds);

      // Au bout de 5 minutes, active le "speed up"
      if (_elapsedSeconds == 300 && !_speedUpActivated) {
        _speedUpActivated = true;
        onSpeedUp?.call();
      }

      // Au bout de 6 minutes total, on arrête
      if (_speedUpActivated && _elapsedSeconds >= 360) {
        stopTimer();
        onForcedEnd?.call();
      }
    });
  }

  /// Arrête le chrono
  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  int get elapsedSeconds => _elapsedSeconds;
  bool get speedUpActivated => _speedUpActivated;
}
