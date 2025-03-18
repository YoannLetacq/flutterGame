import 'package:flutter/material.dart';
import 'package:untitled/models/card_model.dart';
import 'package:untitled/services/card_service.dart';

class GameScreen extends StatefulWidget {
  static const routeName = '/game';
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final CardService _cardService = CardService();
  List<CardModel> cards = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final fetchedCards = await _cardService.fetchCards();
      if (mounted) {
        setState(() {
          cards = fetchedCards;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      // Vous pouvez afficher un message d'erreur dans l'UI si nécessaire
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Screen')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: cards.length,
        itemBuilder: (context, index) {
          // Ici, vous pouvez intégrer des animations pour l'apparition de chaque carte
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(cards[index].name),
              subtitle: Text(cards[index].definition),
            ),
          );
        },
      ),
    );
  }
}
