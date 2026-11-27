// Domino (#1042) : avatar et score du joueur gardent leur place, pour agrandir le tapis.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/domino/domino_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/turn_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('#1042 : tapis plus haut que la moitié de l\'écran', (
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

    final felt = tester.getSize(find.byKey(const ValueKey('domino-felt')));
    final table = tester.getSize(find.byKey(const ValueKey('domino-table')));
    expect(table.height, greaterThan(felt.height * 0.4));
    expect(find.byType(TurnAvatar), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
