enum AbandonType {
  none,       // Aucune condition d'abandon détectée
  modal,      // Abandon confirmé via le modal
  disconnect, // Abandon par déconnexion (wifi, etc.)
  inactive,   // Abandon par inactivité prolongée
}

class AbandonService {
  /// Vérifie si l'abandon par inactivité est déclenché.
  /// Retourne true si le temps écoulé depuis [lastActive] dépasse [timeout] (par défaut 1 minute).
  bool isAbandonedByInactivity(DateTime lastActive, {Duration timeout = const Duration(minutes: 1)}) {
    return DateTime.now().difference(lastActive) > timeout;
  }

  /// Détermine si l'abandon par modal est confirmé.
  /// Retourne true si le joueur a validé l'abandon via le modal.
  bool isAbandonedByModal(bool modalConfirmed) {
    return modalConfirmed;
  }

  /// Vérifie si l'abandon par déconnexion est déclenché.
  /// Retourne true si le temps écoulé depuis [lastConnected] dépasse [timeout] (par défaut 1 minute).
  bool isAbandonedByDisconnection(DateTime lastConnected, {Duration timeout = const Duration(minutes: 1)}) {
    return DateTime.now().difference(lastConnected) > timeout;
  }

  /// Combine les vérifications pour déterminer le type d'abandon.
  /// - [lastActive] : le dernier moment où le joueur a été actif.
  /// - [lastConnected] : le dernier moment où le joueur était connecté.
  /// - [modalConfirmed] : indique si l'abandon a été confirmé via modal.
  /// Le paramètre [timeout] est utilisé pour les vérifications d'inactivité et de déconnexion.
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
