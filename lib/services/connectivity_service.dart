import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Retourne le stream de ConnectivityResult pour écouter les changements de connectivité.
  Stream<List<ConnectivityResult>> get connectivityStream => _connectivity.onConnectivityChanged;

  /// Vérifie l'état de connexion actuel.
  Future<List<ConnectivityResult>> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (kDebugMode) {
        print('État de la connectivité vérifié: $result');
      }
      return result;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur lors de la vérification de la connectivité: $e');
        print(stackTrace);
      }
      rethrow;
    }
  }
}
