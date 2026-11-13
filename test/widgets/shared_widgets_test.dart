import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/comic_button.dart';
import 'package:kahwetne/widgets/felt_panel.dart';
import 'package:kahwetne/widgets/game_header.dart';
import 'package:kahwetne/widgets/playing_card.dart';
import 'package:kahwetne/widgets/result_dialog.dart';
import 'package:kahwetne/widgets/trophy_badge.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 360, child: child)),
      ),
    );

void main() {
  testWidgets('PlayingCard : dos par défaut puis tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        PlayingCard(
          face: const ColoredBox(color: Colors.white),
          faceDown: true,
          semanticLabel: 'carte',
          onTap: () => taps++,
        ),
      ),
    );
    expect(find.bySemanticsLabel('carte'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('carte'));
    expect(taps, 1);
  });

  testWidgets(
    'ComicButton : appui déclenche onPressed, désactivé ne déclenche rien',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              ComicButton(label: 'Actif', onPressed: () => taps++),
              const ComicButton(
                label: 'Off',
                variant: ComicButtonVariant.danger,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Actif'));
      await tester.tap(find.text('Off'));
      expect(taps, 1);
      for (final v in ComicButtonVariant.values) {
        await tester.pumpWidget(
          _host(ComicButton(label: v.name, onPressed: () {}, variant: v)),
        );
        expect(find.text(v.name), findsOneWidget);
      }
    },
  );

  testWidgets('FeltPanel affiche son contenu', (tester) async {
    await tester.pumpWidget(_host(const FeltPanel(child: Text('tapis'))));
    expect(find.text('tapis'), findsOneWidget);
  });

  testWidgets(
    'TrophyBadge affiche la cible et le halo se désactive avec reduce motion',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(body: Center(child: TrophyBadge(target: 21))),
          ),
        ),
      );
      expect(find.text('21'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('ResultDialog : titre et actions visibles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResultDialog(
            style: ResultDialogStyle.dark,
            title: 'Victoire !',
            actions: [
              ElevatedButton(onPressed: () {}, child: const Text('Rejouer')),
            ],
            children: const [Text('X – Y')],
          ),
        ),
      ),
    );
    expect(find.text('Victoire !'), findsOneWidget);
    expect(find.text('X – Y'), findsOneWidget);
    expect(find.text('Rejouer'), findsOneWidget);
  });
}
