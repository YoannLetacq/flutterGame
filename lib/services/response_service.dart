import 'package:untitled/services/similarity_service.dart';

class ResponseService {
  final SimilarityService similarityService;

  ResponseService({SimilarityService? similarityService})
      : similarityService = similarityService ?? SimilarityService();

  /// Évalue la réponse de l'utilisateur par rapport à la réponse attendue.
  /// Retourne true si la similarité dépasse le seuil (par défaut 0.8), sinon false.
  bool evaluateResponse(String userResponse, String expectedResponse, {double threshold = 0.8}) {
    final double similarity = similarityService.calculateSimilarity(userResponse, expectedResponse);
    return similarity >= threshold;
  }
}
