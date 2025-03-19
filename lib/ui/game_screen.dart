import 'package:flutter/material.dart';
import 'package:untitled/models/card_model.dart';
import 'package:untitled/services/card_service.dart';
import 'package:untitled/services/response_service.dart';
import 'package:untitled/ui/widgets/card_response_widget.dart';

class GameScreen extends StatefulWidget {
  static const routeName = '/game';
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final CardService _cardService = CardService();
  final ResponseService _responseService = ResponseService();
  List<CardModel> cards = [];
  int currentIndex = 0;
  bool isLoading = true;
  int score = 0;

  CardModel? get currentCard => (cards.isNotEmpty && currentIndex < cards.length)
      ? cards[currentIndex]
      : null;

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
      // Vous pouvez afficher un message d'erreur ici si besoin.
    }
  }

  void _handleResponse(String userResponse) {
    if (currentCard == null) return;
    bool isCorrect = _responseService.evaluateResponse(userResponse, currentCard!.answer);
    String message = isCorrect ? "Bonne réponse !" : "Mauvaise réponse";
    if (isCorrect) {
      setState(() {
        score += 10; // Exemple : 10 points pour une bonne réponse.
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );

    // Passer à la carte suivante après un délai pour permettre à l'utilisateur de voir le message
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          currentIndex++;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Screen')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentCard == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Fin des cartes !',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Score final : $score',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            // Ici, vous pouvez ajouter une navigation vers l'écran des résultats.
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Affichage de la carte
            Text(
              currentCard!.definition,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Affichage du widget de réponse qui s'adapte au type de carte.
            CardResponseWidget(
              cardType: currentCard!.type,
              options: currentCard!.type == 'definition'
                  ? currentCard!.options
                  : null,
              onSubmit: _handleResponse,
              questionText: currentCard!.type == 'definition'
                  ? currentCard!.definition
                  : currentCard!.name,
            ),
            const SizedBox(height: 24),
            // Affichage du score en cours.
            Text(
              'Score: $score',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
