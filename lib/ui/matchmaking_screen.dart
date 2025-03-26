import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_model.dart';
import '../../services/auth_service.dart';
import '../../services/matchmaking_service.dart';
import 'game_screen.dart';

/// Écran de matchmaking.
/// - Met en attente le joueur et affiche un indicateur de recherche de joueur.
/// - Lorsqu'un adversaire est trouvé, passe à l'écran de jeu correspondant en récupérant l'ID de la partie depuis Firebase Realtime Database.
class MatchmakingScreen extends StatelessWidget {
  final bool isRanked;

  const MatchmakingScreen({super.key, required this.isRanked});


  @override
  Widget build(BuildContext context) {
    final MatchmakingService matchmakingService = Provider.of<MatchmakingService>(context);
    final user = Provider.of<AuthService>(context).currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Matchmaking')),
        body: const Center(child: Text('Erreur: Pas authentifie'),),
      );
    }

    // Lance la recherche d'une partie
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!matchmakingService.isWaiting && matchmakingService.currentGame == null) {
        matchmakingService.startMatchMaking(user.uid, isRanked ? GameMode.CLASSEE : GameMode.CLASSIQUE);
      }
    });

    // Si la partie est trouvew, on passe à l'écran de jeu
    if (matchmakingService.currentGame != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
       context,
        MaterialPageRoute(
          builder: (_) => GameScreen(game: matchmakingService.currentGame!),
        ),
      );
    });
      return const SizedBox.shrink();
    }
    return Scaffold(
      appBar: AppBar(title: isRanked ? const Text('Matchmaking classé') : const Text('Matchmaking')),
      body: Center(
        child: matchmakingService.isWaiting ?
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("En attente d'un adversaire..."),
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                ElevatedButton(onPressed:
                () {
        // Stop le matchmaking
        matchmakingService.stopMatchmaking(user.uid,
        isRanked ? GameMode.CLASSEE : GameMode.CLASSIQUE);
    Navigator.pop(context);
  },
    child: const Text('Annuler la recherche'),
    ),
                ],
              ) :
            const CircularProgressIndicator(),
      ),
    );
  }
}
