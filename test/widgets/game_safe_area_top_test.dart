import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_rules_screen.dart';
import 'package:kahwetne/widgets/game_safe_area.dart';
import 'package:material_ui/material_ui.dart';

/// Issue #204 : la marge de caméra/encoche ne doit pas faire descendre les boutons du haut.
void main() {
  Widget withTopInset(Widget home) => MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 640),
          padding: EdgeInsets.only(top: 40),
        ),
        child: MaterialApp(home: home),
      );

  testWidgets('GameSafeArea sans marge de caméra', (tester) async {
    const key = Key('contenu');
    await tester.pumpWidget(
      withTopInset(const GameSafeArea(child: SizedBox(key: key))),
    );
    expect(tester.getTopLeft(find.byKey(key)).dy, 0);
  });

  testWidgets('Règles Chkobba utilisent GameSafeArea', (tester) async {
    await tester.pumpWidget(withTopInset(const ChkobbaRulesScreen()));
    await tester.pump();
    expect(find.byType(GameSafeArea), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
