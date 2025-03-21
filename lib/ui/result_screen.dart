import 'package:flutter/material.dart';

/// Écran de résultat affiché après la fin d'une partie.
class ResultScreen extends StatelessWidget {
  static const routeName = '/result';

  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupération des paramètres transmis via la navigation.
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    final int playerScore = args?['score'] ?? 0;
    final int durationSeconds = args?['duration'] ?? 0;
    final int? eloChange = args != null && args.containsKey('eloChange')
        ? args['eloChange'] as int?
        : null;
    bool isVictory;
    if (args != null && args.containsKey('isVictory')) {
      isVictory = args['isVictory'] as bool;
    } else if (args != null && args.containsKey('result')) {
      final resultStr = (args['result'] as String).toLowerCase();
      isVictory = resultStr.contains('vic') || resultStr.contains('win');
    } else {
      isVictory = false;
    }

    final duration = Duration(seconds: durationSeconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    String formattedTime;
    if (minutes > 0) {
      formattedTime = '${minutes}m ${seconds}s';
    } else {
      formattedTime = '${seconds}s';
    }

    final resultColor = isVictory ? Colors.green : Colors.red;
    final resultText = isVictory ? 'Victoire !' : 'Défaite';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultat de la partie'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Indicateur visuel de résultat
              Icon(
                isVictory ? Icons.emoji_events : Icons.cancel,
                size: 60,
                color: isVictory ? Colors.amber : Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                resultText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: resultColor,
                ),
              ),
              const SizedBox(height: 24),
              // Score avec animation (compteur animé)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Score : ',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: playerScore.toDouble()),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Text(
                        value.toInt().toString(),
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Temps écoulé
              Text(
                'Temps écoulé : $formattedTime',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              // Affichage de l'évolution Elo (pour partie classée)
              if (eloChange != null) ...[
                Text(
                  'Évolution Elo : ${(eloChange > 0 ? '+' : '')}$eloChange',
                  style: TextStyle(
                    fontSize: 16,
                    color: eloChange > 0
                        ? Colors.green
                        : (eloChange < 0 ? Colors.red : Colors.grey[700]),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: const Text("Retour à l'accueil"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
