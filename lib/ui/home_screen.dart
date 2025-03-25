import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';
import 'login_screen.dart';
import 'matchmaking_screen.dart';

/// Écran d'accueil (après connexion).
/// - Affiche les informations de profil du joueur (nom, avatar, Elo).
/// - Propose de lancer une partie classée ou classique.
/// - Permet de se déconnecter.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfileService>(context, listen: false).getUserProfile();
    final authService = Provider.of<AuthService>(context, listen: false);
    final userName = userProfile['displayName'] ?? 'Joueur';
    final elo = userProfile['elo'] ?? ''; // 'elo' n'est pas renvoyé par getUserProfile (on pourrait le récupérer via Firestore)

    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenue, $userName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await authService.signOut();
              // Retour au LoginScreen après déconnexion
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            tooltip: 'Se déconnecter',
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (userProfile['avatarUrl']!.isNotEmpty)
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(userProfile['avatarUrl']!),
              ),
            const SizedBox(height: 10),
            Text(
              userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (elo != '')
              Text(
                'Elo : $elo',
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
            const SizedBox(height: 30),
            ElevatedButton(
              child: const Text('Jouer - Partie Classique'),
              onPressed: () {
                // Démarre la recherche d'une partie classique
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const MatchmakingScreen(isRanked: false),
                    transitionsBuilder: (_, anim, __, child) => SlideTransition(
                      position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                );
              },
            ),
            ElevatedButton(
              child: const Text('Jouer - Partie Classée'),
              onPressed: () {
                // Démarre la recherche d'une partie classée
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const MatchmakingScreen(isRanked: true),
                    transitionsBuilder: (_, anim, __, child) => SlideTransition(
                      position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
