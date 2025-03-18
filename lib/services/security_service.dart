class SecurityService {
  /// Valide que le score est dans une plage raisonnable (par exemple, 0 à 1000).
  /// Retourne true si valide, false sinon.
  bool validateScore(num score) {
    return score >= 0 && score <= 1000;
  }

  /// Valide que les points d'expérience sont dans une plage attendue (par exemple, 0 à 1000).
  bool validateExp(num exp) {
    return exp >= 0 && exp <= 1000;
  }

  /// Valide que la variation Elo est dans une plage raisonnable (par exemple, -500 à +500).
  bool validateEloChange(num eloChange) {
    return eloChange >= -500 && eloChange <= 500;
  }

  /// Valide que la chaîne de caractères ne soit pas vide et éventuellement ne contient pas de caractères interdits.
  bool validateString(String value) {
    // Ici, nous vérifions simplement que la chaîne n'est pas vide.
    return value.isNotEmpty;
  }

  /// Méthode globale pour valider l'historique d'une partie.
  /// Les données attendues sont : 'result', 'score', 'exp', 'eloChange'.
  bool validateHistoryData(Map<String, dynamic> data) {
    if (!validateString(data['result'] as String)) return false;
    if (!validateScore(data['score'] as num)) return false;
    if (!validateExp(data['exp'] as num)) return false;
    if (!validateEloChange(data['eloChange'] as num)) return false;
    return true;
  }
}
