import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/game_end_sequence.dart';
import 'package:kahwetne/widgets/round_result_panel.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(body: Center(child: SingleChildScrollView(child: child))),
    );

RoundResultPanel _panel({bool? won, ValueListenable<bool>? revealed}) =>
    RoundResultPanel(
      title: 'Victoire',
      badge: 'PARTIE TERMINÉE',
      won: won,
      revealed: revealed,
      rows: const [],
      actions: const [],
    );

void main() {
  testWidgets('sans révélation : animation tout de suite', (tester) async {
    await tester.pumpWidget(_host(_panel(won: true)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('win-celebration-confetti')), findsOneWidget);
  });

  testWidgets('pub en attente : pas d animation avant révélation',
      (tester) async {
    final seq = GameEndSequence();
    await tester.pumpWidget(_host(_panel(won: true, revealed: seq.revealed)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('win-celebration-confetti')), findsNothing);
    expect(find.byKey(const Key('win-celebration-defeat')), findsNothing);
  });

  testWidgets('après la pub : animation de gain', (tester) async {
    final seq = GameEndSequence();
    await tester.pumpWidget(_host(_panel(won: true, revealed: seq.revealed)));
    seq.start(() async => null);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('win-celebration-confetti')), findsOneWidget);
  });

  testWidgets('après la pub : animation de perte si défaite', (tester) async {
    final seq = GameEndSequence();
    await tester.pumpWidget(_host(_panel(won: false, revealed: seq.revealed)));
    seq.start(() async => null);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('win-celebration-defeat')), findsOneWidget);
  });
}
