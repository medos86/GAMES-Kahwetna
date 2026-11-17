import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/widgets/card_flight.dart';

// Une carte qui va vers un tas s'enfonce sous le bord bas du tableau (#357).
void main() {
  setUp(() => cardAnimations.value = true);
  tearDown(() => cardAnimations.value = false);

  const cardKey = Key('carte-en-vol');

  Future<void> pumpFlight(
    WidgetTester tester, {
    Rect? Function()? occluder,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              flyCard(
                context: context,
                from: const Rect.fromLTWH(100, 300, 50, 70),
                to: () => const Rect.fromLTWH(100, 0, 50, 70),
                child: const ColoredBox(key: cardKey, color: Colors.red),
                occluder: occluder,
              );
            });
            return const SizedBox.expand();
          },
        ),
      ),
    );
  }

  testWidgets('la carte est coupée au bord bas de la zone traversée', (
    tester,
  ) async {
    await pumpFlight(
      tester,
      occluder: () => const Rect.fromLTWH(0, 0, 400, 60),
    );
    await tester.pump(const Duration(milliseconds: 150));

    final clip = tester.widget<ClipRect>(
      find.ancestor(
        of: find.byKey(cardKey),
        matching: find.byType(ClipRect),
      ),
    );
    final top = tester.getTopLeft(find.byKey(cardKey)).dy;
    final rect = clip.clipper!.getClip(const Size(50, 70));
    // La coupe est au bord bas de la zone (y = 60), exprimé dans la carte.
    expect(rect.top, closeTo(60 - top, 0.01));

    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sans zone traversée : pas de coupe', (tester) async {
    await pumpFlight(tester);
    await tester.pump(const Duration(milliseconds: 150));

    expect(
      find.ancestor(
        of: find.byKey(cardKey),
        matching: find.byType(ClipRect),
      ),
      findsNothing,
    );
    await tester.pump(const Duration(seconds: 1));
  });
}
