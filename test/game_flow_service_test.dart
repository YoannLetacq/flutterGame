import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/models/game_model.dart';
import 'package:untitled/services/timer_service.dart';
import 'package:untitled/services/game_progress_service.dart';
import 'package:untitled/services/abandon_service.dart';
import 'package:untitled/services/elo_service.dart';
import 'package:untitled/services/game_flow_service.dart';

void main() {
  group('GameFlowService Tests', () {
    late TimerService timerService;
    late GameProgressService progressService;
    late AbandonService abandonService;
    late EloService eloService;
    late GameModel game;
    late GameFlowService gameFlowService;

    setUp(() {
      timerService = TimerService();
      progressService = GameProgressService();
      abandonService = AbandonService();
      eloService = EloService();
      game = GameModel(
        id: 'gameFlow1',
        cards: ['card1', 'card2', 'card3', 'card4', 'card5'],
        mode: GameMode.CLASSEE, // ou CLASSIQUE selon le contexte
        players: {},
      );
      gameFlowService = GameFlowService(
        timerService: timerService,
        progressService: progressService,
        abandonService: abandonService,
        eloService: eloService,
        game: game,
      );
    });

    test('Progression through cards', () {
      expect(gameFlowService.currentCardIndex, equals(0));
      gameFlowService.nextCard();
      expect(gameFlowService.currentCardIndex, equals(1));
      gameFlowService.nextCard();
      expect(gameFlowService.currentCardIndex, equals(2));
      gameFlowService.nextCard();
      gameFlowService.nextCard();
      // Avec 5 cartes, le dernier index est 4.
      expect(gameFlowService.currentCardIndex, equals(4));
      // Un appel supplémentaire ne doit pas dépasser.
      gameFlowService.nextCard();
      expect(gameFlowService.currentCardIndex, equals(4));
    });

    test('Calculate ranking change', () {
      double delta = gameFlowService.calculateRankingChange(
        playerRating: 1000,
        opponentRating: 1000,
        score: 1.0,
        kFactor: 60,
      );
      expect(delta, closeTo(30.0, 0.1));
    });

    test('End game stops timer and sets isGameEnded', () {
      // Démarrer le chronomètre pour vérifier qu'il est actif
      gameFlowService.startGame(
        onTick: (_) {},
        onSpeedUp: () {},
      );
      gameFlowService.endGame();
      expect(gameFlowService.isGameEnded, isTrue);
    });

    // tests pour checkAbandon
    test('checkAbandon returns none when conditions are normal', () {
      final now = DateTime.now();
      final result = gameFlowService.checkAbandon(
        lastActive: now,
        lastConnected: now,
        modalConfirmed: false,
        timeout: const Duration(minutes: 1),
      );
      expect(result, equals(AbandonType.none));
    });

    test('checkAbandon returns modal when modalConfirmed is true', () {
      final now = DateTime.now();
      final result = gameFlowService.checkAbandon(
        lastActive: now,
        lastConnected: now,
        modalConfirmed: true,
        timeout: const Duration(minutes: 1),
      );
      expect(result, equals(AbandonType.modal));
    });

    test('checkAbandon returns inactive when lastActive is too old', () {
      final now = DateTime.now();
      final lastActive = now.subtract(const Duration(minutes: 2)); // inactivité dépassée
      final result = gameFlowService.checkAbandon(
        lastActive: lastActive,
        lastConnected: now, // connexion récente
        modalConfirmed: false,
        timeout: const Duration(minutes: 1),
      );
      expect(result, equals(AbandonType.inactive));
    });

    test('checkAbandon returns disconnect when lastConnected is too old', () {
      final now = DateTime.now();
      final lastConnected = now.subtract(const Duration(minutes: 2)); // déconnexion dépassée
      final result = gameFlowService.checkAbandon(
        lastActive: now, // activité récente
        lastConnected: lastConnected,
        modalConfirmed: false,
        timeout: const Duration(minutes: 1),
      );
      expect(result, equals(AbandonType.disconnect));
    });
  });
}
