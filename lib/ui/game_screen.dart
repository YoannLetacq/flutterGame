import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/helpers/realtime_db_helper.dart';
import 'package:untitled/models/game_model.dart';
import 'package:untitled/providers/game_state_provider.dart';
import 'package:untitled/services/abandon_service.dart';
import 'package:untitled/services/history_service.dart';
import 'package:untitled/ui/result_screen.dart';
import 'package:untitled/ui/widgets/animated_card_display.dart';
import 'package:untitled/ui/widgets/card_response_widget.dart';
import 'package:untitled/ui/widgets/disconnect_notif_widget.dart';
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
  // ────────────────────────────────── STATE ──────────────────────────────────
  bool _waitingTimerStarted         = false;

  bool _hasForceEnd                 = false;
  bool _hasFinished                 = false;

  bool _disconnectWorkflowActive    = false;      // nouveau
  // ────────────────────────────────────────────────────────────────────────────

  // ─────────────────────────────   INIT   ────────────────────────────────────
  @override
  void initState() {
    super.initState();
    final provider = context.read<GameStateProvider>();

    provider.gameFlowService.startGame(
      onTick      : provider.updateElapsedTime,
      onSpeedUp   : () => setState(() {}),            // simple refresh
      onForcedEnd : () {
        if (!_hasForceEnd && mounted) {
          _hasForceEnd = true;
          _onGameFinished();
        }
      },
      playerId: provider.gameFlowService.localPlayerId,
    );
  }

  // ─────────────────────────────   BUILD   ───────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p = context.watch<GameStateProvider>();

    // ── post‑frame pour les contrôles temps‑réel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runEndOfGameChecks(p);
      _handleOpponentConnectivity(p);
    });

    return WillPopScope(
      onWillPop: _confirmAbandon,
      child: Scaffold(
        appBar: _buildAppBar(),
        body  : _buildBody(p),
      ),
    );
  }

  // ─────────────────────────────  UI helpers  ────────────────────────────────
  PreferredSizeWidget _buildAppBar() => AppBar(
    title: Text('Game ${widget.game.id}'),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: _confirmAbandon,
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.flag),
        tooltip: 'Abandonner',
        onPressed: _confirmAbandon,
      ),
    ],
  );

  Widget _buildBody(GameStateProvider p) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: Text('Temps écoulé : ${p.elapsedTime}s',
            style: const TextStyle(fontSize: 18)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: PlayerProgressBarWidget(
                currentIndex: p.currentCardIndex,
                totalCards  : p.totalCards,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OpponentProgressBarWidget(
                currentIndex: p.opponentCardIndex,
                totalCards  : p.totalCards,
              ),
            ),
          ],
        ),
      ),
      Expanded(child: AnimatedCardDisplay(cardModel: p.currentCard)),
      CardResponseWidget(card: p.currentCard, onAnswer: p.submitResponse),
    ],
  );

  // ────────────────────────────  GAME FLOW  ──────────────────────────────────
  void _runEndOfGameChecks(GameStateProvider p) {
    if (_hasFinished) return;

    // L’adversaire vient de finir ou d’abandonner
    if (p.opponentStatus == 'finished' || p.opponentStatus == 'abandon') {
      _onGameFinished();
      return;
    }

    // Le joueur local a fini en 1ᵉʳ → start waiting 60 s
    final finishedLocal =
        p.currentCardIndex >= p.totalCards && p.playerStatus != 'waitingOpponent';
    if (finishedLocal && !_waitingTimerStarted) {
      _waitingTimerStarted = true;
      p.timerService.startWaitingTimer(_onGameFinished);
      _showWaitingDialog();
    }
  }

  // ───────────────────────────  CONNECTIVITY  ────────────────────────────────
  void _handleOpponentConnectivity(GameStateProvider p) {
    // ↘ déconnexion détectée
    if (p.opponentJustDisconnected && !_disconnectWorkflowActive) {
      _disconnectWorkflowActive = true;

      _showBanner(DisconnectNotifWidget.disconnect());

      // On démarre le timer de déconnexion
      p.timerService.startDisconnectTimer(_onGameFinished);
      _waitingTimerStarted = false;
      p.timerService.stopWaitingTimer();
    }
    if (p.opponentJustReconnected && _disconnectWorkflowActive) {
      _disconnectWorkflowActive = false;

      _showBanner(DisconnectNotifWidget.reconnect());

      // On stoppe le timer de déconnexion
      p.timerService.stopDisconnectTimer();
    }

  }

  // banner material
  void _showBanner(Widget content) {
    ScaffoldMessenger.of(context)
      ..clearMaterialBanners()
      ..showMaterialBanner(MaterialBanner(
        content : content,
        actions : [
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).clearMaterialBanners(),
            child: const Text('OK'),
          )
        ],
      ));
  }

  // ────────────────────────────  ABANDON  ────────────────────────────────────
  Future<bool> _confirmAbandon() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder : (_) => AlertDialog(
        title   : const Text('Quitter la partie ?'),
        content : const Text('Voulez‑vous vraiment quitter la partie en cours ?'),
        actions : [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Oui')),
        ],
      ),
    ) ??
        false;
    if (!mounted) return false;
    if (context.read<AbandonService>().isAbandonedByModal(confirm)) {
      _hasFinished = true;
      _finalizeMatch(isAbandon: true);
      return true;
    }
    return false;
  }

  // ───────────────────────────── FIN PARTIE ──────────────────────────────────
  void _onGameFinished() {
    if (_hasFinished || !mounted) return;
    _hasFinished = true;

    final t = context.read<GameStateProvider>().timerService;
    t.stopTimer();
    t.stopWaitingTimer();
    t.stopDisconnectTimer();

    _finalizeMatch(isAbandon: false);
  }

  Future<void> _finalizeMatch({required bool isAbandon}) async {
    final p       = context.read<GameStateProvider>();
    final history = context.read<HistoryService>();

    if (isAbandon) {
      await p.gameFlowService.updatePlayerStatus(
        p.gameFlowService.localPlayerId,
        'abandon',
      );
    }

    final ok = await p.gameFlowService.finalizeMatch(
      localScore       : p.score,
      opponentScore    : p.opponentScore,
      localPlayerId    : p.gameFlowService.localPlayerId,
      opponentPlayerId : p.gameFlowService.opponentPlayerId,
      wasRanked        : false,
      historyService   : history,
      isAbandon        : isAbandon,
    );

    if (!mounted) return;
    if (!ok) return Navigator.pop(context);

    // récupère gameResult pour l’écran résultat
    final snap = await RealtimeDBHelper
        .ref('games/${widget.game.id}/players/${p.gameFlowService.localPlayerId}')
        .child('gameResult')
        .get();

    final resultStr = snap.value as String?;
    if (!mounted) return;
    if (resultStr == null) return Navigator.pop(context);

    // Si l’adversaire a abandonné, on le marque comme déconnecté
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          playerWon     : resultStr == 'win',
          playerScore   : p.score,
          opponentScore : p.opponentScore,
          wasRanked     : false,
          opponentId    : p.gameFlowService.opponentPlayerId,
        ),
      ),
    );
  }

  // ─────────────────────────────  DIALOG UE  ─────────────────────────────────
  void _showWaitingDialog() => showDialog(
    barrierDismissible: false,
    context: context,
    builder: (_) => const AlertDialog(
      title   : Text('En attente…'),
      content : Text('Vous avez terminé vos cartes.\n'
          'En attente de l’adversaire (60 s) …'),
    ),
  );
}