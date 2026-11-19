import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/age_gate_service.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/features/settings/age_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('change la réponse depuis les Paramètres', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AgeGateService.instance.load();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AgeSection()),
      ),
    );
    expect(find.text(Strings.ageNotAnswered), findsOneWidget);

    await tester.tap(find.text(Strings.ageChange));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.ageCurrentUnder));
    await tester.pumpAndSettle();

    expect(AgeGateService.instance.answers.value, AgeAnswer.underThirteen);
    expect(find.text(Strings.ageCurrentUnder), findsOneWidget);
    expect(find.text(Strings.ageChangeTitle), findsNothing);
  });

  testWidgets('Annuler ne change pas la réponse', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AgeGateService.instance.load();
    await AgeGateService.instance.setAnswer(AgeAnswer.thirteenOrOver);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AgeSection()),
      ),
    );
    await tester.tap(find.text(Strings.ageChange));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Strings.ageCancel));
    await tester.pumpAndSettle();

    expect(AgeGateService.instance.answers.value, AgeAnswer.thirteenOrOver);
  });
}
