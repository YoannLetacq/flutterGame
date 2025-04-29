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

  /// Cree deux listes de 20 cartes aléatoires a distribuer aux joueurs
  List<List<CardModel>> dealCards(List<CardModel> cards) {
    // si moins de 40 cartes, on renvoie une exeception
    if (cards.length < 20) {
      throw Exception('Pas assez de cartes pour distribuer');
    }
    final shuffledCards = cards..shuffle();
    final firstHalf = shuffledCards.sublist(0, 10);
    final secondHalf = shuffledCards.sublist(10, 20);
    return [firstHalf, secondHalf];
  }

  /// filtre les cartes en fonction de la recherche
  /// renvoie [source] filtre par [query]
  List<CardModel> filter(List<CardModel> source, String query) {
    if (query.trim().isEmpty) return List<CardModel>.from(source);

    final queryLower = query.toLowerCase();
    return source.where((card) {
      return card.name.toLowerCase().contains(queryLower) ||
          card.explanation.toLowerCase().contains(queryLower);
    }).toList();
  }
}
