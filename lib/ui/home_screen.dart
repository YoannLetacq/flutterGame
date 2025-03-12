import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled/services/auth_service.dart';
import 'login_screen.dart';
import 'matchmaking_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la déconnexion')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayName = _user?.displayName ?? _user?.email ?? 'Utilisateur';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zone01 Game - Accueil'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Bienvenue, $displayName',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Lancer le jeu, par exemple rediriger vers le matchmaking
                Navigator.pushNamed(context, MatchmakingScreen.routeName);
              },
              child: const Text('Lancer le jeu'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleSignOut,
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}
