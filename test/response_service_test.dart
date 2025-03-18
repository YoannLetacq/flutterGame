import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/services/response_service.dart';

void main() {
  group('ResponseService Tests', () {
    final responseService = ResponseService();

    test('Evaluate similar response returns true', () {
      bool result = responseService.evaluateResponse("flutter", "fluttr", threshold: 0.8);
      expect(result, isTrue);
    });

    test('Evaluate dissimilar response returns false', () {
      bool result = responseService.evaluateResponse("flutter", "dart", threshold: 0.8);
      expect(result, isFalse);
    });
  });
}
