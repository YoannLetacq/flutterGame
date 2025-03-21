import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:untitled/constants/app_constants.dart';
import 'package:untitled/models/card_model.dart';

/// Service pour récupérer les cartes depuis Firestore.
class CardService {
  final FirebaseFirestore _firestore;

  CardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Récupère la liste des cartes depuis la collection Firestore définie.
  Future<List<CardModel>> fetchCards() async {
    try {
      final snapshot = await _firestore.collection(FirestoreCollections.cards).get();
      if (kDebugMode) {
        print('Cartes récupérées: ${snapshot.docs.length}');
      }
      return snapshot.docs.map((doc) => CardModel.fromJson(doc.data())).toList();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Erreur lors de la récupération des cartes: $e');
        print(stackTrace);
      }
      rethrow;
    }
  }
}
