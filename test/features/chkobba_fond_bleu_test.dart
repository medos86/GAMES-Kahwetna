// Chkobba : plus de vert, fond bleu avec masque photo (#705).
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/comic_palette.dart';
import 'package:kahwetne/core/theme/scoba_palette.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/widgets/tapis_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lit largeur et hauteur d'un PNG dans son en-tête IHDR.
(int, int) _pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(Uint8List.fromList(bytes));
  return (data.getUint32(16), data.getUint32(20));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('#705 : le masque garde le ratio de la photo source (784x1168)', () {
    expect(_pngSize(TapisBackground.motifAsset), (784, 1168));
  });

  test('#705 : aucun vert dans la palette du tapis Chkobba', () {
    final green = ComicPalette.seatGreen;
    expect(ScobaPalette.tapisBleu, isNot(green));
    expect(ScobaPalette.tapisBleu, ComicPalette.tunisBlue);
  });

  testWidgets('#705 : écran Chkobba sur fond bleu avec masque', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: ChkobbaScreen(difficulty: Difficulty.facile, targetScore: 11),
      ),
    );
    await tester.pump();
    final box = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('tapis-background')),
    );
    final deco = box.decoration as BoxDecoration;
    expect(deco.color, ComicPalette.tunisBlue);
    expect(deco.image!.repeat, ImageRepeat.repeat);
    expect(
      (deco.image!.image as AssetImage).assetName,
      'assets/images/tapis/tapis_masque.png',
    );
    expect(tester.takeException(), isNull);
  });
}
