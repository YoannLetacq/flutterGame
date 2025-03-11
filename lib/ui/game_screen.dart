import 'package:flutter/material.dart';
import 'package:untitled/models/game_model.dart';
import 'package:untitled/services/timer_service.dart';
import 'package:untitled/services/game_progress_service.dart';
import 'package:untitled/services/abandon_service.dart';
import 'package:untitled/services/elo_service.dart';
import 'package:untitled/services/game_flow_service.dart';

class GameScreen extends StatefulWidget {
  static const routeName = '/game';

  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameFlowService gameFlowService;
  int elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    // Création d'une instance de GameModel pour simuler une partie
    final game = GameModel(
      id: 'game1',
      cards: ['Card 1', 'Card 2', 'Card 3', 'Card 4', 'Card 5'],
      mode: GameMode.CLASSIQUE,
      players: {},
    );
    // Instanciation des services requis
    final timerService = TimerService();
    final progressService = GameProgressService();
    final abandonService = AbandonService();
    final eloService = EloService();

    gameFlowService = GameFlowService(
      timerService: timerService,
      progressService: progressService,
      abandonService: abandonService,
      eloService: eloService,
      game: game,
    );
    // Démarrer le chronomètre et mettre à jour l'UI via onTick
    gameFlowService.startGame(
      onTick: (seconds) {
        setState(() {
          elapsedSeconds = seconds;
        });
      },
      onSpeedUp: () {
        // Notification pour le mode speed-up
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mode Speed-Up activé !')),
        );
      },
    );
  }

  @override
  void dispose() {
    gameFlowService.endGame();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Temps écoulé: $elapsedSeconds secondes',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'Carte actuelle: ${gameFlowService.currentCardIndex + 1}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  gameFlowService.nextCard();
                });
              },
              child: const Text('Carte suivante'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                gameFlowService.endGame();
                Navigator.pushNamed(context, '/result');
              },
              child: const Text('Terminer la partie'),
            ),
          ],
        ),
      ),
    );
  }
}
