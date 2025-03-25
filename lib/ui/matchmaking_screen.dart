import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_model.dart';
import '../../services/auth_service.dart';
import '../../services/matchmaking_service.dart';
import 'game_screen.dart';

/// Écran de matchmaking.
/// - Met en attente le joueur et affiche un indicateur de recherche de joueur.
/// - Lorsqu'un adversaire est trouvé, passe à l'écran de jeu correspondant en récupérant l'ID de la partie depuis Firebase Realtime Database.
class MatchmakingScreen extends StatefulWidget {
  final bool isRanked;
  const MatchmakingScreen({super.key, required this.isRanked});

  @override
  _MatchmakingScreenState createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  String? _statusMessage;
  StreamSubscription<DatabaseEvent>? _matchSub;

  @override
  void initState() {
    super.initState();
    // Démarre la recherche de match dès que l'écran est affiché.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMatchmaking());
  }

  @override
  void dispose() {
    _matchSub?.cancel();
    super.dispose();
  }

  Future<void> _startMatchmaking() async {
    final matchmakingService = Provider.of<MatchmakingService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) {
      setState(() {
        _statusMessage = "Erreur : utilisateur non authentifié.";
      });
      return;
    }
    final String userId = user.uid;
    setState(() => _statusMessage = "Recherche d'un joueur...");

    GameMode mode = widget.isRanked ? GameMode.CLASSEE : GameMode.CLASSIQUE;
    // Appel du matchmaking via le service
    GameModel? game = await matchmakingService.findMatch(userId, mode);
    if (game != null) {
      _navigateToGame(game);
    } else {
      // Aucun match immédiat : mettre en place un listener sur le noeud d'attente pour détecter une modification.
      final String modeKey = widget.isRanked ? 'ranked' : 'casual';
      final DatabaseReference waitingRef = FirebaseDatabase.instance.ref('matchmaking/$modeKey/waiting');
      _matchSub = waitingRef.onValue.listen((event) async {
        final data = event.snapshot.value;
        // Si la valeur est différente de l'uid actuel, on considère qu'un match est trouvé.
        if (data != null && data is String && data != userId) {
          final String gameId = data;
          // On peut récupérer ici la partie complète si nécessaire.
          // Pour cet exemple, nous créons un GameModel minimal.
          GameModel matchedGame = GameModel(
            id: gameId,
            cards: [], // Charger la liste de cartes via CardService dans une version complète.
            mode: mode,
            players: {}, // Les informations des joueurs devront être chargées depuis la DB.
          );
          // Annuler l'abonnement avant de naviguer.
          await _matchSub?.cancel();
          _navigateToGame(matchedGame);
        }
      });
    }
  }

  void _navigateToGame(GameModel game) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(game: game)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRanked ? 'Matchmaking Classé' : 'Matchmaking Classique'),
      ),
      body: Center(
        child: _statusMessage == null
            ? const CircularProgressIndicator()
            : Text(
          _statusMessage!,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
