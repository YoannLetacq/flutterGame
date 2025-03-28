/// Évalue la réponse de l'utilisateur.
///
/// [userResponseIndex] est l'index de l'option choisie par l'utilisateur.
/// [expectedIndex] est l'index correct stocké dans la carte (champ answer).
/// Retourne true si les indices correspondent, sinon false.
class ResponseService {
  int answerCount = 0;
  int? get score => answerCount;

  /// Évalue la réponse de l'utilisateur par rapport à la réponse attendue.
  /// Retourne true si la similarité dépasse le seuil (par défaut 0.8), sinon false.
  bool evaluateResponse(int userResponseIndex, int expectedIndex) {
    if (userResponseIndex == expectedIndex) {
      answerCount++;
      return true;
    }
    return false;

  }
}
