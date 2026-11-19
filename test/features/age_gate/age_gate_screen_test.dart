import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/age_gate_service.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/features/age_gate/age_gate_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Oui renvoie thirteenOrOver', (tester) async {
    AgeAnswer? answered;
    await tester.pumpWidget(
      MaterialApp(
        home: AgeGateScreen(onAnswer: (answer) => answered = answer),
      ),
    );

    await tester.tap(find.text(Strings.ageGateYes));
    await tester.pump();

    expect(answered, AgeAnswer.thirteenOrOver);
  });

  testWidgets('Non renvoie underThirteen', (tester) async {
    AgeAnswer? answered;
    await tester.pumpWidget(
      MaterialApp(
        home: AgeGateScreen(onAnswer: (answer) => answered = answer),
      ),
    );

    await tester.tap(find.text(Strings.ageGateNo));
    await tester.pump();

    expect(answered, AgeAnswer.underThirteen);
  });

  testWidgets('« Pourquoi ? » ouvre l’explication', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AgeGateScreen(onAnswer: (_) {}),
      ),
    );

    await tester.tap(find.text(Strings.ageGateWhy));
    await tester.pumpAndSettle();

    expect(find.text(Strings.ageGateWhyBody), findsOneWidget);
  });

  testWidgets('wrapper : question puis menu après réponse', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AgeGateService.instance.load();

    await tester.pumpWidget(
      const MaterialApp(
        home: AgeGateGate(next: Text('MENU')),
      ),
    );
    expect(find.text(Strings.ageGateQuestion), findsOneWidget);

    await tester.tap(find.text(Strings.ageGateYes));
    await tester.pumpAndSettle();

    expect(find.text('MENU'), findsOneWidget);
    expect(find.text(Strings.ageGateQuestion), findsNothing);
  });

  testWidgets('le wrapper laisse passer directement si déjà répondu',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AgeGateService.instance.load();
    await AgeGateService.instance.setAnswer(AgeAnswer.underThirteen);

    await tester.pumpWidget(
      const MaterialApp(
        home: AgeGateGate(next: Text('MENU')),
      ),
    );

    expect(find.text('MENU'), findsOneWidget);
    expect(find.text(Strings.ageGateQuestion), findsNothing);
  });
}
