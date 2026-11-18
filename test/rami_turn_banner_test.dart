import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/i18n/app_language.dart';
import 'package:kahwetne/core/strings.dart';
import 'package:kahwetne/features/rami/rami_turn_banner.dart';
import 'package:kahwetne/widgets/pulse_glow.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUp(() => appLanguage.value = AppLanguage.fr);

  testWidgets(
    'mon tour : bannière dorée pulsante « À toi de jouer »',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RamiTurnBanner(myTurn: true, otherName: 'Ali'),
        ),
      );
      expect(find.text(Strings.ramiYourTurn), findsOneWidget);
      expect(
        tester.widget<PulseGlow>(find.byType(PulseGlow)).active,
        isTrue,
      );
      expect(find.bySemanticsLabel(Strings.ramiYourTurn), findsOneWidget);
    },
  );

  testWidgets(
    'tour d\'un adversaire : nom affiché, sans pulsation',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RamiTurnBanner(myTurn: false, otherName: 'Ali'),
        ),
      );
      expect(find.text('Tour de Ali…'), findsOneWidget);
      expect(find.text(Strings.ramiYourTurn), findsNothing);
      expect(
        tester.widget<PulseGlow>(find.byType(PulseGlow)).active,
        isFalse,
      );
    },
  );

  testWidgets(
    'la bannière passe au tour de l\'adversaire quand le tour change',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RamiTurnBanner(myTurn: true, otherName: 'Karim'),
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: RamiTurnBanner(myTurn: false, otherName: 'Karim'),
        ),
      );
      expect(find.text('Tour de Karim…'), findsOneWidget);
    },
  );
}
