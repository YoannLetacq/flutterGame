import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/ui/game_screen.dart';

void main() {
  testWidgets('GameScreen displays timer, current card and buttons, and navigates on end game', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const GameScreen(),
      routes: {
        '/result': (context) => const Scaffold(body: Center(child: Text('Result Screen'))),
      },
    ));

    // Vérifier que l'AppBar affiche "Game Screen".
    expect(find.text('Game Screen'), findsOneWidget);

    // Vérifier que le texte du chronomètre et de la carte actuelle sont présents.
    expect(find.textContaining('Temps écoulé:'), findsOneWidget);
    expect(find.textContaining('Carte actuelle:'), findsOneWidget);

    // Vérifier que les boutons sont présents.
    expect(find.text('Carte suivante'), findsOneWidget);
    expect(find.text('Terminer la partie'), findsOneWidget);

    // Vérifier la progression des cartes
    // On s'attend à ce que l'index initial soit 1
    expect(find.text('Carte actuelle: 1'), findsOneWidget);
    // Simuler un tap sur le bouton "Carte suivante"
    await tester.tap(find.text('Carte suivante'));
    await tester.pump();
    // Après le tap, l'index devrait être incrémenté à 2
    expect(find.text('Carte actuelle: 2'), findsOneWidget);

    // Simuler la fin de la partie en tapant sur "Terminer la partie"
    await tester.tap(find.text('Terminer la partie'));
    await tester.pumpAndSettle();

    // Vérifier que la navigation vers le Result Screen s'effectue
    expect(find.text('Result Screen'), findsOneWidget);
  });
}
