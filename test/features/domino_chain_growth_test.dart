// Croissance de la chaîne Domino (#960) : taille de départ, zoom, pierres fixes, retour à la ligne.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/domino/domino_chain_layout.dart';
import 'package:kahwetne/features/domino/domino_tiles.dart';
import 'package:kahwetne/game/domino.dart';

void main() {
  test('#960 : la chaîne commence à taille pleine, sans zoom', () {
    final slots = layoutChainAroundCenter(
      count: 1,
      openIndex: 0,
      halfWidth: 6,
    );
    final scale = chainScale(
      slots: slots,
      unit: 30,
      width: 360,
      height: 600,
    );
    expect(scale, 1.0);
  });

  test('#960 : le zoom ne baisse que quand la chaîne déborde en largeur', () {
    final few = layoutChainAroundCenter(
      count: 5,
      openIndex: 2,
      halfWidth: 6,
    );
    expect(
      chainScale(slots: few, unit: 30, width: 360, height: 600),
      1.0,
    );
    final many = layoutChainAroundCenter(
      count: 80,
      openIndex: 40,
      halfWidth: 6,
    );
    // #1043 : la hauteur déclenche le zoom arrière ; la chaîne ne défile jamais.
    final scale = chainScale(slots: many, unit: 30, width: 360, height: 600);
    expect(scale < 1.0, isTrue);
  });

  test('#960 : ajouter en bout ne déplace aucune pierre existante', () {
    for (final halfWidth in [6, 8]) {
      for (var n = 1; n < 30; n++) {
        for (var open = 0; open < n; open++) {
          final before = layoutChainAroundCenter(
            count: n,
            openIndex: open,
            halfWidth: halfWidth,
          );
          final after = layoutChainAroundCenter(
            count: n + 1,
            openIndex: open,
            halfWidth: halfWidth,
          );
          for (var i = 0; i < n; i++) {
            expect(
              (after[i].x, after[i].y, after[i].vertical),
              (before[i].x, before[i].y, before[i].vertical),
              reason: 'pierre $i déplacée (n=$n, open=$open, côté droit)',
            );
          }
        }
      }
    }
  });

  test('#960 : ajouter en tête ne déplace aucune pierre existante', () {
    for (final halfWidth in [6, 8]) {
      for (var n = 1; n < 30; n++) {
        for (var open = 0; open < n; open++) {
          final before = layoutChainAroundCenter(
            count: n,
            openIndex: open,
            halfWidth: halfWidth,
          );
          // Pierre ajoutée avant : l'ouverture passe à open+1.
          final after = layoutChainAroundCenter(
            count: n + 1,
            openIndex: open + 1,
            halfWidth: halfWidth,
          );
          for (var i = 0; i < n; i++) {
            expect(
              (after[i + 1].x, after[i + 1].y, after[i + 1].vertical),
              (before[i].x, before[i].y, before[i].vertical),
              reason: 'pierre $i déplacée (n=$n, open=$open, côté gauche)',
            );
          }
        }
      }
    }
  });

  test('#1022 : la taille de départ est grande, sans plafond', () {
    for (final width in [360.0, 390.0, 800.0, 1200.0]) {
      final halfWidth = width >= 480 ? 8 : 6;
      final unit = chainStartUnit(width: width, halfWidth: halfWidth);
      // #1022 : une pierre fait le tiers de la largeur au départ.
      expect(unit * 6, closeTo(width, 1e-9));
      expect(unit * 2 * 2, closeTo(width * 2 / 3, 1e-9));
      final slots = layoutChainAroundCenter(
        count: 1,
        openIndex: 0,
        halfWidth: halfWidth,
      );
      expect(
        chainScale(slots: slots, unit: unit, width: width, height: 600),
        1.0,
      );
    }
  });

  test('#960 : un virage ne se fait qu\'en bout de rangée', () {
    for (final halfWidth in [6, 8]) {
      final slots = layoutChainAroundCenter(
        count: 60,
        openIndex: 0,
        halfWidth: halfWidth,
      );
      for (var i = 1; i < slots.length; i++) {
        final s = slots[i];
        if (!s.vertical) continue;
        final prev = slots[i - 1];
        expect(
          prev.vertical,
          isFalse,
          reason: 'deux virages de suite (index $i, demi $halfWidth)',
        );
        if (s.x == halfWidth - 1) {
          // Virage à droite : la rangée précédente touche le bord.
          expect(
            prev.x + prev.width,
            halfWidth - 1,
            reason: 'virage droit avant la fin de rangée (index $i)',
          );
        } else if (s.x == 1) {
          // Virage à gauche : rangée précédente jusqu'au bord intérieur.
          expect(
            prev.x,
            2,
            reason: 'virage gauche avant la fin de rangée (index $i)',
          );
        }
      }
    }
  });

  testWidgets(
    '#960 : ajouter une pierre ne déplace rien à l\'écran',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      PlacedTile tile(int i) => PlacedTile(
            id: 't$i',
            a: i % 6,
            b: (i + 1) % 6,
            left: i % 6,
            right: (i + 1) % 6,
          );

      Future<void> pump(int count) => tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: 360,
                  height: 600,
                  child: DominoChain(
                    chain: [for (var i = 0; i < count; i++) tile(i)],
                    leftOpen: true,
                    rightOpen: true,
                    onEndTap: (_) {},
                    openingId: 't5',
                  ),
                ),
              ),
            ),
          );

      await pump(8);
      await tester.pump(const Duration(milliseconds: 400));
      final before = tester.getTopLeft(find.byKey(const ValueKey('t2')));

      await pump(9);
      await tester.pump(const Duration(milliseconds: 400));
      final after = tester.getTopLeft(find.byKey(const ValueKey('t2')));

      expect(after, before);
      expect(tester.takeException(), isNull);
    },
  );
}
