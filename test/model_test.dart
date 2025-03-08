import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/models/game_model.dart';
import 'package:untitled/models/player_model.dart';
import 'package:untitled/models/card_model.dart';
import 'package:untitled/models/game_state_model.dart';

void main() {
  group('PlayerModel', () {
    test('serialization/deserialization', () {
      final player = PlayerModel(
        id: 'player1',
        cardsOrder: ['card1', 'card2'],
        currentCardIndex: 1,
        score: 10,
        status: 'in game',
        winner: null,
      );

      final json = player.toJson();
      final playerFromJson = PlayerModel.fromJson(json);

      expect(playerFromJson.id, equals(player.id));
      expect(playerFromJson.cardsOrder, equals(player.cardsOrder));
      expect(playerFromJson.currentCardIndex, equals(player.currentCardIndex));
      expect(playerFromJson.score, equals(player.score));
      expect(playerFromJson.status, equals(player.status));
      expect(playerFromJson.winner, equals(player.winner));
    });
  });

  group('CardModel', () {
    test('serialization/deserialization', () {
      final card = CardModel(
        id: 'card1',
        name: 'Scrum',
        type: 'complement',
        definition: 'Definition text',
        options: ['option1', 'option2', 'option3'],
        hints: ['hint1', 'hint2'],
        answer: 'option2',
        imageUrl: '',
        explanation: 'Some explanation',
      );

      final json = card.toJson();
      final cardFromJson = CardModel.fromJson(json);

      expect(cardFromJson.id, equals(card.id));
      expect(cardFromJson.name, equals(card.name));
      expect(cardFromJson.type, equals(card.type));
      expect(cardFromJson.definition, equals(card.definition));
      expect(cardFromJson.options, equals(card.options));
      expect(cardFromJson.hints, equals(card.hints));
      expect(cardFromJson.answer, equals(card.answer));
      expect(cardFromJson.imageUrl, equals(card.imageUrl));
      expect(cardFromJson.explanation, equals(card.explanation));
    });
  });

  group('GameStateModel', () {
    test('serialization/deserialization', () {
      final startTime = DateTime.now();
      final finishTime = startTime.add(const Duration(minutes: 5));
      final gameState = GameStateModel(
        state: 'in game',
        startTime: startTime,
        finishTime: finishTime,
      );

      final json = gameState.toJson();
      final gameStateFromJson = GameStateModel.fromJson(json);

      expect(gameStateFromJson.state, equals(gameState.state));
      expect(gameStateFromJson.startTime.toIso8601String(), equals(gameState.startTime.toIso8601String()));
      expect(gameStateFromJson.finishTime?.toIso8601String(), equals(gameState.finishTime?.toIso8601String()));
    });
  });

  group('GameModel', () {
    test('serialization/deserialization', () {
      final player1 = PlayerModel(
        id: 'player1',
        cardsOrder: ['card1', 'card2'],
        currentCardIndex: 1,
        score: 10,
        status: 'in game',
        winner: null,
      );

      final player2 = PlayerModel(
        id: 'player2',
        cardsOrder: ['card3', 'card4'],
        currentCardIndex: 0,
        score: 15,
        status: 'finished',
        winner: 'player2',
      );

      final game = GameModel(
        id: 'game1',
        cards: ['card1', 'card2', 'card3', 'card4'],
        mode: GameMode.CLASSEE,
        players: {
          player1.id: player1,
          player2.id: player2,
        },
      );

      final json = game.toJson();
      final gameFromJson = GameModel.fromJson(json);

      expect(gameFromJson.id, equals(game.id));
      expect(gameFromJson.cards, equals(game.cards));
      expect(gameFromJson.mode, equals(game.mode));
      expect(gameFromJson.players.length, equals(2));
      expect(gameFromJson.players['player1']?.id, equals(player1.id));
      expect(gameFromJson.players['player2']?.id, equals(player2.id));
    });
  });
}
