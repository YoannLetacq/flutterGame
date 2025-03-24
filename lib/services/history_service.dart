import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:untitled/services/security_service.dart';

class HistoryService {
  final FirebaseFirestore _firestore;
  final SecurityService _securityService = SecurityService();

  HistoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Enregistre l'historique d'une partie pour l'utilisateur [userId].
  /// [historyData] doit contenir les informations de la partie (date, résultat, score, exp, eloChange, etc.)
  Future<void> recordGameHistory(String userId,
      Map<String, dynamic> historyData) async {
    if (!_securityService.validateHistoryData(historyData)) {
      throw Exception("Données d'historique invalides");
    }
    try {
      await _firestore
          .collection('game_history')
          .doc(userId)
          .collection('history')
          .add(historyData);
      if (kDebugMode) {
        print('Historique enregistré pour $userId : $historyData');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur lors de l\'enregistrement de l\'historique : $e');
        print(stackTrace);
      }
      rethrow;
    }
  }

  /// Récupère les 10 dernières parties de l'utilisateur [userId], triées par date décroissante.
  Future<List<Map<String, dynamic>>> getRecentGames(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('game_history')
          .doc(userId)
          .collection('history')
          .orderBy('date', descending: true)
          .limit(10)
          .get();
      return querySnapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Erreur lors de la récupération de l'historique : $e");
      }
      rethrow;
    }
  }
}


