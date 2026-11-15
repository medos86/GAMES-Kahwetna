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
      LaunchRequest? launched;
      await tester.pumpWidget(
        MaterialApp(
          home: MainMenuScreen(onPlay: (request) => launched = request),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Chkobba').first);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(Strings.menuLaunch), findsOneWidget);

      await tester.tap(find.text(Strings.menuLaunch).first);
      await tester.pump(const Duration(milliseconds: 500));

      expect(launched, isNotNull);
      expect(find.text(Strings.menuLaunch), findsNothing);
    },
  );
}
