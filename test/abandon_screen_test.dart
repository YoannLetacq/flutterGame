import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/ui/abandon_screen.dart';

void main() {
  testWidgets('AbandonScreen displays abandonment message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AbandonScreen(),
      ),
    );
    expect(find.text('Votre adversaire a abandonné'), findsOneWidget);
  });
}
