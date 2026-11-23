// Pressable joue son son de clic (issue #792) sans bloquer le onTap.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/audio/sounds.dart';
import 'package:kahwetne/widgets/pressable.dart';

void main() {
  testWidgets('un tap avec son appelle onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Pressable(
          onTap: () => taps++,
          sound: Sfx.uiClick,
          child: const SizedBox(width: 100, height: 40),
        ),
      ),
    ));
    await tester.tap(find.byType(Pressable));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('sans son déclaré, le tap fonctionne toujours', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Pressable(
          onTap: () => taps++,
          child: const SizedBox(width: 100, height: 40),
        ),
      ),
    ));
    await tester.tap(find.byType(Pressable));
    await tester.pump();
    expect(taps, 1);
  });
}
