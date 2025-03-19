import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/ui/widgets/player_progress_bar_widget.dart';
import 'package:untitled/ui/widgets/opponent_progress_bar_widget.dart';

void main() {
  group('ProgressBarWidget Tests', () {
    testWidgets('PlayerProgressBarWidget displays avatar and animated progress bar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PlayerProgressBarWidget(
            progress: 0.6,
            // Utiliser une URL statique valide pour les tests.
            avatarUrl:  '/home/lychee/AndroidStudioProjects/untitled/ressources/user.png',
          ),
        ),
      ));

      // Vérifier que le CircleAvatar est présent.
      expect(find.byType(CircleAvatar), findsOneWidget);
      // Vérifier que le LinearProgressIndicator est présent.
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      // Laisser l'animation se terminer.
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('OpponentProgressBarWidget displays avatar and animated progress bar', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: OpponentProgressBarWidget(
            progress: 0.8,
            // Utiliser une URL statique valide pour les tests.
            avatarUrl: '/home/lychee/AndroidStudioProjects/untitled/ressources/user.png',
          ),
        ),
      ));

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
    });
  });
}
