import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/widgets/game_header.dart';

/// Socle commun des en-têtes de jeu (#242).
Widget _host(Widget child, {double width = 390}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 844)),
        child: Scaffold(body: SizedBox(width: width, child: child)),
      ),
    );

void main() {
  testWidgets('le bouton Menu appelle onMenu', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(GameHeader(onMenu: () => taps++)));
    await tester.tap(find.text(Strings.menuLabel));
    expect(taps, 1);
  });

  testWidgets(
    'pas de titre « KAHWETNE » dans l\'en-tête (#223)',
    (tester) async {
      await tester.pumpWidget(_host(GameHeader(onMenu: () {})));
      expect(find.textContaining('KAHWETNE'), findsNothing);
    },
  );

  testWidgets('Menu à gauche, emplacement à droite', (tester) async {
    await tester.pumpWidget(
      _host(
        GameHeader(
          onMenu: () {},
          trailing: const SizedBox(
            key: ValueKey('droite'),
            width: 40,
            height: 40,
          ),
        ),
      ),
    );
    final menuX = tester.getTopLeft(find.text(Strings.menuLabel)).dx;
    final rightX = tester.getTopLeft(find.byKey(const ValueKey('droite'))).dx;
    expect(menuX, lessThan(195));
    expect(rightX, greaterThan(195));
  });

  testWidgets('même position du Menu à 360 px et à 430 px', (tester) async {
    await tester.pumpWidget(_host(GameHeader(onMenu: () {}), width: 360));
    final narrow = tester.getTopLeft(find.byType(TextButton)).dx;
    await tester.pumpWidget(_host(GameHeader(onMenu: () {}), width: 430));
    final wide = tester.getTopLeft(find.byType(TextButton)).dx;
    expect(narrow, wide);
  });
}
