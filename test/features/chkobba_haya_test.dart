import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_controller.dart';
import 'package:kahwetne/features/chkobba/chkobba_table.dart';
import 'package:kahwetne/widgets/comic/action_burst.dart';

// Bannière « 7AYA ! » : plus petite et plus courte, pour ne pas masquer le plateau (#364).
void main() {
  test('la bannière 7AYA reste affichée une seconde', () {
    expect(ChkobbaController.hayaDuration, const Duration(milliseconds: 1000));
  });

  testWidgets('la bannière 7AYA utilise l\'éclat à la taille demandée', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: ChkobbaBanner(
            text: '♦ 7AYA !',
            colors: [Colors.orange, Colors.red],
            burstSize: 110,
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(ActionBurst)).width, 110);
    expect(tester.takeException(), isNull);
  });
}
