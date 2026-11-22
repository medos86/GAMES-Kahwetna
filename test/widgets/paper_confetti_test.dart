import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/paper_confetti.dart';
import 'package:kahwetne/widgets/result_dialog.dart';

/// Issue #773 : animation de papiers jetés à la victoire.
void main() {
  test('buildPaperPieces : déterministe', () {
    final a = buildPaperPieces(40, 7);
    final b = buildPaperPieces(40, 7);
    expect(a.length, 40);
    expect(a.map((p) => p.x).toList(), b.map((p) => p.x).toList());
    expect(a.map((p) => p.color).toList(), b.map((p) => p.color).toList());
  });

  test('buildPaperPieces : valeurs dans les bornes prévues', () {
    for (final p in buildPaperPieces(200, 773)) {
      expect(p.x, inInclusiveRange(0, 1));
      expect(p.delay, inInclusiveRange(0, 0.3));
      expect(p.spin, inInclusiveRange(1, 4));
      expect(p.drift, inInclusiveRange(-0.1, 0.1));
      expect(p.width, inInclusiveRange(6, 12));
      expect(p.height, inInclusiveRange(10, 18));
    }
  });

  testWidgets('PaperConfetti : ne bloque pas les touchers', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Stack(children: [PaperConfetti()])),
      ),
    );
    final ignore = find.descendant(
      of: find.byType(PaperConfetti),
      matching: find.byType(IgnorePointer),
    );
    expect(ignore, findsWidgets);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  });

  testWidgets('PaperConfetti : se termine après sa durée', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PaperConfetti(duration: Duration(milliseconds: 500)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('ResultDialog : sans confettis par défaut', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ResultDialog(title: 'Perdu')),
      ),
    );
    expect(find.byType(PaperConfetti), findsNothing);
  });

  testWidgets('ResultDialog : celebrate affiche les papiers', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResultDialog(title: 'Victoire', celebrate: true),
        ),
      ),
    );
    expect(find.byType(PaperConfetti), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
