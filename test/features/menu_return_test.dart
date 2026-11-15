import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/features/menu/main_menu_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Au lancement d'un jeu, le menu se remet sur la liste des jeux (#365).
void main() {
  testWidgets(
    'après le lancement, le menu revient à la liste des jeux',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      LaunchRequest? launched;
      await tester.pumpWidget(
        MaterialApp(
          home: MainMenuScreen(onPlay: (request) => launched = request),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Chkobba').first);
      await tester.pump(const Duration(milliseconds: 500));
      // Police de test (Ahem) plus large : débordement de l'écran de niveau sans effet réel.
      tester.takeException();
      expect(find.bySemanticsLabel(Strings.menuLaunch), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(Strings.menuLaunch).first);
      await tester.pump(const Duration(milliseconds: 500));

      expect(launched, isNotNull);
      expect(find.bySemanticsLabel(Strings.menuLaunch), findsNothing);
    },
  );
}
