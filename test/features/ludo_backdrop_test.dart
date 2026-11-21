// Fond du Ludo : image-masque appliquée sur le dégradé bleu.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/ludo_backdrop_palette.dart';
import 'package:kahwetne/features/ludo/ludo_backdrop.dart';

void main() {
  test('le masque du Ludo est déclaré et présent', () {
    expect(File(ludoBackdropMaskAsset).existsSync(), isTrue);
  });

  test('le masque est compressé (moins de 100 Ko)', () {
    final size = File(ludoBackdropMaskAsset).lengthSync();
    expect(size, lessThan(100 * 1024));
  });

  test('le masque est un WebP', () {
    final bytes = File(ludoBackdropMaskAsset).readAsBytesSync();
    expect(bytes.sublist(0, 4), Uint8List.fromList('RIFF'.codeUnits));
    expect(bytes.sublist(8, 12), Uint8List.fromList('WEBP'.codeUnits));
  });

  test('la teinte du masque est blanche et translucide, jamais opaque', () {
    expect(LudoBackdropPalette.maskTint.a, lessThan(0.5));
    expect(
      LudoBackdropPalette.maskTint.value & 0x00FFFFFF,
      0x00FFFFFF,
    );
  });

  testWidgets('le fond du Ludo se peint sans erreur', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(width: 360, height: 640, child: LudoBackdrop()),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
