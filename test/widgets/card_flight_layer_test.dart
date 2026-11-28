import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/widgets/card_flight.dart';

/// Issue #1058 : une couche de vol partagée, pas une animation par carte.
void main() {
  setUp(() => cardAnimations.value = true);
  tearDown(() => cardAnimations.value = false);

  testWidgets('52 cartes en vol : aucune animation par carte', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    final futures = <Future<void>>[];
    for (var i = 0; i < 52; i++) {
      futures.add(
        flyCard(
          context: context,
          from: const Rect.fromLTWH(0, 0, 40, 60),
          to: () => const Rect.fromLTWH(200, 200, 40, 60),
          delay: Duration(milliseconds: 10 * i),
          child: SizedBox(key: ValueKey('c$i'), width: 40, height: 60),
        ),
      );
    }
    await tester.pump(const Duration(milliseconds: 50));
    // Pas de TweenAnimationBuilder par carte : la couche est unique.
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    expect(find.byKey(const ValueKey('c0')), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    await Future.wait(futures);
    expect(find.byKey(const ValueKey('c0')), findsNothing);
  });

  testWidgets('vol suivant : sa course démarre au lancement', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );
    final first = flyCard(
      context: context,
      from: const Rect.fromLTWH(0, 0, 40, 60),
      to: () => const Rect.fromLTWH(200, 0, 40, 60),
      duration: const Duration(milliseconds: 300),
      child: const SizedBox(key: ValueKey('a'), width: 40, height: 60),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 400));
    await first;
    expect(find.byKey(const ValueKey('a')), findsNothing);

    final second = flyCard(
      context: context,
      from: const Rect.fromLTWH(0, 0, 40, 60),
      to: () => const Rect.fromLTWH(200, 0, 40, 60),
      duration: const Duration(milliseconds: 300),
      child: const SizedBox(key: ValueKey('b'), width: 40, height: 60),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byKey(const ValueKey('b')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    await second;
    expect(find.byKey(const ValueKey('b')), findsNothing);
  });
}
