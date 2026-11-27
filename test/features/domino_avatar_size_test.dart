// Domino (#1039) : l'avatar adversaire a la même taille que celui du joueur.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/domino/domino_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/turn_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('#1039 : avatar adversaire aussi grand que le mien', (
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

    final avatars = find.byType(TurnAvatar);
    expect(avatars, findsNWidgets(2));
    final opponent = tester.getSize(avatars.at(0));
    final player = tester.getSize(avatars.at(1));
    expect(opponent.width, closeTo(player.width, 0.5));
    expect(opponent.height, closeTo(player.height, 0.5));
    expect(tester.takeException(), isNull);
  });
}
