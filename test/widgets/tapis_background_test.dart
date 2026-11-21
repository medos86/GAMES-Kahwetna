// Fond tapis plein écran (#695) : le motif de la porte est un masque répété sur le feutre.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/comic_palette.dart';
import 'package:kahwetne/widgets/tapis_background.dart';

void main() {
  test('#695 : le masque du tapis existe', () {
    expect(File(TapisBackground.motifAsset).existsSync(), isTrue);
  });

  testWidgets('#695 : le tapis couvre l\'écran', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: TapisBackground())),
    );
    final box = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('tapis-background')),
    );
    final deco = box.decoration as BoxDecoration;
    expect(deco.color, ComicPalette.tunisBlue);
    final image = deco.image!;
    expect(image.repeat, ImageRepeat.repeat);
    expect(image.image, isA<AssetImage>());
    expect((image.image as AssetImage).assetName, TapisBackground.motifAsset);
    expect(tester.takeException(), isNull);
  });
}
