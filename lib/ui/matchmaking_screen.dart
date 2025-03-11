import 'package:flutter/material.dart';

class MatchmakingScreen extends StatelessWidget {
  static const routeName = '/matchmaking';

  const MatchmakingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche d\'adversaire'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Recherche en cours...',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Simuler le démarrage du jeu (navigation vers GameScreen)
                Navigator.pushNamed(context, '/game');
              },
              child: const Text('Simuler le démarrage du jeu'),
            ),
          ],
        ),
      ),
    );
  }
}
