/// Service de sécurité et validation des données.
/// - Rôle : vérifier l'intégrité des données de jeu pour prévenir la triche ou les incohérences.
/// - Dépendances : aucune directe. Utilisé par d'autres services (ex: HistoryService) pour valider des informations.
/// - Retourne un booléen indiquant si les données sont valides.
class SecurityService {
  /// Valide les données d'historique de partie [historyData].
  /// Par exemple, vérifie que les scores sont positifs et que les champs requis existent.
  bool validateHistoryData(Map<String, dynamic> historyData) {
    if (!historyData.containsKey('score') || !historyData.containsKey('result')) {
      return false;
    }
    // On peut ajouter d'autres règles de validation si nécessaire.
    if (historyData['score'] is int && historyData['score'] < 0) {
      return false;
    }
    return true;
  }

  /// (Exemple supplémentaire) Valide une réponse de joueur pour éviter les réponses vides ou invalides.
  bool validatePlayerResponse(String response) {
    return response.trim().isNotEmpty;
  }
}
