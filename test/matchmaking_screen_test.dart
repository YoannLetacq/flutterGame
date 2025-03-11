import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/ui/matchmaking_screen.dart';

void main() {
  testWidgets('MatchmakingScreen displays progress indicator, text and button', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: MatchmakingScreen()));

    // Vérifier que l'indicateur de progression est présent.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Vérifier que le texte "Recherche en cours..." est affiché.
    expect(find.text('Recherche en cours...'), findsOneWidget);
    // Vérifier que le bouton est présent.
    expect(find.text('Simuler le démarrage du jeu'), findsOneWidget);
  });

  testWidgets('MatchmakingScreen navigates to GameScreen on button tap', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      routes: {
        '/game': (context) => const Scaffold(body: Center(child: Text('Game Screen'))),
      },
      home: const MatchmakingScreen(),
    ));

    // Simuler le tap sur le bouton.
    await tester.tap(find.text('Simuler le démarrage du jeu'));
    await tester.pumpAndSettle();

    // Vérifier que l'écran de jeu (Game Screen) s'affiche.
    expect(find.text('Game Screen'), findsOneWidget);
  });
}
