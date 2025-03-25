import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';

/// Provider de connectivité réseau (ChangeNotifier).
/// - Rôle : notifier l'UI des changements d'état réseau (en ligne/hors ligne) du joueur.
/// - Dépendances : [ConnectivityService] pour interroger l'état de la connexion.
/// - Retourne un booléen `isConnected` via le ChangeNotifier (true si connecté).
class ConnectivityProvider with ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;

  ConnectivityProvider() {
    // Initialise en écoutant les changements de connectivité.
    Connectivity().onConnectivityChanged.listen((result) {
      bool nowConnected = result != ConnectivityResult.none;
      if (_isConnected != nowConnected) {
        _isConnected = nowConnected;
        notifyListeners();
      }
    });
  }

  /// Indique si l'appareil est actuellement connecté à Internet.
  bool get isConnected => _isConnected;
}
