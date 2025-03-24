import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/services/user_profile_service.dart';
import 'package:untitled/services/auth_service.dart';
import 'package:untitled/ui/widgets/game_history_modal.dart';

import 'login_screen.dart';
import 'matchmaking_screen.dart';

/// Écran d'accueil affiché après l'authentification.
class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfileService = Provider.of<UserProfileService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    Map<String, String> profile;
    try {
      profile = userProfileService.getUserProfile();
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, LoginScreen.routeName);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final avatarUrl = profile['avatarUrl'] ?? '';
    final displayName = profile['displayName']!.isNotEmpty
        ? profile['displayName']!
        : (profile['email']!.isNotEmpty ? profile['email']! : 'Utilisateur');
    final eloRating = profile.containsKey('elo') && profile['elo']!.isNotEmpty
        ? profile['elo']!
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zone01 Game - Accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique des parties',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                isScrollControlled: true,
                builder: (ctx) => const GameHistoryModal(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, LoginScreen.routeName);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 40)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                displayName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Classement Elo : $eloRating',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    MatchmakingScreen.routeName,
                    arguments: {'ranked': false},
                  );
                },
                child: const Text('Jouer Partie Classique'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    MatchmakingScreen.routeName,
                    arguments: {'ranked': true},
                  );
                },
                child: const Text('Jouer Partie Classée'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
