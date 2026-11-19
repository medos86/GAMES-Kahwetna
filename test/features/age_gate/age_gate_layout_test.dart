import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/age_gate/age_gate_screen.dart';

/// Mise en page de la question d'âge (issues #571 et #572) : sans débordement
/// en RTL (arabe), grand texte et petit écran. Les textes AR restent à relire.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAt(
    WidgetTester tester, {
    required TextDirection direction,
    required double textScale,
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => Directionality(
          textDirection: direction,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
        ),
        home: AgeGateScreen(onAnswer: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('RTL et grand texte', (tester) async {
    await pumpAt(
      tester,
      direction: TextDirection.rtl,
      textScale: 2,
      size: const Size(320, 568),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('paysage petit écran : sans débordement', (tester) async {
    await pumpAt(
      tester,
      direction: TextDirection.ltr,
      textScale: 1.5,
      size: const Size(568, 320),
    );

    expect(tester.takeException(), isNull);
  });
}
