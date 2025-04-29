/// Service d'évaluation de réponses.
/// - Rôle : vérifier si la réponse du joueur correspond à la réponse attendue.
class ResponseService {
  /// Vérifie si l'indice [userResponseIndex] correspond à la bonne réponse [expectedIndex].
  /// Retourne true si c'est correct, sinon false.
  bool evaluateResponse(int userResponseIndex, int expectedIndex) {
    return userResponseIndex == expectedIndex;
  }
}
