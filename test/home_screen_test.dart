import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/ui/home_screen.dart';
import 'package:untitled/main.dart';

void main() {
  testWidgets('HomeScreen displays welcome text and login button', (WidgetTester tester) async {
    await tester.pumpWidget(const Zone01GameApp());

    // Vérifier que le texte de bienvenue est affiché.
    expect(find.text('Bienvenue sur Zone01 Game!'), findsOneWidget);

    // Vérifier que le bouton "Se connecter" est présent.
    expect(find.text('Se connecter'), findsOneWidget);
  });
}
