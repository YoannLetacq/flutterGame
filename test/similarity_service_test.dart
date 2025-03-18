import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/services/similarity_service.dart';

void main() {
  group('SimilarityService Tests', () {
    final similarityService = SimilarityService();

    test('Identical strings yield similarity 1.0', () {
      expect(similarityService.calculateSimilarity("flutter", "flutter"), equals(1.0));
    });

    test('Slight differences yield similarity above threshold', () {
      final similarity = similarityService.calculateSimilarity("flutter", "fluttr");
      expect(similarity, greaterThan(0.8));
    });

    test('Very different strings yield low similarity', () {
      final similarity = similarityService.calculateSimilarity("flutter", "dart");
      expect(similarity, lessThan(0.5));
    });
  });
}
