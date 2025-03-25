import 'dart:async';

/// Service de chronométrage de partie.
/// - Rôle : gérer un chronomètre de jeu, notifier chaque seconde écoulée et déclencher un mode "speed-up".
/// - Dépendances : aucune (utilise [Timer] du Dart SDK).
/// - Retourne le temps écoulé via un callback [onTick], et peut signaler [onSpeedUp] après 5 minutes.
class TimerService {
  Timer? _timer;
  int _elapsedSeconds = 0;

  /// Démarre le chronomètre.
  /// [onTick] est appelé chaque seconde avec le nombre total de secondes écoulées.
  /// [onSpeedUp] est appelé lorsque 300 secondes (5 minutes) se sont écoulées, pour indiquer une accélération de jeu.
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

  /// Retourne le nombre de secondes écoulées depuis le démarrage.
  int get elapsedSeconds => _elapsedSeconds;
}
