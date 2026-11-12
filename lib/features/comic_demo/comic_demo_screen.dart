import 'package:material_ui/material_ui.dart';

import '../../core/i18n/translations.dart';
import '../../core/theme/comic_palette.dart';
import '../../core/strings.dart';
import '../../widgets/comic/action_burst.dart';
import '../../widgets/comic/comic_panel.dart';
import '../../widgets/comic/halftone_overlay.dart';
import '../../widgets/comic/speech_bubble.dart';

/// Page de démo du thème BD (issue #98).
/// Lancer avec `flutter run --dart-define=COMIC_DEMO=true`.
/// Le bouton FR / AR change seulement cette page (la langue de l'app ne bouge pas).
class ComicDemoScreen extends StatefulWidget {
  const ComicDemoScreen({super.key});

  @override
  State<ComicDemoScreen> createState() => _ComicDemoScreenState();
}

class _ComicDemoScreenState extends State<ComicDemoScreen> {
  bool _arabic = false;
  int _burstKey = 0;
  String _burstText = 'PAFF !';

  // Texte de démo : même clé dans les deux langues.
  Map<String, String> get _texts => _arabic ? arTexts : frTexts;

  void _burst(String text) => setState(() {
        _burstText = text;
        _burstKey++;
      });

  @override
  Widget build(BuildContext context) {
    final dir = _arabic ? TextDirection.rtl : TextDirection.ltr;
    final family = _arabic ? 'Tajawal' : 'Bangers';
    return Directionality(
      textDirection: dir,
      child: Scaffold(
        backgroundColor: ComicPalette.paper,
        appBar: AppBar(
          backgroundColor: ComicPalette.yellow,
          foregroundColor: ComicPalette.ink,
          title: const Text(
            'Démo BD',
            style: TextStyle(fontFamily: 'Bangers', fontSize: 26),
          ),
          actions: [
            TextButton(
              onPressed: () => setState(() => _arabic = !_arabic),
              child: Text(
                _arabic ? 'FR' : 'AR',
                style: const TextStyle(
                  color: ComicPalette.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Palette'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _Swatch('encre', ComicPalette.ink),
                _Swatch('papier', ComicPalette.paper),
                _Swatch('rouge', ComicPalette.red),
                _Swatch('jaune', ComicPalette.yellow),
                _Swatch('bleu tunisien', ComicPalette.tunisBlue),
              ],
            ),
            _section('Case et trame'),
            HalftoneOverlay(
              child: ComicPanel(
                color: ComicPalette.paper,
                child: Text(
                  _texts['menuChooseLevelNote'] ?? '',
                  textAlign: _arabic ? TextAlign.right : TextAlign.left,
                  style: TextStyle(
                    fontFamily: family,
                    fontSize: 16,
                    color: ComicPalette.ink,
                  ),
                ),
              ),
            ),
            _section('Bulles'),
            SpeechBubble(
              tailOnLeft: !_arabic,
              child: Text(
                _texts['menuComingSoonBody'] ?? '',
                style: TextStyle(
                  fontFamily: family,
                  fontSize: 16,
                  color: ComicPalette.ink,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: _arabic ? Alignment.centerLeft : Alignment.centerRight,
              child: SpeechBubble(
                tailOnLeft: _arabic,
                fill: ComicPalette.yellow,
                child: Text(
                  _texts['menuStart'] ?? '',
                  style: TextStyle(
                    fontFamily: family,
                    fontSize: 18,
                    color: ComicPalette.ink,
                  ),
                ),
              ),
            ),
            _section('Onomatopées (toucher pour rejouer)'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final word in const ['PAFF !', 'POW !', 'BAM !'])
                  GestureDetector(
                    onTap: () => _burst(word),
                    child: ComicPanel(
                      color: ComicPalette.paper,
                      child: Text(
                        word,
                        style: const TextStyle(
                          fontFamily: 'Bangers',
                          fontSize: 22,
                          color: ComicPalette.ink,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ActionBurst(
                key: ValueKey(_burstKey),
                text: _burstText,
                size: 140,
              ),
            ),
            _section('Titres et textes'),
            Text(
              _texts['menuTagline'] ?? '',
              style: TextStyle(
                fontFamily: family,
                fontSize: 28,
                color: ComicPalette.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _texts['levelHard'] ?? '',
              style: TextStyle(
                fontFamily: family,
                fontSize: 18,
                color: ComicPalette.red,
              ),
            ),
            const SizedBox(height: 8),
            // Le texte de l'app (Strings) reste en français ici : la démo ne change pas la langue.
            Text(
              Strings.menuStart,
              style: const TextStyle(
                fontFamily: 'Bangers',
                fontSize: 20,
                color: ComicPalette.ink,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Bangers',
            fontSize: 20,
            color: ComicPalette.tunisBlue,
          ),
        ),
      );
}

class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color);

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: ComicPalette.ink, width: 3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color.computeLuminance() > 0.5
              ? ComicPalette.ink
              : ComicPalette.paper,
        ),
      ),
    );
  }
}
