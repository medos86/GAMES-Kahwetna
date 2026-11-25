// Mascotte du carrousel : plus grande, avec une pointe de lumière sur son contour (#901, #902, #904).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/menu/main_menu/game_carousel.dart';
import 'package:kahwetne/features/menu/main_menu/mascot_outline.dart';
import 'package:material_ui/material_ui.dart';

const _chkobbaPath = 'assets/images/mascots/chkobba.png';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 600,
          child: GameCarousel(onSelect: (_) {}, onChanged: (_) {}),
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder _photo() => find.byWidgetPredicate(
      (w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == _chkobbaPath,
    );

void main() {
  testWidgets('pointe de lumière sur le contour (#904)', (tester) async {
    await _pump(tester);
    final spark = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is MascotSparkPainter,
    );
    expect(spark, findsWidgets);
  });

  testWidgets('le reflet est animé en continu (#902)', (tester) async {
    await _pump(tester);
    // Le balayage tourne en boucle : une animation reste active après un pas de temps.
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('la mascotte est plus grande : au moins 160 px (#901)',
      (tester) async {
    await _pump(tester);
    final size = tester.getSize(_photo().first);
    // Carte : 400 px moins les deux flèches => environ 188 px ; photo = 1,6 × 0,56 × 188 ≈ 169 px.
    expect(size.height, greaterThanOrEqualTo(160));
  });
}
