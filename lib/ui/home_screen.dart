import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/providers/connectivity_provider.dart';
import 'login_screen.dart';
import 'matchmaking_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityResults = Provider.of<ConnectivityProvider>(context).connectivityResults;
    String connectivityText = 'Aucun résultat';
    if (connectivityResults.isNotEmpty) {
      connectivityText = connectivityResults.first.toString().replaceAll('ConnectivityResult.', '');
    }
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email ?? 'Utilisateur';

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
            Text(
              'État de connexion: $connectivityText',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, MatchmakingScreen.routeName);
              },
              child: const Text('Lancer le jeu'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, LoginScreen.routeName);
              },
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}
