import 'package:flutter/material.dart';
import 'package:untitled/models/card_model.dart';
import 'package:untitled/services/response_service.dart';
import 'package:untitled/ui/widgets/card_response_widget.dart';

class GameScreen extends StatefulWidget {
  static const routeName = '/game';
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Simuler une carte courante pour l'exemple.
  // Dans une implémentation réelle, cette carte serait chargée via CardService.
  CardModel? currentCard;
  final ResponseService responseService = ResponseService();
  int score = 0;

  @override
  void initState() {
    super.initState();
    // Exemple de carte pour tester les deux types.
    // Pour tester le TextField, changez 'type' en "complement".
    currentCard = CardModel(
      id: 'card1',
      name: 'Exemple de Carte',
      definition:
      'Complétez la phrase : Flutter est un framework pour...',
      answer: 'Flutter est un framework pour développer des applications multiplateformes.',
      explanation: 'Explication de la réponse.',
      hints: ['framework', 'multiplateforme', 'applications'],
      imageUrl: '',
      options: ['Option A', 'Option B', 'ma réponse', 'Option D'],
      type: 'definition', // ou 'complement'
    );
  }

  void _handleResponse(String userResponse) {
    if (currentCard == null) return;
    bool isCorrect = responseService.evaluateResponse(
      userResponse,
      currentCard!.answer,
    );
    setState(() {
      if (isCorrect) {
        score += 10; // Exemple : 10 points par bonne réponse.
      }
      // Ici, vous pouvez ajouter la logique pour passer à la carte suivante.
      // Pour cet exemple, nous ne mettons pas à jour currentCard.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Screen')),
      body: currentCard == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Affichage de la question ou de la définition de la carte.
            Text(
              currentCard!.definition,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Intégration du widget de réponse qui s'adapte au type de la carte.
            CardResponseWidget(
              cardType: currentCard!.type,
              options: currentCard!.type == 'definition'
                  ? currentCard!.options
                  : null,
              onSubmit: _handleResponse,
            ),
            const SizedBox(height: 24),
            // Affichage du score.
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
