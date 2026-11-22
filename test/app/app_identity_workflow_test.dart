import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('les workflows appliquent le nom et l\'icône Korti Fans', () {
    final apk = File('.github/workflows/apk.yml').readAsStringSync();
    final ios = File('.github/workflows/ios-build.yml').readAsStringSync();
    expect(apk, contains('tool/apply_app_identity.sh android'));
    expect(ios, contains('tool/apply_app_identity.sh ios'));
  });

  test('le script d\'identité et l\'icône source existent', () {
    expect(File('tool/apply_app_identity.sh').existsSync(), isTrue);
    expect(File('assets/images/app_icon.png').existsSync(), isTrue);
  });
}
