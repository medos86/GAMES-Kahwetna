import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/toast.dart';

void main() {
  Future<void> pumpHost(
    WidgetTester tester,
    void Function(BuildContext) onTap,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => onTap(context),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'affiche le message en SnackBar flottant, marge basse 96, durée 3 s',
    (tester) async {
      await pumpHost(tester, (context) => showToast(context, 'Bien joué'));
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Bien joué'), findsOneWidget);
      final bar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(bar.behavior, SnackBarBehavior.floating);
      expect(bar.duration, const Duration(seconds: 3));
      expect(bar.margin, isNotNull);
      expect(bar.margin!.resolve(TextDirection.ltr).bottom, 96);
      expect(kToastBottomMargin, 96);
    },
  );

  testWidgets('affiche la description quand elle est fournie', (tester) async {
    await pumpHost(
      tester,
      (context) => showToast(
        context,
        'Ouverture refusée',
        description: 'Il faut 51 points',
        type: ToastType.error,
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ouverture refusée'), findsOneWidget);
    expect(find.text('Il faut 51 points'), findsOneWidget);
  });

  testWidgets('sans description : un seul texte', (tester) async {
    await pumpHost(tester, (context) => showToast(context, 'Info seule'));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final bar = find.byType(SnackBar);
    expect(
      find.descendant(of: bar, matching: find.byType(Text)),
      findsOneWidget,
    );
  });

  testWidgets('une icône par type (info, success, error)', (tester) async {
    final expected = <ToastType, IconData>{
      ToastType.info: Icons.info_outline,
      ToastType.success: Icons.check_circle_outline,
      ToastType.error: Icons.error_outline,
    };
    for (final entry in expected.entries) {
      await pumpHost(
        tester,
        (context) => showToast(context, 'msg', type: entry.key),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.byIcon(entry.value),
        ),
        findsOneWidget,
        reason: '${entry.key}',
      );
      // Laisse le toast expirer avant le type suivant.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('un nouveau toast remplace le précédent', (tester) async {
    var count = 0;
    await pumpHost(
      tester,
      (context) => showToast(context, 'Message ${++count}'),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Message 1'), findsOneWidget);

    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Message 1'), findsNothing);
    expect(find.text('Message 2'), findsOneWidget);
  });

  testWidgets('disparaît après 3 secondes', (tester) async {
    await pumpHost(tester, (context) => showToast(context, 'Éphémère'));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Éphémère'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Éphémère'), findsNothing);
  });

  testWidgets(
    'showToastOn : fonctionne à partir d\'une clé ScaffoldMessenger',
    (tester) async {
      final key = GlobalKey<ScaffoldMessengerState>();
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: key,
          home: const Scaffold(body: SizedBox.expand()),
        ),
      );

      showToastOn(key.currentState!, 'Bientôt disponible');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bientôt disponible'), findsOneWidget);
    },
  );
}
