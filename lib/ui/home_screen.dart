import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_profile_service.dart';
import '../providers/game_state_provider.dart';
import '../services/matchmaking_service.dart';
import 'learning_screen.dart';
import 'login_screen.dart';
import 'matchmaking_screen.dart';

/// Écran d'accueil (après connexion).
/// - Affiche les informations de profil du joueur (nom, avatar, Elo).
/// - Propose de lancer une partie classée ou classique.
/// - Permet de se déconnecter.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex = 0; // 0 = home, 1 =learning

  @override
  void initState() {
    super.initState();
    // purge des etat matchmaking et game apres retour home
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchmakingService>().clear();
      final gameState = Provider.of<GameStateProvider?>(context, listen: false);
      gameState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfile =
    context.read<UserProfileService>().getUserProfile(); // pas besoin d’écoute
    final authService = context.read<AuthService>();

    final String userName = userProfile['displayName'] ?? 'Joueur';
    final String elo      = userProfile['elo'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Bienvenue, $userName' : 'Récapitulatif des notions'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await authService.signOut();
              if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                );
            },
          ),
        ],
      ),

      // ----- Corps : IndexedStack pour conserver l’état de chaque onglet -----
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeBody(context, userProfile, userName, elo), // index 0
          const LearningScreen(),                              // index 1
        ],
      ),

      // ----- Barre de navigation -----
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home),      label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Notions'),
        ],
      ),
    );
  }

  /// Contenu de l’onglet Accueil (UI historique)
  Widget _buildHomeBody(BuildContext context, Map<String, dynamic> profile,
      String userName, String elo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (profile['avatarUrl']!.isNotEmpty)
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(profile['avatarUrl']!),
            ),
          const SizedBox(height: 10),
          Text(userName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          if (elo.isNotEmpty)
            Text('Elo : $elo',
                style: TextStyle(fontSize: 18, color: Colors.grey[700])),
          const SizedBox(height: 30),

          // ---------- Boutons de lancement de parties ----------
          ElevatedButton(
            child: const Text('Jouer – Partie Classique'),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                  const MatchmakingScreen(isRanked: false),
                  transitionsBuilder: (_, anim, __, child) => SlideTransition(
                    position: Tween<Offset>(
                        begin: const Offset(1, 0), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                ),
              );
            },
          ),
          ElevatedButton(
            child: const Text('Jouer – Partie Classée'),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                  const MatchmakingScreen(isRanked: true),
                  transitionsBuilder: (_, anim, __, child) => SlideTransition(
                    position: Tween<Offset>(
                        begin: const Offset(1, 0), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
