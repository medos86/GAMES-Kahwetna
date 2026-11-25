import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/comic_palette.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #952 : quand c'est mon tour, le tapis ne reçoit pas de contour jaune.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Rami : le contour du tapis reste encre, jamais doré (#952)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
      ),
    );
    await tester.pump();

    final tableBorders = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.borderRadius == BorderRadius.circular(22))
        .map((d) => d.border)
        .whereType<Border>()
        .toList();

    expect(tableBorders, isNotEmpty);
    for (final border in tableBorders) {
      expect(border.top.color, isNot(ComicPalette.gold));
      expect(border.top.color, ComicPalette.ink);
    }
    expect(tester.takeException(), isNull);
  });
}
