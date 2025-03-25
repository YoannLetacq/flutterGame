import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/ui/widgets/animated_card_display.dart';
import 'package:untitled/ui/widgets/card_response_widget.dart';
import 'package:untitled/ui/widgets/opponent_progress_bar_widget.dart';
import 'package:untitled/ui/widgets/player_progress_bar_widget.dart';
import '../../models/game_model.dart';
import '../../services/game_flow_service.dart';
import '../../services/timer_service.dart';
import '../../services/game_progress_service.dart';
import '../../services/abandon_service.dart';
import '../../services/elo_service.dart';
import 'result_screen.dart';

/// Écran principal de la partie.
/// - Affiche la carte courante, la progression de chaque joueur et le timer de la partie.
/// - Gère la logique de fin de partie : fin automatique quand les deux joueurs ont fini leurs cartes, ou abandon.
/// - Intègre l'animation latérale de changement de carte via [AnimatedCardDisplay].
class GameScreen extends StatefulWidget {
  final GameModel game;
  const GameScreen({super.key, required this.game});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameFlowService _gameFlow;
  late String _playerId;
  late String _opponentId;
  int _elapsedTime = 0;

  @override
  void initState() {
    super.initState();
    // Suppose that the first player in the map is the local player (in a real scenario, identify via Auth)
    _playerId = widget.game.players.keys.first;
    _opponentId = widget.game.players.keys.last;
    // Initialize GameFlowService with necessary services from providers
    final timerService = Provider.of<TimerService>(context, listen: false);
    final progressService = Provider.of<GameProgressService>(context, listen: false);
    final abandonService = Provider.of<AbandonService>(context, listen: false);
    final eloService = Provider.of<EloService>(context, listen: false);
    final gameRef = FirebaseDatabase.instance.ref('games/${widget.game.id}');
    _gameFlow = GameFlowService(
      timerService: timerService,
      progressService: progressService,
      abandonService: abandonService,
      eloService: eloService,
      game: widget.game,
      gameRef: gameRef,
    );
    // Start the game timer and logic
    _gameFlow.startGame(
      playerId: _playerId,
      onTick: (seconds) {
        setState(() => _elapsedTime = seconds);
      },
      onSpeedUp: () {
        // Activate speed-up mode after 5 minutes
        if (kDebugMode) {
          print('Mode speed-up activé (5 minutes écoulées)');
        }


      },
    );
    // Écoute l'état global du jeu pour détecter la fin de partie (deux joueurs finis)
    _gameFlow.listenGameState().listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && mounted) {
        final playersData = data['players'] as Map?;
        if (playersData != null) {
          final statusPlayer = playersData[_playerId]['status'];
          final statusOpponent = playersData[_opponentId]['status'];
          if (statusPlayer == 'finished' && statusOpponent == 'finished') {
            // Les deux joueurs ont terminé leurs cartes -> fin de partie
            _onGameFinished();
          } else if (statusPlayer == 'finished' && statusOpponent == 'abandon') {
            // L'adversaire a abandonné -> victoire du joueur courant
            _onGameFinished(abandonWin: true);
          } else if (statusPlayer == 'abandon' && statusOpponent == 'finished') {
            // Le joueur courant a abandonné -> défaite
            _onGameFinished(abandonWin: false);
          }
        }
      }
    });
  }

  void _onGameFinished({bool? abandonWin}) {
    // Arrête le GameFlow et passe à l'écran de résultats
    _gameFlow.endGame(_playerId);
    // Détermine le résultat pour l'écran des scores
    bool playerWon;
    if (abandonWin != null) {
      playerWon = abandonWin; // victoire ou défaite suite à un abandon
    } else {
      // Comparer les scores si pas d'abandon
      final playerScore = widget.game.players[_playerId]?.score ?? 0;
      final opponentScore = widget.game.players[_opponentId]?.score ?? 0;
      playerWon = playerScore >= opponentScore;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          playerWon: playerWon,
          playerScore: widget.game.players[_playerId]?.score ?? 0,
          opponentScore: widget.game.players[_opponentId]?.score ?? 0,
          wasRanked: widget.game.mode == GameMode.CLASSEE,
          opponentId: _opponentId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Arrête le timer si l'écran se ferme (par précaution)
    if (!_gameFlow.isGameEnded) {
      _gameFlow.timerService.stopTimer();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCardId = widget.game.cards.isNotEmpty
        ? widget.game.cards[_gameFlow.currentCardIndex]
        : null;
    return Scaffold(
      appBar: AppBar(
        title: Text('Game ${widget.game.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            tooltip: 'Abandonner',
            onPressed: () {
              // Le joueur abandonne volontairement la partie
              _gameFlow.gameRef.child('players').child(_playerId).update({'status': 'abandon'});
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Timer display
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Temps écoulé: $_elapsedTime sec',
              style: const TextStyle(fontSize: 18),
            ),
          ),
          // Progress bars for both players
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(child: PlayerProgressBarWidget(currentIndex: _gameFlow.currentCardIndex, totalCards: widget.game.cards.length)),
                const SizedBox(width: 10),
                Expanded(child: OpponentProgressBarWidget(currentIndex: widget.game.players[_opponentId]?.currentCardIndex ?? 0, totalCards: widget.game.cards.length)),
              ],
            ),
          ),
          // Current card display with lateral slide animation
          Expanded(
            child: AnimatedCardDisplay(cardId: currentCardId),
          ),
          // Zone de réponse du joueur (ex: boutons ou champ texte), via un widget dédié:
          CardResponseWidget(
            cardId: currentCardId,
            onAnswer: (String answer) {
              // Traitement de la réponse du joueur (vérification via ResponseService, mise à jour du score)
              // Incrémente la progression si réponse donnée
              setState(() {
                _gameFlow.currentCardIndex = _gameFlow.progressService.incrementCardIndex(_gameFlow.currentCardIndex, widget.game.cards.length);
              });
              // Met à jour l'état du joueur en DB (nouvel index, score éventuel)
              _gameFlow.updatePlayerState(_playerId);
            },
          ),
        ],
      ),
    );
  }
}
