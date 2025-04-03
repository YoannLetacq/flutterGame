import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled/services/auth_service.dart';

import '../models/game_model.dart';
import '../providers/game_state_provider.dart';
import '../services/abandon_service.dart';
import '../services/elo_service.dart';
import '../services/game_flow_service.dart';
import '../services/game_progress_service.dart';
import '../services/response_service.dart';
import '../services/timer_service.dart';
import '../ui/game_screen.dart';

/// Fonction utilitaire pour lancer correctement la GameScreen avec son provider
void navigateToGame(BuildContext context, GameModel game) {
  final userId = context.read<AuthService>().currentUser?.uid;
  if (userId == null) {
    throw Exception('User ID is null. Cannot navigate to game screen.');
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider(
        create: (_) => GameStateProvider(
          gameFlowService: GameFlowService(
            timerService: context.read<TimerService>(),
            progressService: context.read<GameProgressService>(),
            abandonService: context.read<AbandonService>(),
            eloService: context.read<EloService>(),
            game: game,
            gameRef: FirebaseDatabase.instance.ref('games/${game.id}'),
            userId: userId,
          ),
          responseService: ResponseService(),
          timerService: context.read<TimerService>(),
          gameProgressService: context.read<GameProgressService>(),
          cards: game.cards,
        ),
        child: GameScreen(game: game),
      ),
    ),
  );
}
