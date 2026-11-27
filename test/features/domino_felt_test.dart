// Tapis plein écran (#659) : les mains et le tapis du Domino sont sur le feutre.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/domino/domino_screen.dart';
import 'package:kahwetne/core/theme/scoba_palette.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    '#659 : le feutre contient le tapis et les mains',
    (tester) async {
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
      expect(find.byKey(const ValueKey('domino-felt')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '#1024 : tapis en dégradé bleu comme Chkobba, scores dans les coins',
    (tester) async {
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
      final felt = find.byKey(const ValueKey('domino-felt'));
      expect(
        find.descendant(
          of: felt,
          matching: find.byWidgetPredicate(
            (w) =>
                w is DecoratedBox &&
                w.decoration == ScobaPalette.tapisPremiumDecoration,
          ),
        ),
        findsOneWidget,
      );
      // Score adversaire et score joueur, dans le tapis.
      expect(find.descendant(of: felt, matching: find.text('0')), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );
}
