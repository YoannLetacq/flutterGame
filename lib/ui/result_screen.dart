import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/ranking_service.dart';
import '../../services/history_service.dart';
import 'home_screen.dart';

/// Écran de résultats de la partie.
///
/// Affiche le score final et indique le gagnant.
/// Comprend un compteur de score animé qui se met à jour jusqu'au score final.
/// Si la partie était classée, calcule l'Elo gagné/perdu et met à jour le classement dans Firestore.
///
/// Dépendances : RankingService et HistoryService (via Provider) pour le calcul de l'Elo et l'enregistrement de l'historique.
/// AuthService est utilisé pour récupérer l'UID du joueur actuel.
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

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<int> _scoreAnimation;
  int _displayedScore = 0;

  @override
  void initState() {
    super.initState();
    // Animation du compteur de score de 0 jusqu'au score du joueur
    _animController = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _scoreAnimation = IntTween(begin: 0, end: widget.playerScore).animate(_animController)
      ..addListener(() {
        setState(() {
          _displayedScore = _scoreAnimation.value;
        });
      });
    _animController.forward();

    // Si la partie était classée, mettre à jour l'Elo et enregistrer l'historique
    if (widget.wasRanked) {
      // Récupérer l'UID du joueur courant via AuthService
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      if (user != null) {
        final String userId = user.uid;
        final rankingService = Provider.of<RankingService>(context, listen: false);
        final historyService = Provider.of<HistoryService>(context, listen: false);
        double playerResultScore = widget.playerWon ? 1.0 : 0.0;
        double opponentResultScore = widget.playerWon ? 0.0 : 1.0;
        // Met à jour le classement Elo des deux joueurs dans Firestore.
        rankingService.updateEloAfterGame(
          playerId: userId,
          opponentId: widget.opponentId,
          playerScore: playerResultScore,
          opponentScore: opponentResultScore,
        );
        // Enregistre l'historique de la partie pour l'utilisateur courant.
        historyService.recordGameHistory(userId, {
          'date': DateTime.now(),
          'score': widget.playerScore,
          'opponentScore': widget.opponentScore,
          'result': widget.playerWon ? 'win' : 'loss',
          'mode': 'ranked',
        });
      } else {
        if (kDebugMode) {
          print("Aucun utilisateur connecté. Impossible de mettre à jour le classement Elo.");
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
    String resultText = widget.playerWon ? 'Victoire !' : 'Défaite';
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
