import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/difficulty_chip.dart';

// La pastille de niveau ne déborde pas quand la place est réduite (#340).
void main() {
  for (final scale in [1.0, 1.3, 2.0]) {
    testWidgets('pastille dans 90 px, texte x$scale : pas de dépassement', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 90,
                  child: DifficultyChip(difficulty: Difficulty.facile),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
