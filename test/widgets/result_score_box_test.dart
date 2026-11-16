import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/result_dialog.dart';

/// Issue #295 : cartes de score du récapitulatif (variation signée, motif, total).
void main() {
  test('variation signée : +100, -10, 0', () {
    expect(signedScore(100), '+100');
    expect(signedScore(-10), '-10');
    expect(signedScore(0), '0');
  });

  testWidgets('ResultScoreBox affiche nom, variation, motif et total', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResultScoreBox(
            name: 'Toi',
            value: '-10',
            total: '90',
            reason: 'Gagnant',
            highlight: true,
          ),
        ),
      ),
    );
    expect(find.text('TOI'), findsOneWidget);
    expect(find.text('-10'), findsOneWidget);
    expect(find.text('Gagnant'), findsOneWidget);
    expect(find.text('Total 90'), findsOneWidget);
  });
}
