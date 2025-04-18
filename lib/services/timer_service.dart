import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:untitled/providers/game_state_provider.dart';

/// Service de chronométrage de partie.
/// - Rôle : gérer un chronomètre de jeu, notifier chaque seconde écoulée
///          et déclencher un mode "speed-up" après 5 minutes.
/// - Retourne le temps écoulé via [onTick], déclenche [onSpeedUp] à 300 sec
///   et prévoit un arrêt forcé si on dépasse 6 minutes (360 sec).
class TimerService {
  Timer? _timer;
  Timer? _waitingTimer;
  Timer? _disconnectTimer;
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

  // Demarre le timer specfique quand un joueur termine avant l'autre
  void startWaitingTimer(void Function() onWaitingTimeout) {
    _waitingTimer?.cancel();
    _waitingTimer = Timer(const Duration(seconds: 60), () {
      onWaitingTimeout();
    });
    if (kDebugMode) { print('Waiting timer demarre.'); }
  }

  /// Arrête le timer d'attente
  void stopWaitingTimer() {
    _waitingTimer?.cancel();
    _waitingTimer = null;
    if (kDebugMode) { print('Waiting timer arrete.'); }
  }

  /// Lance un compte à rebours de 60 s côté joueur connecté
  void startDisconnectTimer(void Function() onTimeout) {
    _disconnectTimer?.cancel();
    _disconnectTimer = Timer(const Duration(seconds: 0), onTimeout);
  }

  /// Stoppe ce timer (reconnexion de l’adversaire)
  void stopDisconnectTimer() {
    _disconnectTimer?.cancel();
    _disconnectTimer = null;
  }


  int get elapsedSeconds => _elapsedSeconds;
  bool get speedUpActivated => _speedUpActivated;
}
