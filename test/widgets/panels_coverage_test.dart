import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/result_dialog.dart';
import 'package:kahwetne/widgets/texture_patterns.dart';
import 'package:kahwetne/widgets/trophy_badge.dart';

// Fenêtre de résultat, motifs de fond et trophée du score cible (#167 : couverture).
void main() {
  testWidgets('fenêtre de résultat dans chaque style', (tester) async {
    for (final style in ResultDialogStyle.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultDialog(
              style: style,
              title: 'Bravo',
              icon: Icons.emoji_events,
              children: const [Text('Contenu')],
              actions: [
                TextButton(onPressed: () {}, child: const Text('OK')),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Bravo'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    }
  });

  testWidgets('motifs de points et de rayures', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(
                width: 120,
                height: 60,
                child: DotPattern(spacing: 12, radius: 2, color: Colors.white),
              ),
              SizedBox(
                width: 120,
                height: 60,
                child: StripePattern(
                  period: 10,
                  width: 4,
                  color: Colors.white,
                  vertical: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(DotPattern), findsOneWidget);
    expect(find.byType(StripePattern), findsOneWidget);
  });

  testWidgets('trophée avec le score cible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TrophyBadge(target: 11)),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('11'), findsOneWidget);
  });
}
