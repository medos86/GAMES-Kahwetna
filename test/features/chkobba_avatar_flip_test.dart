// Rotation 3D de l'avatar après une prise (#988) : une fois par prise, puis retour initial.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';

const _flipKey = ValueKey('chkobba-avatar-flip');

Widget _app(int trigger) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: ChkobbaAvatarFlip(
          trigger: trigger,
          child: const SizedBox(width: 40, height: 40),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => cardAnimations.value = true);

  testWidgets('pas de rotation sans nouvelle prise', (tester) async {
    await tester.pumpWidget(_app(0));
    await tester.pumpWidget(_app(0));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(_flipKey), findsNothing);
  });

  testWidgets('rotation à chaque prise puis retour initial', (tester) async {
    await tester.pumpWidget(_app(0));
    await tester.pumpWidget(_app(1));
    await tester.pump(const Duration(milliseconds: 300));

    // En plein tour : une transformation 3D est appliquée.
    final mid = tester.widget<Transform>(find.byKey(_flipKey));
    expect(mid.transform.storage[0], isNot(closeTo(1, 1e-3)));

    // Fin : plus de transformation, l'avatar est à sa place.
    await tester.pumpAndSettle();
    expect(find.byKey(_flipKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demi-tour à 90° puis 180° (#1019)', (tester) async {
    await tester.pumpWidget(_app(0));
    await tester.pumpWidget(_app(1));
    // Quart du parcours (150 ms sur 600 ms) : un quart de tour du demi-tour, 90°.
    await tester.pump(const Duration(milliseconds: 150));
    final quarter = tester.widget<Transform>(find.byKey(_flipKey));
    expect(quarter.transform.storage[0], closeTo(0, 1e-2));

    // Mi-parcours : demi-tour complet, l'avatar montre son dos (cos 180° = -1).
    await tester.pump(const Duration(milliseconds: 150));
    final half = tester.widget<Transform>(find.byKey(_flipKey));
    expect(half.transform.storage[0], closeTo(-1, 1e-2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('pas de rotation si animations désactivées', (tester) async {
    cardAnimations.value = false;
    await tester.pumpWidget(_app(0));
    await tester.pumpWidget(_app(1));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(_flipKey), findsNothing);
  });
}
