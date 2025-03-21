import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/services/abandon_service.dart';

void main() {
  group('AbandonService', () {
    final abandonService = AbandonService();

    test('détecte un abandon par inactivité au-delà du délai', () {
      DateTime lastActive = DateTime.now().subtract(const Duration(minutes: 2));
      bool result = abandonService.isAbandonedByInactivity(lastActive, timeout:const Duration(minutes: 1));
      expect(result, isTrue);
    });

    test('ne détecte pas d\'abandon par inactivité si le délai n\'est pas dépassé', () {
      DateTime lastActive = DateTime.now().subtract(const Duration(seconds: 30));
      bool result = abandonService.isAbandonedByInactivity(lastActive, timeout: const Duration(minutes: 1));
      expect(result, isFalse);
    });

    test('détecte un abandon par déconnexion au-delà du délai', () {
      DateTime lastConnected = DateTime.now().subtract(const Duration(minutes: 5));
      bool result = abandonService.isAbandonedByDisconnection(lastConnected, timeout: const Duration(minutes: 1));
      expect(result, isTrue);
    });

    test('détecte un abandon via confirmation modal', () {
      bool resultTrue = abandonService.isAbandonedByModal(true);
      bool resultFalse = abandonService.isAbandonedByModal(false);
      expect(resultTrue, isTrue);
      expect(resultFalse, isFalse);
    });

    test('getAbandonType retourne modal en priorité si modalConfirmed est true', () {
      DateTime now = DateTime.now();
      // Même si lastActive et lastConnected dépassent le délai, modalConfirmed true doit primer.
      AbandonType type = abandonService.getAbandonType(
        lastActive: now.subtract(const Duration(minutes: 10)),
        lastConnected: now.subtract(const Duration(minutes: 10)),
        modalConfirmed: true,
        timeout: const Duration(minutes: 1),
      );
      expect(type, AbandonType.modal);
    });

    test('getAbandonType retourne disconnect si déconnexion détectée (et pas de modal)', () {
      DateTime now = DateTime.now();
      AbandonType type = abandonService.getAbandonType(
        lastActive: now.subtract(const Duration(seconds: 30)),
        lastConnected: now.subtract(const Duration(minutes: 2)),
        modalConfirmed: false,
        timeout: const Duration(minutes: 1),
      );
      expect(type, AbandonType.disconnect);
    });

    test('getAbandonType retourne inactive si seulement inactivité détectée', () {
      DateTime now = DateTime.now();
      AbandonType type = abandonService.getAbandonType(
        lastActive: now.subtract(const Duration(minutes: 2)),
        lastConnected: now.subtract(const Duration(seconds: 30)),
        modalConfirmed: false,
        timeout: const Duration(minutes: 1),
      );
      expect(type, AbandonType.inactive);
    });

    test('getAbandonType retourne none si aucune condition remplie', () {
      DateTime now = DateTime.now();
      AbandonType type = abandonService.getAbandonType(
        lastActive: now.subtract(const Duration(seconds: 30)),
        lastConnected: now.subtract(const Duration(seconds: 30)),
        modalConfirmed: false,
        timeout: const Duration(minutes: 1),
      );
      expect(type, AbandonType.none);
    });
  });
}
