import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:untitled/constants/app_constants.dart';
import 'package:untitled/models/card_model.dart';
import 'package:untitled/models/game_model.dart';
import 'package:untitled/models/player_model.dart';
import 'package:untitled/services/abandon_service.dart';
import 'package:untitled/services/card_service.dart';
import 'package:untitled/services/elo_service.dart';
import 'package:untitled/services/game_flow_service.dart';
import 'package:untitled/services/game_progress_service.dart';
import 'package:untitled/services/game_service.dart';
import 'package:untitled/services/timer_service.dart';

class GameProvider extends ChangeNotifier {
  final GameService _gameService;
  final CardService _cardService;
  final String playerId;
  final FirebaseDatabase _database;

  GameModel? game;
  List<CardModel> cards = [];
  int currentCardIndex = 0;
  int score = 0;
  bool isLoading = false;
  bool isGameEnded = false;
  int elapsedTime = 0; // en secondes
  GameFlowService? _gameFlow;

  GameProvider({
    required GameService gameService,
    required CardService cardService,
    required this.playerId,
    FirebaseDatabase? database,
  })  : _gameService = gameService,
        _cardService = cardService,
        _database = database ?? FirebaseDatabase.instance;

  /// Crée une nouvelle partie en mode [mode] (CLASSIQUE ou CLASSEE) et initialise le jeu.
  /// Cette méthode récupère des cartes, crée l'objet GameModel et sauvegarde la partie.
  Future<void> createGame(GameMode mode) async {
    isLoading = true;
    notifyListeners();
    try {
      // 1. Récupérer toutes les cartes disponibles et en sélectionner un sous-ensemble pour la partie.
      List<CardModel> allCards = await _cardService.fetchCards();
      // Pour la partie, on sélectionne 5 cartes aléatoirement (ou moins si pas assez).
      allCards.shuffle(Random());
      cards = allCards.take(5).toList();
      // Extraire les IDs des cartes sélectionnées.
      List<String> cardIds = cards.map((c) => c.id).toList();

      // 2. Créer le GameModel initial.
      String gameId = _generateGameId();
      Map<String, PlayerModel> players = {};
      // Initialiser le joueur créateur.
      players[playerId] = PlayerModel(
        id: playerId,
        cardsOrder: cardIds,
        currentCardIndex: 0,
        score: 0,
        status: mode == GameMode.CLASSEE ? GameStatus.waitingOpponent : GameStatus.inGame,
        winner: null,
      );
      game = GameModel(id: gameId, cards: cardIds, mode: mode, players: players);

      // 3. Enregistrer la partie dans la base (Realtime Database via GameService).
      await _gameService.createGame(game!);

      // 4. Préparer le GameFlowService avec la référence de la partie en DB.
      DatabaseReference gameRef = _database.ref('${DBPaths.games}/$gameId');
      _gameFlow = GameFlowService(
        timerService: TimerService(),
        progressService: GameProgressService(),
        abandonService: AbandonService(),
        eloService: EloService(),
        game: game!,
        gameRef: gameRef,
      );

      // Si mode classique, démarrer la partie immédiatement.
      // Si mode classé, on attendra un adversaire avant de démarrer (status "waitingOpponent").
      if (mode == GameMode.CLASSIQUE) {
        _startGameFlow();
      }
      // Si CLASSEE, le jeu démarrera quand un second joueur rejoindra.
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Rejoint une partie existante identifiée par [gameId], en tant que deuxième joueur.
  Future<void> joinGame(String gameId) async {
    isLoading = true;
    notifyListeners();
    try {
      // 1. Récupérer la partie existante.
      GameModel? existingGame = await _gameService.getGame(gameId);
      if (existingGame == null) {
        throw Exception("Partie $gameId introuvable");
      }
      game = existingGame;
      // Récupérer la liste des cartes de la partie.
      List<String> cardIds = game!.cards;
      // Charger les détails des cartes depuis Firestore.
      List<CardModel> allCards = await _cardService.fetchCards();
      // Filtrer les cartes pour ne garder que celles de la partie.
      cards = allCards.where((c) => cardIds.contains(c.id)).toList();

      // 2. Ajouter le nouveau joueur dans la structure de la partie.
      game!.players[playerId] = PlayerModel(
        id: playerId,
        cardsOrder: cardIds,
        currentCardIndex: 0,
        score: 0,
        status: GameStatus.inGame, // le joueur qui rejoint est prêt à jouer
        winner: null,
      );
      // Identifier l'hôte existant (premier joueur).
      String hostId = game!.players.keys.firstWhere((id) => id != playerId, orElse: () => playerId);
      // Mettre à jour le statut de l'hôte en "in game" si nécessaire (la partie démarre).
      if (game!.players[hostId] != null) {
        game!.players[hostId] = game!.players[hostId]!.copyWith(status: GameStatus.inGame);
      }

      // 3. Mettre à jour la partie en base de données pour ajouter le joueur.
      await _gameService.updateGame(gameId, {
        // On met à jour le sous-arbre players avec le nouveau joueur.
        '${DBPaths.players}/$playerId': game!.players[playerId]!.toJson(),
        // Mettre à jour aussi le statut de l'hôte si on l'a modifié.
        if (game!.players[hostId] != null) '${DBPaths.players}/$hostId/status': GameStatus.inGame,
      });

      // 4. Initialiser GameFlowService avec la référence DB de la partie et démarrer le jeu.
      DatabaseReference gameRef = _database.ref('${DBPaths.games}/$gameId');
      _gameFlow = GameFlowService(
        timerService: TimerService(),
        progressService: GameProgressService(),
        abandonService: AbandonService(),
        eloService: EloService(),
        game: game!,
        gameRef: gameRef,
      );
      // Démarrer le chronomètre et la partie pour le joueur qui rejoint.
      _startGameFlow();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Lance le GameFlow (chronomètre, etc.) une fois les joueurs prêts.
  void _startGameFlow() {
    if (_gameFlow == null || game == null) return;
    // Réinitialiser les indicateurs locaux.
    isGameEnded = false;
    currentCardIndex = 0;
    score = 0;
    elapsedTime = 0;
    // Démarrer le chronomètre de jeu.
    _gameFlow!.startGame(
      onTick: (seconds) {
        elapsedTime = seconds;
        notifyListeners();
      },
      onSpeedUp: () {
        // Par exemple, on pourrait notifier l'UI que le temps est écoulé (>5min) et accélérer le jeu.
        // (Ici, on ne change rien à l'UI, mais on pourrait envisager de réduire le temps accordé pour répondre, etc.)
      },
      playerId: playerId,
    );
  }

  /// Soumet la réponse [answer] pour la carte courante.
  /// Gère la mise à jour du score, le passage à la carte suivante avec animation, et la fin de partie.
  void submitAnswer(String answer) {
    if (game == null || _gameFlow == null || currentCardIndex >= cards.length) return;
    bool isCorrect = (answer == cards[currentCardIndex].answer);
    // Mettre à jour le score si la réponse est correcte.
    if (isCorrect) {
      score += 1;
      // Mettre à jour le score en DB pour ce joueur.
      _gameFlow!.gameRef.child(DBPaths.players).child(playerId).update({'score': score});
    }
    // Mémoriser l'index avant progression.
    int oldIndex = currentCardIndex;
    // Passer à la carte suivante (met à jour currentCardIndex via GameFlowService).
    _gameFlow!.nextCard(playerId);
    currentCardIndex = _gameFlow!.currentCardIndex;
    // Si l'index n'a pas changé, c'est que c'était la dernière carte.
    if (currentCardIndex == oldIndex) {
      isGameEnded = true;
      // Arrêter le jeu pour ce joueur.
      _gameFlow!.endGame(playerId);
      // Si mode classé, on pourrait calculer le résultat Elo ici en utilisant _gameFlow.calculateRankingChange()
      // et éventuellement enregistrer le nouveau classement en base (non implémenté ici).
    }
    notifyListeners();
  }

  /// Génère un identifiant unique de partie (par ex., via timestamp ou aléatoire).
  String _generateGameId() {
    // Pour simplicité, on utilise un timestamp Unix combiné à un nombre aléatoire.
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random().nextInt(9999).toString().padLeft(4, '0');
    return 'game_${timestamp}_$random';
  }
}
