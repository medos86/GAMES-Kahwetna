import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/profile_store.dart';
import 'package:kahwetne/features/settings/profile_section.dart';
import 'package:kahwetne/widgets/avatar_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue #547 : pseudo modifiable et validé, avatar cliquable.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      profileNamePrefsKey: 'Sfaxi_Lion',
      profileAvatarPrefsKey: 'lion',
    });
  });

  Future<void> pump(WidgetTester tester, {VoidCallback? onPick}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileSection(onPickAvatar: onPick),
        ),
      ),
    );
  }

  testWidgets('affiche le pseudo actuel', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    expect(find.text('Sfaxi_Lion'), findsOneWidget);
  });

  testWidgets('pseudo invalide : erreur, rien de sauvé', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ab');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('trop court'), findsOneWidget);
    expect((await loadProfile()).name, 'Sfaxi_Lion');
  });

  testWidgets('un pseudo valide est sauvegardé', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tigre_Brave');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect((await loadProfile()).name, 'Tigre_Brave');
  });

  testWidgets('tap sur l\'avatar appelle onPickAvatar', (tester) async {
    var picked = false;
    await pump(tester, onPick: () => picked = true);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AvatarView));
    expect(picked, isTrue);
  });
}
