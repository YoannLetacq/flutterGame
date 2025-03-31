import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/ranking_service.dart';
import '../../services/history_service.dart';
import 'home_screen.dart';

/// Écran de résultats de la partie.
///
/// - Affiche le score final, la victoire ou la défaite.
/// - Anime le compteur de score jusqu’au score final.
/// - Si la partie était classée (wasRanked), met à jour le classement Elo via [RankingService],
///   et enregistre l'historique via [HistoryService].
class ResultScreen extends StatefulWidget {
  final bool playerWon;
  final int playerScore;
  final int opponentScore;
  final bool wasRanked;
  final String opponentId;

  const ResultScreen({
    super.key,
    required this.playerWon,
    required this.playerScore,
    required this.opponentScore,
    required this.wasRanked,
    required this.opponentId,
  });

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<int> _scoreAnimation;
  int _displayedScore = 0;

  @override
  void initState() {
    super.initState();
    // Animation du score du joueur local
    _animController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scoreAnimation =
    IntTween(begin: 0, end: widget.playerScore).animate(_animController)
      ..addListener(() {
        setState(() {
          _displayedScore = _scoreAnimation.value;
        });
      });
    _animController.forward();

    // Gestion du ranking/historique si partie classée
    if (widget.wasRanked) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user != null) {
        final userId = user.uid;
        final rankingService = Provider.of<RankingService>(context, listen: false);
        final historyService = Provider.of<HistoryService>(context, listen: false);

        // Dans la logique Elo, 1.0 = victoire, 0.0 = défaite
        final playerEloScore = widget.playerWon ? 1.0 : 0.0;
        final opponentEloScore = widget.playerWon ? 0.0 : 1.0;

        // Met à jour le classement du joueur local + adversaire
        rankingService.updateEloAfterGame(
          playerId: userId,
          opponentId: widget.opponentId,
          playerScore: playerEloScore,
          opponentScore: opponentEloScore,
        );

        // Enregistre l'historique de la partie pour le joueur local
        historyService.recordGameHistory(userId, {
          'date': DateTime.now(),
          'score': widget.playerScore,
          'opponentScore': widget.opponentScore,
          'result': widget.playerWon ? 'win' : 'loss',
          'mode': 'ranked',
        });
      } else {
        if (kDebugMode) {
          print("Aucun utilisateur connecté -> impossible de mettre à jour l'Elo.");
        }
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultText = widget.playerWon ? 'Victoire !' : 'Défaite';
    return Scaffold(
      appBar: AppBar(title: const Text('Résultat')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              resultText,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Votre score : $_displayedScore',
              style: const TextStyle(fontSize: 24),
            ),
            Text(
              'Score adversaire : ${widget.opponentScore}',
              style: const TextStyle(fontSize: 24),
            ),
            if (widget.wasRanked)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  "Classement Elo mis à jour",
                  style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                ),
              ),
            ElevatedButton(
              child: const Text('Retour à l\'accueil'),
              onPressed: () {
                // Retour forcé à l'écran Home
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
