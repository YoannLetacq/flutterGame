import 'package:untitled/helpers/firestore_helper.dart';

/// Évalue la réponse de l'utilisateur.
///
/// [userResponseIndex] est l'index de l'option choisie par l'utilisateur.
/// [expectedIndex] est l'index correct stocké dans la carte (champ answer).
/// Retourne true si les indices correspondent, sinon false.
class ResponseService {
  int answerCount = 0;
  int? get score => answerCount;

  /// Évalue la réponse de l'utilisateur par rapport à la réponse attendue.
  bool evaluateResponse(int userResponseIndex, int expectedIndex) {
    if (userResponseIndex == expectedIndex) {
      answerCount++;
      return true;
    }
    return false;

  }

/// Recupere la reponse dans la database.
  /// answer est l'index de la bonne reponse parmis options.
  Future<int> getAnswerFromDB(String collection, String docId, String field) async {
    final answer = await FirestoreHelper.getField(
        collection: collection,
        docId: docId,
        field: field
    );
    return answer as int;
  }
}
