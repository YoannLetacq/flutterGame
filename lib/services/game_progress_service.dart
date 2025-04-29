/// Service de progression de jeu.
/// - Rôle : gérer l'index de carte actuel du joueur, et indiquer si la fin des cartes est atteinte.
/// - Dépendances : aucune directe (opérations sur indices entiers).
/// - Retourne le nouvel index de carte après incrément.
class GameProgressService {
  /// Incrémente l'index de la carte courante.
  /// Si [currentIndex] < ([totalCards] - 1), l'index est incrémenté de 1.
  /// Sinon (dernière carte atteinte), renvoie le même index (on ne dépasse pas le dernier).
  int incrementCardIndex(int currentIndex, int totalCards) {
    return (currentIndex + 1).clamp(0, totalCards);
  }
}
