/// Service de gestion des abandons de partie.
/// - Rôle : déterminer si un joueur a abandonné la partie (volontairement ou par inactivité/déconnexion).
/// - Dépendances : aucune directe (utilise l'heure actuelle), peut être utilisé par [GameFlowService] ou un Provider de connectivité.
/// - Retourne un [AbandonType] indiquant le type d'abandon détecté, ou none si aucun.
enum AbandonType {
  none,        // Aucun abandon détecté
  modal,       // Abandon confirmé via un modal (action volontaire)
  disconnect,  // Abandon par déconnexion (perte de connexion réseau)
  inactive,    // Abandon par inactivité prolongée
}

class AbandonService {
  /// Vérifie si un abandon par inactivité est survenu.
  /// Retourne true si le temps écoulé depuis [lastActive] dépasse le [timeout] (par défaut 1 minute).
  bool isAbandonedByInactivity(DateTime lastActive, {Duration timeout = const Duration(minutes: 1)}) {
    return DateTime.now().difference(lastActive) > timeout;
  }

  /// Détermine si l'abandon via une fenêtre de confirmation est confirmé.
  /// Retourne true si [modalConfirmed] est true.
  bool isAbandonedByModal(bool modalConfirmed) {
    return modalConfirmed;
  }

  /// Vérifie si un abandon par déconnexion réseau est survenu.
  /// Retourne true si le temps écoulé depuis [lastConnected] dépasse le [timeout] (par défaut 1 minute).
  bool isAbandonedByDisconnection(DateTime lastConnected, {Duration timeout = const Duration(minutes: 1)}) {
    return DateTime.now().difference(lastConnected) > timeout;
  }

  /// Combine les vérifications pour déterminer le type d'abandon.
  /// [lastActive] : dernier moment où le joueur a été actif.
  /// [lastConnected] : dernier moment où le joueur était connecté.
  /// [modalConfirmed] : true si l'utilisateur a explicitement confirmé son abandon.
  AbandonType getAbandonType({
    required DateTime lastActive,
    required DateTime lastConnected,
    required bool modalConfirmed,
    Duration timeout = const Duration(minutes: 1),
  }) {
    if (isAbandonedByModal(modalConfirmed)) {
      return AbandonType.modal;
    } else if (isAbandonedByDisconnection(lastConnected, timeout: timeout)) {
      return AbandonType.disconnect;
    } else if (isAbandonedByInactivity(lastActive, timeout: timeout)) {
      return AbandonType.inactive;
    }
    return AbandonType.none;
  }
}
