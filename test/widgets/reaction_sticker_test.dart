import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/reactions/reaction_mood.dart';
import 'package:kahwetne/core/services/card_animations.dart';
import 'package:kahwetne/widgets/reaction_sticker.dart';

Widget host(Widget child, {bool disableAnimations = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: child),
      ),
    );

void main() {
  testWidgets('sans humeur, rien n est rendu', (tester) async {
    await tester.pumpWidget(host(const ReactionSticker(mood: null)));
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('affiche le sticker de l humeur donnee', (tester) async {
    await tester.pumpWidget(
      host(const ReactionSticker(mood: ReactionMood.laugh)),
    );
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      ReactionMood.laugh.assetPath,
    );
  });

  testWidgets('réduire les animations : taille pleine immédiatement', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const ReactionSticker(mood: ReactionMood.shock),
        disableAnimations: true,
      ),
    );
    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byType(ReactionSticker),
        matching: find.byType(Transform),
      ),
    );
    expect(transform.transform.storage[0], 1.0);
  });

  testWidgets('apparition : petit puis taille pleine (#788)', (tester) async {
    cardAnimations.value = true;
    addTearDown(() => cardAnimations.value = false);
    await tester.pumpWidget(
      host(const ReactionSticker(mood: ReactionMood.angry)),
    );
    double scale() => tester
        .widget<Transform>(
          find.descendant(
            of: find.byType(ReactionSticker),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .storage[0];

    expect(scale(), closeTo(reactionPopStartScale, 1e-6));
    await tester.pump(reactionPopDuration ~/ 2);
    expect(scale(), greaterThan(reactionPopStartScale));
    await tester.pumpAndSettle();
    expect(scale(), closeTo(1.0, 1e-6));
  });

  testWidgets('sticker non bloquant pour le toucher', (tester) async {
    await tester.pumpWidget(
      host(const ReactionSticker(mood: ReactionMood.kiss)),
    );
    expect(
      find.descendant(
        of: find.byType(ReactionSticker),
        matching: find.byType(IgnorePointer),
      ),
      findsWidgets,
    );
  });
}
