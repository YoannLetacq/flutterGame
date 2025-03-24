import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/models/game_model.dart';
import 'package:untitled/providers/game_provider.dart';
import 'package:untitled/ui/result_screen.dart';
import 'package:untitled/ui/widgets/card_widget.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final String? gameId; // null si on crée une nouvelle partie, non-null si on rejoint.
  static const routeName = '/game';

  const GameScreen({super.key, this.mode = GameMode.CLASSIQUE, this.gameId});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameProvider _gameProvider;

  @override
  void initState() {
    super.initState();
    // Initialiser le provider après le build du contexte.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _gameProvider = context.read<GameProvider>();
      // Selon les paramètres, créer ou rejoindre la partie.
      if (widget.gameId != null) {
        _gameProvider.joinGame(widget.gameId!);
      } else {
        _gameProvider.createGame(widget.mode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jeu de Cartes'),
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, _) {
          // Si le jeu est en cours de chargement (création ou rejoindre en attente)
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          // Si la partie est terminée, naviguer vers l'écran de résultat.
          if (provider.isGameEnded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ResultScreen()
              ));
            });
          }
          // Si en mode classé et l'adversaire n'est pas encore là, afficher attente.
          if (provider.game != null && provider.game!.mode == GameMode.CLASSEE && provider.game!.players.length < 2) {
            return const Center(
              child: Text(
                'En attente d’un adversaire...',
                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              ),
            );
          }
          // Affichage principal de la partie.
          if (provider.game == null || provider.cards.isEmpty) {
            // Aucun jeu initialisé (cas d'erreur éventuel).
            return const Center(child: Text('Aucune partie en cours'));
          }
          // Récupérer la carte courante à afficher.
          final currentIndex = provider.currentCardIndex;
          final currentCard = provider.cards[currentIndex];
          final totalCards = provider.cards.length;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Informations en-tête: score, progression, chronomètre.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Score: ${provider.score}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Question ${currentIndex + 1}/$totalCards',
                        style: const TextStyle(fontSize: 16)),
                    Text(_formatTime(provider.elapsedTime),
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 20),
                // Zone de la carte/question avec animation de transition.
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) {
                      // Détermine la direction de l'animation selon si c'est une nouvelle carte.
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation);
                      return SlideTransition(position: offsetAnimation, child: child);
                    },
                    child: CardWidget(
                      key: ValueKey(currentCard.id), // clé unique pour AnimatedSwitcher
                      card: currentCard,
                      onAnswerSelected: (answer) {
                        provider.submitAnswer(answer);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Formate le temps écoulé (en secondes) en mm:ss.
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final sec = seconds % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = sec.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }
}
