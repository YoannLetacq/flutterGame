import 'package:flutter/foundation.dart';
import 'package:untitled/models/card_model.dart';
import 'package:untitled/services/card_service.dart';

class CardProvider extends ChangeNotifier {
  final CardService _cardService;
  List<CardModel> cards = [];
  bool isLoading = false;
  String? errorMessage;

  CardProvider({required CardService cardService}) : _cardService = cardService;

  /// Charge toutes les cartes depuis Firestore.
  Future<void> loadCards() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      cards = await _cardService.fetchCards();
    } catch (e) {
      errorMessage = "Erreur lors du chargement des cartes : $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
