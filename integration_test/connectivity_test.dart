import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:untitled/services/connectivity_service.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityService Integration Tests', () {
    final connectivityService = ConnectivityService();

    testWidgets('checkConnectivity returns a valid ConnectivityResult', (WidgetTester tester) async {
      final resultList = await connectivityService.checkConnectivity();
      // Vérifier que la liste n'est pas vide.
      expect(resultList, isNotEmpty);
      // Vérifier que le premier élément est l'une des valeurs attendues.
      expect(resultList.first, anyOf(
        equals(ConnectivityResult.mobile),
        equals(ConnectivityResult.wifi),
        equals(ConnectivityResult.none),
        equals(ConnectivityResult.ethernet),
        equals(ConnectivityResult.bluetooth),
      ));
    });

    testWidgets('connectivityStream emits connectivity events', (WidgetTester tester) async {
      final completer = Completer<void>();
      final subscription = connectivityService.connectivityStream.listen((eventList) {
        expect(eventList, isNotEmpty);
        expect(eventList.first, anyOf(
          equals(ConnectivityResult.mobile),
          equals(ConnectivityResult.wifi),
          equals(ConnectivityResult.none),
          equals(ConnectivityResult.ethernet),
          equals(ConnectivityResult.bluetooth),
        ));
        completer.complete();
      });

      // Attendre un événement avec un timeout de 5 secondes.
      await completer.future.timeout(const Duration(seconds: 5));
      await subscription.cancel();
    });
  });
}
