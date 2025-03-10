import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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
        cards: ['card1', 'card2', 'card3'],
        mode: GameMode.CLASSIQUE, // ou CLASSEE selon le contexte
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
      // À la fin, nextCard ne doit pas dépasser le dernier index.
      gameFlowService.nextCard();
      expect(gameFlowService.currentCardIndex, equals(2));
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
  });
}
