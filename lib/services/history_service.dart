import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'security_service.dart';

/// Service d'historique des parties.
/// - Rôle : enregistrer le résultat des parties jouées pour chaque utilisateur.
/// - Dépendances : [FirebaseFirestore] pour stocker les données, [SecurityService] pour valider les données avant enregistrement.
/// - Ne retourne rien, mais enregistre un document d'historique pour l'utilisateur donné.
class HistoryService {
  final FirebaseFirestore _firestore;
  final SecurityService _securityService = SecurityService();

  HistoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Enregistre l'historique d'une partie pour l'utilisateur [userId].
  /// [historyData] doit contenir les infos de la partie (date, résultat, score, expérience, eloChange, etc.).
  /// Lance une exception si les données sont invalides selon le SecurityService.
  Future<void> recordGameHistory(String userId, Map<String, dynamic> historyData) async {
    // Valide les données d'historique pour éviter toute incohérence ou triche.
    if (!_securityService.validateHistoryData(historyData)) {
      throw Exception("Données d'historique invalides");
    }
    try {
      await _firestore.collection('game_history').doc(userId).collection('history').add(historyData);
      if (kDebugMode) {
        print('Historique enregistré pour $userId : $historyData');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print("Erreur lors de l'enregistrement de l'historique : $e");
        print(stack);
      }
      rethrow;
    }
  }
}
