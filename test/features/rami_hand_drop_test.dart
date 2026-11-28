import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/layout/device_metrics.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_card_view.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:kahwetne/widgets/ad_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #1076 : la main est plus grande et descend jusqu'au bord de la bordure noire,
/// sans jamais atteindre la zone de la pub.
void main() {
  test('cartes de la main plus grandes qu\'avant (#1076)', () {
    expect(ramiHandCardScale, greaterThan(1.55));
  });

  test('la descente de la main = padding du feutre + bordure (#1076)', () {
    expect(ramiHandDrop, ramiTableFeltPadding + ramiTableFrameWidth);
  });

  test('la descente reste sous la marge avant la pub (#1076)', () {
    expect(ramiHandDrop, lessThan(ramiAdSafeGap));
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('la main descend sous la bordure sans atteindre la pub (#1076)', (
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

    final tableFinder = find.byWidgetPredicate((w) {
      if (w is! Container) return false;
      final d = w.decoration;
      return d is BoxDecoration &&
          d.borderRadius == BorderRadius.circular(22);
    });
    expect(tableFinder, findsWidgets);
    final tableRect = tester.getRect(tableFinder.first);

    final cards = find.byType(RamiCardView);
    expect(cards, findsWidgets);
    var lowest = double.negativeInfinity;
    for (var i = 0; i < cards.evaluate().length; i++) {
      final rect = tester.getRect(cards.at(i));
      if (rect.bottom > lowest) lowest = rect.bottom;
    }

    // Ne dépasse pas le bord extérieur de la bordure noire (6 px) au-delà de la descente.
    expect(lowest, lessThanOrEqualTo(tableRect.bottom + ramiTableFrameWidth + 0.5));

    final ad = find.byType(AdBanner);
    if (ad.evaluate().isNotEmpty) {
      expect(lowest, lessThan(tester.getRect(ad.first).top));
    }
    expect(tester.takeException(), isNull);
  });
}
