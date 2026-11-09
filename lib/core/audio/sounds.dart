import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Effets sonores du jeu. Les fichiers sont dans assets/sounds/domino/ (place.wav, draw.wav, pass.wav, win.wav, lose.wav).
enum Sfx { place, draw, pass, win, lose }

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
          _sources[sfx] = await SoLoud.instance.loadAsset('assets/sounds/domino/${sfx.name}.wav');
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
