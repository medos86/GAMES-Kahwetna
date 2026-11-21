// Pas de contour brun autour du grand carré du plateau Ludo (#689).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _boardPath = 'lib/features/ludo/ludo_parts/ludo_board.dart';

void main() {
  final source = File(_boardPath).readAsStringSync();

  test('#689 : le cadre externe du plateau n a pas de contour', () {
    expect(source.contains('Border.all(color: _brown, width: 6)'), isFalse);
  });

  test('#689 : le fond crème du plateau reste arrondi', () {
    expect(source.contains('BorderRadius.circular(20)'), isTrue);
  });
}
