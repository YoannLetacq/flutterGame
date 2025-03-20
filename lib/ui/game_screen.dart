import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:untitled/models/card_model.dart';
import 'package:untitled/services/card_service.dart';
import 'package:untitled/services/game_flow_service.dart';
import 'package:untitled/services/response_service.dart';
import 'package:untitled/ui/widgets/animated_card_display.dart';
import 'package:untitled/ui/widgets/card_response_widget.dart';
import 'package:untitled/ui/widgets/player_progress_bar_widget.dart';
import 'package:untitled/ui/widgets/opponent_progress_bar_widget.dart';

import '../models/game_model.dart';
import '../models/player_model.dart';
import '../services/abandon_service.dart';
import '../services/elo_service.dart';
import '../services/game_progress_service.dart';
import '../services/timer_service.dart';


class GameScreen extends StatefulWidget {
  static const routeName = '/game';
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final CardService _cardService = CardService();
  final ResponseService _responseService = ResponseService();
  late GameFlowService gameFlowService;

  List<CardModel> cards = [];
  int currentIndex = 0;
  bool isLoading = true;
  int score = 0;

  // Valeurs de progression exprimées entre 0 et 1.
  double userProgress = 0.0;
  double opponentProgress = 0.0;

  CardModel? get currentCard =>
      (cards.isNotEmpty && currentIndex < cards.length) ? cards[currentIndex] : null;

  @override
  void initState() {
    super.initState();

    // Récupérer l'utilisateur connecté via FirebaseAuth.
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }

    // Charger les cartes depuis Firestore via _loadCards().
    _loadCards().then((_) {
      // Une fois les cartes chargées, générer un identifiant unique pour la partie.
      final String gameId = FirebaseDatabase.instance.ref().child('games').push().key!;

      // Créer une instance de PlayerModel pour le joueur local.
      final player = PlayerModel(
        id: currentUser.uid,
        cardsOrder: [], // Cette liste sera remplie ultérieurement par la logique de répartition.
        currentCardIndex: 0,
        score: 0,
        status: 'in game',
        winner: null,
      );

      // Construire le GameModel en utilisant l'ID généré, la liste des IDs de cartes et les données du joueur.
      final GameModel gameModel = GameModel(
        id: gameId,
        cards: cards.map((card) => card.id).toList(),
        mode: GameMode.CLASSIQUE, // On utilise le mode classique pour le moment.
        players: { currentUser.uid: player },
      );

      // Créer la référence de la partie dans Firebase Realtime Database sous "games/{gameId}".
      final DatabaseReference gameRef =
      FirebaseDatabase.instance.ref().child('games').child(gameId);

      // Initialiser GameFlowService avec TimerService, GameProgressService, AbandonService, EloService, le modèle et la référence.
      gameFlowService = GameFlowService(
        timerService: TimerService(),
        progressService: GameProgressService(),
        abandonService: AbandonService(),
        eloService: EloService(),
        game: gameModel,
        gameRef: gameRef,
      );

      // Démarrer le match : démarrez le timer et enregistrez l'état initial du joueur dans la DB.
      gameFlowService.startGame(
        onTick: (elapsedSeconds) {
          if (kDebugMode) {
            print("Temps écoulé : $elapsedSeconds secondes");
          }
        },
        onSpeedUp: () {
          if (kDebugMode) {
            print("Mode speed-up activé !");
          }
        },
        playerId: currentUser.uid,
      );

      // Mettre en place un listener pour synchroniser la progression de l'adversaire.
      gameFlowService.listenGameState().listen((DatabaseEvent event) {
        final data = event.snapshot.value as Map?;
        if (data != null && data.containsKey('players')) {
          final playersData = data['players'] as Map;
          // Supposons que l'adversaire ait l'ID 'player2'
          if (playersData.containsKey('player2')) {
            final opponentData = playersData['player2'] as Map;
            int opponentIndex = opponentData['currentCardIndex'] ?? 0;
            setState(() {
              opponentProgress = (opponentIndex / gameModel.cards.length).clamp(0.0, 1.0);
            });
          }
        }
      });
    });
  }


  /// Modification de _loadCards pour retourner un Future complet
  Future<void> _loadCards() async {
    try {
      final fetchedCards = await _cardService.fetchCards();
      if (mounted) {
        setState(() {
          cards = fetchedCards;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      // Gérer l'erreur (afficher un message, etc.)
    }
  }





  void _handleResponse(String userResponse) {
    if (currentCard == null) return;
    bool isCorrect = _responseService.evaluateResponse(userResponse, currentCard!.answer);
    if (isCorrect) {
      setState(() {
        score += 10; // Ajout de points pour une bonne réponse.
        userProgress = ((currentIndex + 1) / cards.length).clamp(0.0, 1.0);
      });
    } else {
      // Aucune notification en cas de mauvaise réponse.
    }
    setState(() {
      opponentProgress = ((currentIndex + 1) / cards.length).clamp(0.0, 1.0);
    });
    // Passer à la carte suivante après un délai.
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          currentIndex++;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // On simule un background cohérent avec la page de connexion (dégradé du rose vers le mauve).
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFAA88FF), Color(0xFF6655EE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : currentCard == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Fin des cartes !',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Score final : $score',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          // HUD en haut
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Column(
              children: [
                PlayerProgressBarWidget(
                  progress: userProgress,
                  avatarUrl: 'assets/images/user.png',
                ),
                const SizedBox(height: 16),
                OpponentProgressBarWidget(
                  progress: opponentProgress,
                  avatarUrl: 'assets/images/opponent.png',
                ),
              ],
            ),
          ),
          // Zone centrale : affichage de la carte avec animation
          Center(
            child: AnimatedCardDisplay(
              cardKey: ValueKey(currentCard!.id),
              child: Container(
                key: ValueKey(currentCard!.id),
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: currentCard!.type == 'definition'
                    ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Nom de la carte en haut
                    Text(
                      currentCard!.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Explanation scrollable
                    Container(
                      height: 100,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          currentCard!.explanation.isNotEmpty
                              ? currentCard!.explanation
                              : "Pas d'explication disponible",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                )
                    : // Cartes "complement" : mot-clé en haut
                Text(
                  currentCard!.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Zone de réponse en bas
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: CardResponseWidget(
              cardType: currentCard!.type,
              options: currentCard!.type == 'definition'
                  ? currentCard!.options
                  : null,
              onSubmit: _handleResponse,
              questionText: currentCard!.type == 'complement'
                  ? currentCard!.name
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
