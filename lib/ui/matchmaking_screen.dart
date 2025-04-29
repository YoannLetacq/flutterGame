import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/ui/login_screen.dart';
import '../../models/game_model.dart';
import '../../services/auth_service.dart';
import '../../services/matchmaking_service.dart';
import '../helpers/navigator_helper.dart';
import 'home_screen.dart';

/// Écran de matchmaking.
/// - Met en attente le joueur et affiche un indicateur de recherche de joueur.
/// - Lorsqu'un adversaire est trouvé, passe à l'écran de jeu correspondant en récupérant l'ID de la partie depuis Firebase Realtime Database.
class MatchmakingScreen extends StatefulWidget {
  final bool isRanked;

  const MatchmakingScreen({super.key, required this.isRanked});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  late final MatchmakingService matchmakingService;
  late final AuthService authService;

  @override
  void initState() {
    super.initState();
    matchmakingService = context.read<MatchmakingService>();
    authService = context.read<AuthService>();

    final user = authService.currentUser;
    if (user != null) {
      matchmakingService.startMatchMaking(
        user.uid,
        widget.isRanked ? GameMode.CLASSEE : GameMode.CLASSIQUE,
      );
    } else {
      // Si l'utilisateur n'est pas connecté, on le redirige vers l'écran de connexion
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    }
  }

  @override
  void dispose() {
    final user = authService.currentUser;
    if (user != null) {
      matchmakingService.stopMatchmaking();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchmakingService = Provider.of<MatchmakingService>(context);

    // Si une partie est trouvée, on y navigue
    if (matchmakingService.currentGame != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigateToGame(context, matchmakingService.currentGame!);
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: widget.isRanked ? const Text('Matchmaking classé') : const Text('Matchmaking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            await matchmakingService.stopMatchmaking();
            if (context.mounted) {
              // Retourne à l'écran précédent
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Center(
        child: matchmakingService.isWaiting
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("En attente d'un adversaire..."),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await matchmakingService.stopMatchmaking();
                if (context.mounted)  {
                  // navigue vers l'écran d'accueil
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
              },
              child: const Text('Annuler la recherche'),
            ),
          ],
        )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

