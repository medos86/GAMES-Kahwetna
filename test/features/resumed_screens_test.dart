import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/features/chkobba/chkobba_controller.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/coinche/coinche_controller.dart';
import 'package:kahwetne/features/coinche/coinche_screen.dart';
import 'package:kahwetne/features/domino/domino_controller.dart';
import 'package:kahwetne/features/domino/domino_screen.dart';
import 'package:kahwetne/features/ludo/ludo_controller.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_controller.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:kahwetne/game/chkobba.dart';
import 'package:kahwetne/game/ludo.dart';
import 'package:kahwetne/game/rami.dart' as rules;
import 'package:shared_preferences/shared_preferences.dart';

// Reprise depuis le menu : une partie sauvegardée est reprise à l'ouverture de l'écran (#219, #167).
Future<void> _resumeScreen(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      home: screen,
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  final resume = find.text(Strings.resumeContinue);
  if (resume.evaluate().isNotEmpty) {
    await tester.tap(resume);
    await tester.pump(const Duration(seconds: 1));
  }
  final error = tester.takeException();
  if (error != null) throw error;
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void _seed(String key, Map<String, dynamic> json) {
  SharedPreferences.setMockInitialValues({
    'kahwetne-save-$key': jsonEncode(json),
  });
}

void main() {
  testWidgets('Rami repris', (tester) async {
    final probe = RamiController(
      targetScore: 100,
      difficulty: rules.RamiAiLevel.facile,
      random: () => 0.37,
    );
    _seed('rami', probe.snapshot()!);
    probe.dispose();
    await _resumeScreen(
      tester,
      const RamiScreen(difficulty: Difficulty.facile, targetScore: 100),
    );
  });

  testWidgets('Coinche repris', (tester) async {
    final probe = CoincheController(
      target: 1000,
      difficulty: Difficulty.facile,
      random: () => 0.37,
    );
    _seed('coinche', probe.snapshot()!);
    probe.dispose();
    await _resumeScreen(
      tester,
      const CoincheScreen(difficulty: Difficulty.facile, targetScore: 1000),
    );
  });

  testWidgets('Domino repris', (tester) async {
    final probe = DominoController(
      targetScore: 50,
      difficulty: Difficulty.facile,
      random: () => 0.37,
    );
    _seed('domino', probe.snapshot()!);
    probe.dispose();
    await _resumeScreen(
      tester,
      const DominoScreen(difficulty: Difficulty.facile, targetScore: 50),
    );
  });

  testWidgets('Ludo repris', (tester) async {
    final probe = LudoController(
      playerCount: 2,
      difficulty: LudoAiLevel.facile,
      random: () => 0.37,
    );
    _seed('ludo', probe.snapshot()!);
    probe.dispose();
    await _resumeScreen(
      tester,
      const LudoScreen(difficulty: Difficulty.facile, players: 2),
    );
  });

  testWidgets('Chkobba repris', (tester) async {
    final probe = ChkobbaController(
      targetScore: 11,
      level: ChkobbaAiLevel.facile,
      random: () => 0.37,
    );
    _seed('chkobba', probe.snapshot()!);
    probe.dispose();
    await _resumeScreen(
      tester,
      const ChkobbaScreen(difficulty: Difficulty.facile, targetScore: 11),
    );
  });
}
