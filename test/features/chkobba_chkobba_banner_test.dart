import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_controller.dart';
import 'package:kahwetne/features/chkobba/chkobba_table.dart';

/// Issue #176 : la bannière « Chkobba ! » suit l'événement de Chkobba, pas une table vide.
void main() {
  burstSlotTests();
  test('la bannière Chkobba partage la durée de la bannière 7AYA', () {
    expect(ChkobbaController.hayaDuration, const Duration(milliseconds: 1000));
  });

  testWidgets('bannière Chkobba centrée sur le tapis, texte lisible', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: ChkobbaBanner(
                  text: 'Chkobba !',
                  colors: [Colors.orange, Colors.red],
                  angle: -0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    expect(find.text('Chkobba !'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

/// Un seul éclat BD par coup, dans un emplacement mis à l'échelle : jamais tronqué (#chkobba-bd).
void burstSlotTests() {
  testWidgets('éclat unique centré : rétréci pour ne jamais être tronqué', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ChkobbaBanner(
                        text: '♦ 7AYA !',
                        colors: [Colors.orange, Colors.red],
                        burstSize: 130,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('♦ 7AYA !'), findsWidgets);
  });
}
