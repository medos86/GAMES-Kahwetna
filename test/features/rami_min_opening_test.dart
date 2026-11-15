import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #318 : le minimum d'ouverture (51 points) est affiché en haut de Rami.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Rami : le minimum d\'ouverture 51 est affiché en haut', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
      ),
    );
    await tester.pump();

    expect(find.textContaining('51'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
