import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/ui/widgets/card_response_widget.dart';

void main() {
  group('CardResponseWidget Tests', () {
    testWidgets('Displays TextField and button for complement type', (WidgetTester tester) async {
      String submittedResponse = "";
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CardResponseWidget(
            cardType: 'complement',
            onSubmit: (response) {
              submittedResponse = response;
            },
            questionText: 'Mot-clé: Agile',
          ),
        ),
      ));

      // Vérifier que le mot-clé est affiché.
      expect(find.text('Mot-clé: Agile'), findsOneWidget);
      // Vérifier que le TextField et le bouton "Valider" sont affichés.
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text("Valider"), findsOneWidget);

      // Saisir du texte et simuler le tap sur le bouton.
      await tester.enterText(find.byType(TextField), 'ma réponse');
      await tester.tap(find.text("Valider"));
      await tester.pumpAndSettle();

      expect(submittedResponse, equals('ma réponse'));
    });

    testWidgets('Displays definition widget with header, question text and options', (WidgetTester tester) async {
      String submittedResponse = "";
      final options = ['Option 1', 'Option 2', 'Option 3'];
      const questionText = 'Quelle est la bonne définition de Flutter ?';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CardResponseWidget(
            cardType: 'definition',
            options: options,
            onSubmit: (response) {
              submittedResponse = response;
            },
            questionText: questionText,
          ),
        ),
      ));

      // Vérifier que la question est affichée en haut.
      expect(find.text(questionText), findsOneWidget);
      // Vérifier que le texte d'instruction est affiché en petit italique.
      expect(find.text('Choisissez la bonne réponse'), findsOneWidget);
      // Vérifier que chaque option est affichée dans une colonne.
      for (final option in options) {
        expect(find.text(option), findsOneWidget);
      }

      // Simuler le tap sur "Option 2".
      await tester.tap(find.text('Option 2'));
      await tester.pumpAndSettle();
      expect(submittedResponse, equals('Option 2'));
    });
  });
}
