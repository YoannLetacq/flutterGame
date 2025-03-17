import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class HistoryService {
  final FirebaseFirestore _firestore;

  HistoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Enregistre l'historique d'une partie pour l'utilisateur [userId].
  /// [historyData] doit contenir les informations de la partie (date, résultat, score, exp, eloChange, etc.)
  Future<void> recordGameHistory(String userId, Map<String, dynamic> historyData) async {
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
}
