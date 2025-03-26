import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:untitled/helpers/firestore_helper.dart';
import 'package:untitled/models/card_model.dart';


/// Service pour récupérer les cartes depuis Firestore.
class CardService {

  /// Récupère la liste des cartes depuis la collection "cards".
  Future<List<CardModel>> fetchCards() async {
    try {
      final snapshot = await FirestoreHelper.getCollection(collection: 'cards');
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
