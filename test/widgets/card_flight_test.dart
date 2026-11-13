import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/widgets/card_flight.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Vol d'une carte entre deux emplacements, réglage coupé ou activé (#224).
Future<BuildContext> _pumpApp(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (ctx) {
          context = ctx;
          return const Scaffold(body: SizedBox());
        },
      ),
    ),
  );
  return context;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cardAnimations.value = false;
  });

  testWidgets('réglage coupé : pas de vol', (tester) async {
    final context = await _pumpApp(tester);
    await flyCard(
      context: context,
      from: const Rect.fromLTWH(0, 0, 40, 60),
      to: const Rect.fromLTWH(200, 200, 40, 60),
      child: const SizedBox(key: ValueKey('vol'), width: 40, height: 60),
    );
    expect(find.byKey(const ValueKey('vol')), findsNothing);
  });

  testWidgets('réglage activé : la carte vole puis disparaît', (tester) async {
    cardAnimations.value = true;
    final context = await _pumpApp(tester);
    final done = flyCard(
      context: context,
      from: const Rect.fromLTWH(0, 0, 40, 60),
      to: const Rect.fromLTWH(200, 200, 40, 60),
      duration: const Duration(milliseconds: 300),
      child: const SizedBox(key: ValueKey('vol'), width: 40, height: 60),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('vol')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('vol')), findsNothing);
    await done;
  });

  testWidgets('préférence sauvegardée relue au démarrage', (tester) async {
    SharedPreferences.setMockInitialValues({cardAnimationsPrefsKey: true});
    await loadCardAnimations();
    expect(cardAnimations.value, isTrue);
    await setCardAnimations(false);
    expect(cardAnimations.value, isFalse);
  });
}
