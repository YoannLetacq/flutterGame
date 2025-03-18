import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled/firebase_options.dart';
import 'package:untitled/main.dart';

Future<void> main() async {
  // Initialiser l'environnement d'intégration
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialiser Firebase avant de lancer l'application.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  group('End-to-End Full User Flow Test', () {
    testWidgets('Full flow from Login to Home Screen', (WidgetTester tester) async {
      // Lancer l'application
      await tester.pumpWidget(const Zone01GameApp());

      // Vérifier que l'écran de connexion s'affiche (texte "Connectez-vous avec Google").
      expect(find.text('Connectez-vous avec Google'), findsOneWidget);

      // Simuler le tap sur le bouton de connexion.
      await tester.tap(find.text('Se connecter avec Google'));
      await tester.pumpAndSettle();

      // Vérifier que l'écran d'accueil s'affiche, avec un message de bienvenue.
      expect(find.textContaining('Bienvenue'), findsOneWidget);
    });
  });
}
