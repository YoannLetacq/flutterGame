class GameProgressService {
  /// Incrémente l'index de la carte courante.
  /// Si l'index est inférieur à (totalCards - 1), on l'incrémente, sinon on retourne le même index.
  int incrementCardIndex(int currentIndex, int totalCards) {
    if (currentIndex < totalCards - 1) {
      return currentIndex + 1;
    }
    return currentIndex; // Pas de changement si c'est la dernière carte.
  }
}
