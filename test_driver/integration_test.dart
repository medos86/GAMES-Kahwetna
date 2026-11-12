// Pilote de `flutter drive` : écrit chaque capture dans screenshots/<nom>.png (issue #206).
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> image, [Map<String, Object?>? args]) async {
      final file = File('screenshots/$name.png')..createSync(recursive: true);
      file.writeAsBytesSync(image);
      return true;
    },
  );
}
