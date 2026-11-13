import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/game_scaffold.dart';

/// Socle commun des écrans de jeu (#242) : le contenu est affiché dans la zone sûre.
void main() {
  testWidgets('le contenu du jeu est affiché dans le socle', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(padding: EdgeInsets.only(top: 40)),
        child: GameScaffold(showAd: false, child: Text('contenu')),
      ),
    ));
    expect(find.text('contenu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la marge du haut ne dépasse pas le plafond du socle', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(padding: EdgeInsets.only(top: 40)),
        child: GameScaffold(showAd: false, child: Text('contenu')),
      ),
    ));
    final top = tester.getTopLeft(find.text('contenu')).dy;
    expect(top, lessThanOrEqualTo(40));
  });
}
