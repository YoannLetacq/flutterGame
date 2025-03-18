import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:untitled/services/connectivity_service.dart';
/// Provides the connectivity results to the app.
///
/// This provider listens to the [ConnectivityService] and updates the connectivity results.
class ConnectivityProvider with ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();
  List<ConnectivityResult> _connectivityResults = [];

  List<ConnectivityResult> get connectivityResults => _connectivityResults;

  ConnectivityProvider() {
    _initConnectivity();
    _connectivityService.connectivityStream.listen((results) {
      _connectivityResults = results;
      notifyListeners();
    });
  }

  Future<void> _initConnectivity() async {
    try {
      _connectivityResults = await _connectivityService.checkConnectivity();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
    }
  }
}
