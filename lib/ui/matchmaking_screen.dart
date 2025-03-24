import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/services/matchmaking_service.dart';
import 'package:untitled/services/auth_service.dart';
import 'package:untitled/services/user_profile_service.dart';

import 'game_screen.dart';

/// Écran de matchmaking : recherche et association d'un adversaire.
/// Il affiche un indicateur de chargement pendant la recherche.
class MatchmakingScreen extends StatefulWidget {
  static const routeName = '/matchmaking';

  const MatchmakingScreen({super.key});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  bool _isSearching = false;
  String? _statusMessage;

  @override
  void initState() {
    if (mounted) {
      _startMatchmaking();
    }
    super.initState();
  }

  Future<void> _startMatchmaking() async {
    setState(() {
      _isSearching = true;
      _statusMessage = "Recherche d’un adversaire…";
    });
    try {
      // Récupérer les services nécessaires.
      final matchmakingService = Provider.of<MatchmakingService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final userProfileService = Provider.of<UserProfileService>(context, listen: false);
      final user = authService.currentUser;
      if (user == null) {
        setState(() {
          _statusMessage = "Utilisateur non authentifié.";
          _isSearching = false;
        });
        return;
      }
      // Récupérer le classement Elo depuis le profil.
      final profile = userProfileService.getUserProfile();
      final userElo = int.tryParse(profile['elo'] ?? '1500') ?? 1500;

      // Déterminer si la partie doit être classée à partir des arguments.
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
      final bool ranked = args['ranked'] ?? false;

      // Appeler la méthode de matchmaking.
      final gameId = await matchmakingService.findMatch(user.uid, userElo);
      // Une fois le match trouvé, naviguer vers l'écran de jeu.
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          GameScreen.routeName,
          arguments: {
            'gameId': gameId,
            'ranked': ranked,
          },
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Erreur lors du matchmaking : $e";
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matchmaking'),
        backgroundColor: const Color(0xFF0F0D7B),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0D7B), Color(0xFF282EAA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: _isSearching
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFC9905)),
              const SizedBox(height: 16),
              Text(
                _statusMessage ?? 'Recherche…',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _statusMessage ?? "Matchmaking terminé.",
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFC9905),
                ),
                onPressed: _startMatchmaking,
                child: const Text('Recommencer la recherche'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
