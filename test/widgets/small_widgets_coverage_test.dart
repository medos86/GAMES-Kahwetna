import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/comic/comic_pill.dart';
import 'package:kahwetne/widgets/difficulty_chip.dart';

// Petits widgets partagés par les écrans de jeu (#167 : couverture).
void main() {
  testWidgets('pastille de niveau : libellé de chaque niveau', (tester) async {
    for (final option in difficultyOptions) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DifficultyChip(difficulty: option.difficulty),
          ),
        ),
      );
      expect(find.text(option.label), findsOneWidget);
    }
  });

  testWidgets('bouton BD : libellé visible et appui', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ComicPill(
            label: 'Menu',
            icon: Icons.arrow_back,
            onTap: () => taps++,
          ),
        ),
      ),
    );
    expect(find.text('Menu'), findsOneWidget);
    await tester.tap(find.text('Menu'));
    expect(taps, 1);
  });
}
