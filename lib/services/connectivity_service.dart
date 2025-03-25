import 'package:connectivity_plus/connectivity_plus.dart';

/// Service utilitaire de connectivité réseau.
/// - Rôle : fournir l'état courant de la connexion Internet.
/// - Dépendances : plugin Connectivity.
/// - Retourne l'état de connexion (connecté ou non).
class ConnectivityService {
  /// Vérifie la connexion réseau actuelle.
  Future<bool> checkConnection() async {
    ConnectivityResult result = (await Connectivity().checkConnectivity()) as ConnectivityResult;
    return result != ConnectivityResult.none;
  }
}
