// Domino (#1040) : plus de bouton « Piocher » ; la pioche est en bas et cliquable.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/i18n/app_language.dart';
import 'package:kahwetne/features/domino/domino_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/pressable.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('#1040 : bouton Piocher supprimé, pioche cliquable en bas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: DominoScreen(difficulty: Difficulty.facile, targetScore: 50),
      ),
    );
    await tester.pump();

    expect(find.text(t('pickUp')), findsNothing);
    // La pioche (compteur + libellé) reste visible, sous forme cliquable.
    expect(find.text(t('draw')), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text(t('draw')),
        matching: find.byType(Pressable),
      ),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });
}
