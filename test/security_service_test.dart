import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/services/security_service.dart';

void main() {
  group('SecurityService Tests', () {
    final securityService = SecurityService();

    test('validateScore returns true for valid score', () {
      expect(securityService.validateScore(100), isTrue);
      expect(securityService.validateScore(0), isTrue);
      expect(securityService.validateScore(1000), isTrue);
    });

    test('validateScore returns false for invalid score', () {
      expect(securityService.validateScore(-10), isFalse);
      expect(securityService.validateScore(1500), isFalse);
    });

    test('validateExp returns true for valid exp', () {
      expect(securityService.validateExp(50), isTrue);
      expect(securityService.validateExp(0), isTrue);
      expect(securityService.validateExp(1000), isTrue);
    });

    test('validateExp returns false for invalid exp', () {
      expect(securityService.validateExp(-5), isFalse);
      expect(securityService.validateExp(2000), isFalse);
    });

    test('validateEloChange returns true for valid elo change', () {
      expect(securityService.validateEloChange(100), isTrue);
      expect(securityService.validateEloChange(-300), isTrue);
      expect(securityService.validateEloChange(500), isTrue);
    });

    test('validateEloChange returns false for invalid elo change', () {
      expect(securityService.validateEloChange(600), isFalse);
      expect(securityService.validateEloChange(-600), isFalse);
    });

    test('validateString returns true for non-empty string', () {
      expect(securityService.validateString("victoire"), isTrue);
    });

    test('validateString returns false for empty string', () {
      expect(securityService.validateString(""), isFalse);
    });

    test('validateHistoryData returns true for valid history data', () {
      final data = {
        'result': 'victoire',
        'score': 100,
        'exp': 50,
        'eloChange': 30,
      };
      expect(securityService.validateHistoryData(data), isTrue);
    });

    test('validateHistoryData returns false for invalid history data', () {
      final data = {
        'result': '',
        'score': 1500,
        'exp': -10,
        'eloChange': 600,
      };
      expect(securityService.validateHistoryData(data), isFalse);
    });
  });
}
