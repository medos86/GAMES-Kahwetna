import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('renovate.json is valid JSON with required keys', () {
    final file = File('renovate.json');
    expect(file.existsSync(), isTrue);
    final config = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(config['extends'], contains('config:recommended'));
    expect(config['timezone'], 'Europe/Paris');
  });

  test('renovate workflow exists and uses RENOVATE_TOKEN', () {
    final wf = File('.github/workflows/renovate.yml').readAsStringSync();
    expect(wf.contains('RENOVATE_TOKEN'), isTrue);
  });
}
