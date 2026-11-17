import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_round_reveal.dart';
import 'package:kahwetne/widgets/comic/action_burst.dart';

/// Issue #417 : l'annonce du gagnant reste 2,5 s avant le tableau des scores.
void main() {
  testWidgets('le tableau des scores attend la fin de l\'annonce', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: RamiRoundReveal(
          burst: 'GAGNÉ !',
          child: Text('TABLEAU'),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ActionBurst), findsOneWidget);
    expect(find.text('TABLEAU'), findsNothing);

    await tester.pump(const Duration(milliseconds: 2400));
    expect(find.text('TABLEAU'), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('TABLEAU'), findsOneWidget);
    expect(find.byType(ActionBurst), findsNothing);
  });
}
