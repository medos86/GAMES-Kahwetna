import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Effets sonores du jeu. Pose, pioche, passe, victoire et défaite sont dans assets/sounds/domino/ ;
/// capture et dé sont dans assets/sounds/common/.
enum Sfx { place, draw, pass, win, lose, capture, dice }

extension SfxPath on Sfx {
  String get assetPath => switch (this) {
    Sfx.capture || Sfx.dice => 'assets/sounds/common/$name.wav',
    _ => 'assets/sounds/domino/$name.wav',
  };
}

/// Effets prévus par jeu (issue #24). Un fichier absent laisse le jeu silencieux, sans erreur bloquante.
const gameSfx = <String, List<Sfx>>{
  'chkobba': [Sfx.place, Sfx.draw, Sfx.win, Sfx.lose],
  'coinche': [Sfx.place, Sfx.win, Sfx.lose],
  'ludo': [Sfx.dice, Sfx.place, Sfx.capture, Sfx.win],
  'rami': [Sfx.place, Sfx.draw, Sfx.win, Sfx.lose],
  'domino': [Sfx.place, Sfx.draw, Sfx.pass, Sfx.win, Sfx.lose],
};

/// Lecture avec flutter_soloud : le moteur audio tourne en natif, sur son propre fil, donc peu de latence.
/// Les sons sont chargés une fois au démarrage. Si un fichier manque ou que l'audio est indisponible,
/// le jeu reste silencieux et l'erreur s'affiche dans la console.
class Sounds {
  Sounds._();

  static final Map<Sfx, AudioSource> _sources = {};
  static bool _ready = false;

  static Future<void> preload() async {
    try {
      if (!_ready) {
        // Tampon court : moins de latence entre la pose et le son (512 échantillons ≈ 12 ms à 44,1 kHz).
        await SoLoud.instance.init(sampleRate: 44100, bufferSize: 512);
        _ready = true;
      }
      for (final sfx in Sfx.values) {
        if (_sources.containsKey(sfx)) continue;
        try {
          _sources[sfx] = await SoLoud.instance.loadAsset(sfx.assetPath);
        } catch (e) {
          debugPrint('Préchargement ${sfx.name} : $e');
        }
      }
    } catch (e) {
      debugPrint('Audio indisponible : $e');
    }
  }

  static Future<void> play(Sfx sfx) async {
    try {
      if (!_ready) await preload();
      final source = _sources[sfx];
      if (source == null) return;
      SoLoud.instance.play(source);
    } catch (e) {
      debugPrint('Son ${sfx.name} : $e');
    }
  }
}
