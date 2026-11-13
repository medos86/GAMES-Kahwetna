import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/widgets/game_header.dart';
import 'package:material_ui/material_ui.dart';

/// Socle commun des en-têtes de jeu (#242).
Widget _host(Widget child, {double width = 390}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 844)),
        child: Scaffold(body: SizedBox(width: width, child: child)),
      ),
    );

void main() {
  testWidgets('la pastille Menu appelle onMenu', (tester) async {
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

  testWidgets('Menu à gauche, contenu central et droite', (tester) async {
    await tester.pumpWidget(
      _host(
        GameHeader(
          onMenu: () {},
          center: const Expanded(
            child: Text('centre', key: ValueKey('centre')),
          ),
          trailing: const SizedBox(key: ValueKey('droite'), width: 40),
        ),
      ),
    );
    final menuX = tester.getTopLeft(find.text(Strings.menuLabel)).dx;
    final centreX = tester.getTopLeft(find.byKey(const ValueKey('centre'))).dx;
    final rightX = tester.getTopLeft(find.byKey(const ValueKey('droite'))).dx;
    expect(menuX, lessThan(centreX));
    expect(centreX, lessThan(rightX));
  });

  testWidgets('même position du Menu à 360 px et à 430 px', (tester) async {
    await tester.pumpWidget(_host(GameHeader(onMenu: () {}), width: 360));
    final narrow = tester.getTopLeft(find.text(Strings.menuLabel)).dx;
    await tester.pumpWidget(_host(GameHeader(onMenu: () {}), width: 430));
    final wide = tester.getTopLeft(find.text(Strings.menuLabel)).dx;
    expect(narrow, wide);
  });
}
