// Rotation 3D de l'avatar après une prise (#988) : déclenchée une fois, puis retour à l'état initial.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';

void main() {
  setUp(() => cardAnimations.value = true);

  Widget app(int trigger) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: ChkobbaAvatarFlip(
              trigger: trigger,
              child: const SizedBox(
                key: ValueKey('avatar'),
                width: 40,
                height: 40,
              ),
            ),
          ),
        ),
      );

  testWidgets('#988 : pas de rotation sans prise (trigger inchangé)', (
    tester,
  ) async {
    await tester.pumpWidget(app(0));
    await tester.pumpWidget(app(0));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(Transform), findsNothing);
    expect(find.byKey(const ValueKey('avatar')), findsOneWidget);
  });

  testWidgets('#988 : la rotation se déclenche à chaque prise puis revient à l\'état initial', (
    tester,
  ) async {
    await tester.pumpWidget(app(0));
    await tester.pumpWidget(app(1));
    await tester.pump(const Duration(milliseconds: 300));

    // En plein tour : une transformation 3D est appliquée à l'avatar.
    final mid = tester.widget<Transform>(
      find.descendant(
        of: find.byType(ChkobbaAvatarFlip),
        matching: find.byType(Transform),
      ),
    );
    expect(mid.transform.storage[0], isNot(closeTo(1, 1e-3)));

    // Fin de l'animation : plus de transformation, l'avatar est à sa place.
    await tester.pumpAndSettle();
    expect(find.byType(Transform), findsNothing);
    expect(find.byKey(const ValueKey('avatar')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('#988 : pas de rotation si les animations sont désactivées', (
    tester,
  ) async {
    cardAnimations.value = false;
    await tester.pumpWidget(app(0));
    await tester.pumpWidget(app(1));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(Transform), findsNothing);
  });
}
