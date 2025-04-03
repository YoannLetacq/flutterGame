import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/models/game_model.dart';
import 'package:untitled/providers/game_state_provider.dart';
import 'package:untitled/services/abandon_service.dart';
import 'package:untitled/services/history_service.dart';
import 'package:untitled/ui/result_screen.dart';
import 'package:untitled/ui/widgets/animated_card_display.dart';
import 'package:untitled/ui/widgets/card_response_widget.dart';
import 'package:untitled/ui/widgets/opponent_progress_bar_widget.dart';
import 'package:untitled/ui/widgets/player_progress_bar_widget.dart';

/// Écran principal de la partie.
/// - Gère le chronomètre (5min + speed-up 1min), l'abandon, et la fin de partie.
/// - Toute la logique de fin (mise à jour DB, enregistrement historique) est déléguée à [GameFlowService.finalizeMatch].
/// - À la fin, on navigue vers un [ResultScreen].
class GameScreen extends StatefulWidget {
  final GameModel game;

  const GameScreen({super.key, required this.game});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _showWaitingModal = false;
  bool _forceEndTriggered = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<GameStateProvider>();

    // Démarre le timer + maj DB init
    provider.gameFlowService.startGame(
      onTick: (sec) => provider.updateElapsedTime(sec),
      onSpeedUp: () {
        // Appelé après 5 minutes
        if (mounted) {
          setState(() {
            // On pourrait afficher "Mode speed-up activé" ou autre.
          });
        }
      },
      onForcedEnd: () {
        // Appelé après 6 minutes
        if (!_forceEndTriggered && mounted) {
          _forceEndTriggered = true;
          _onGameFinished();
        }
      },
      playerId: provider.gameFlowService.localPlayerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameStateProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Vérifie si le joueur local a terminé ses cartes
      _checkWaitingConditions();
    });

    return WillPopScope(
      onWillPop: _onWillPop, // Intercepter le bouton "retour" hardware
      child: Scaffold(
        appBar: AppBar(
          title: Text('Game ${widget.game.id}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _confirmAbandon(), // Evenement "retour" flèche AppBar
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.flag),
              tooltip: 'Abandonner',
              onPressed: () => _confirmAbandon(), // Evenement "Abandon"
            ),
          ],
        ),
        body: Column(
          children: [
            // Timer
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Temps écoulé : ${provider.elapsedTime} sec',
                style: const TextStyle(fontSize: 18),
              ),
            ),

            // Barre de progression (joueur local + adversaire)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: PlayerProgressBarWidget(
                      currentIndex: provider.currentCardIndex,
                      totalCards: provider.totalCards,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OpponentProgressBarWidget(
                      currentIndex: provider.opponentCardIndex,
                      totalCards: provider.totalCards,
                    ),
                  ),
                ],
              ),
            ),

            // Carte courante (animation latérale)
            Expanded(
              child: AnimatedCardDisplay(cardModel: provider.currentCard),
            ),

            // Zone de réponse : on renvoie l'index de l'option choisie au provider
            CardResponseWidget(
              card: provider.currentCard,
              onAnswer: (chosenIndex) => provider.submitResponse(chosenIndex),
            ),
          ],
        ),
      ),
    );
  }

  /// Intercepte le retour hardware
  Future<bool> _onWillPop() async {
    return _confirmAbandon(); // Même logique que la flèche AppBar
  }

  /// Demande confirmation d'abandon
  Future<bool> _confirmAbandon() async {
    final abandonService = context.read<AbandonService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter la partie ?'),
        content: const Text('Voulez-vous vraiment quitter la partie en cours ?'),
        actions: [
          TextButton(
            child: const Text('Non'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          TextButton(
            child: const Text('Oui'),
            onPressed: () => Navigator.pop(ctx, true),

          ),
        ],
      ),
    ) ?? false;

    if (abandonService.isAbandonedByModal(confirm)) {
      // Abandon confirmé => on traite la fin de partie côté service.
      _finalizeMatch(isAbandon: true);
      return true;
    } else {
      return false;
    }
  }

  void _checkWaitingConditions() {
    if (!mounted || _showWaitingModal) return;
    if (context.read<GameStateProvider>().currentCardIndex >=
        context.read<GameStateProvider>().totalCards) {
      setState(() {
        _showWaitingModal = true;
      });
      _showWaitingDialog();
    }
  }


  /// Appelé quand on dépasse 6 minutes (timer expiré) OU si les deux joueurs ont fini
  /// OU en cas d'abandon => On finalise la partie
  void _onGameFinished() {
    _finalizeMatch(isAbandon: false);
  }

  /// Méthode commune pour finaliser la partie (abandon ou fin de timer)
  void _finalizeMatch({required bool isAbandon}) async {
    final provider = context.read<GameStateProvider>();
    final historyService = context.read<HistoryService>();

    // Mettre éventuellement local status = "abandon" si isAbandon
    if (isAbandon) {
      await provider.gameFlowService.updatePlayerStatus(
        provider.gameFlowService.localPlayerId,
        'abandon',
      );
    }

    // Récupération score local / adversaire
    final localScore = provider.score;
    final opponentScore = _fetchOpponentScore(); // ex. depuis widget.game

    // On appelle finalizeMatch dans GameFlowService
    final success = await provider.gameFlowService.finalizeMatch(
      localScore: localScore,
      opponentScore: opponentScore,
      localPlayerId: provider.gameFlowService.localPlayerId,
      opponentPlayerId: provider.gameFlowService.opponentPlayerId,
      wasRanked: false,            // ou true si partie classée
      historyService: historyService,
    );

    if (!mounted) return;
    if (success) {
      // On détermine si le joueur local a gagné
      final playerWon = localScore > opponentScore;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            playerWon: playerWon,
            playerScore: localScore,
            opponentScore: opponentScore,
            wasRanked: false,
            opponentId: provider.gameFlowService.opponentPlayerId,
          ),
        ),
      );
    } else {
      // En cas d'erreur, on peut afficher un message
      Navigator.pop(context);
    }
  }

  /// Exemple pour récupérer le score adverse (selon ta logique DB)
  int _fetchOpponentScore() {
    final oppId = context.read<GameStateProvider>().gameFlowService.opponentPlayerId;
    final oppPlayer = widget.game.players[oppId];
    return oppPlayer?.score ?? 0;
  }

  /// Simple modal d'attente pour le joueur qui a fini avant l'adversaire
  void _showWaitingDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) => const AlertDialog(
        title: Text('En attente...'),
        content: Text('Vous avez terminé vos cartes. En attente de l\'adversaire...'),
        actions: [],
      ),
    );
  }
}
