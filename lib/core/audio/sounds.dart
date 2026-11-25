import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

/// Effets sonores du jeu (issue #820). Domino : assets/sounds/domino/ ;
/// capture et dé : assets/sounds/common/ ; menu, cartes et pions : leurs dossiers.
enum Sfx {
  place,
  draw,
  pass,
  win,
  lose,
  capture,
  dice,
  uiClick,
  uiOpen,
  cardDeal,
  cardFlip,
  pawnMove,
  pawnHome,
  pawnStep,
}

extension SfxPath on Sfx {
  String get assetPath => switch (this) {
        Sfx.capture => 'assets/sounds/common/capture.wav',
        Sfx.dice => 'assets/sounds/common/dice.wav',
        Sfx.uiClick => 'assets/sounds/menu/ui_click.wav',
        Sfx.uiOpen => 'assets/sounds/menu/ui_open.wav',
        Sfx.cardDeal => 'assets/sounds/cards/card_deal.wav',
        Sfx.cardFlip => 'assets/sounds/cards/card_flip.wav',
        Sfx.pawnMove => 'assets/sounds/ludo/pawn_move.wav',
        Sfx.pawnHome => 'assets/sounds/ludo/pawn_home.wav',
        Sfx.pawnStep => 'assets/sounds/ludo/step.wav',
        _ => 'assets/sounds/domino/$name.wav',
      };
}

/// Effets prévus par jeu (issue #24). Un fichier absent laisse le jeu silencieux, sans erreur bloquante.
const gameSfx = <String, List<Sfx>>{
  'chkobba': [Sfx.place, Sfx.draw, Sfx.cardDeal, Sfx.win, Sfx.lose],
  'coinche': [Sfx.place, Sfx.cardDeal, Sfx.win, Sfx.lose],
  'ludo': [
    Sfx.dice,
    Sfx.pass,
    Sfx.place,
    Sfx.pawnMove,
    Sfx.pawnHome,
    Sfx.pawnStep,
    Sfx.capture,
    Sfx.win,
  ],
  'rami': [Sfx.place, Sfx.draw, Sfx.cardDeal, Sfx.win, Sfx.lose],
  'domino': [Sfx.place, Sfx.draw, Sfx.pass, Sfx.win, Sfx.lose],
};

/// Écart entre deux sons de carte distribuée (issue #938).
const dealGap = Duration(milliseconds: 90);

/// Nombre maximal de sons joués pour une distribution, pour rester court même avec beaucoup de cartes.
const maxDealSounds = 8;

/// Instants (depuis le début de la distribution) où jouer le son d'une carte : un son par carte, plafonné.
List<Duration> dealSoundDelays(int cards, {Duration gap = dealGap}) {
  final count = cards < 0 ? 0 : (cards > maxDealSounds ? maxDealSounds : cards);
  return [for (var i = 0; i < count; i++) gap * i];
}

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

  /// Distribution de [cards] cartes : un son de carte par carte, espacés de [dealGap].
  static void playDeal(int cards) {
    for (final delay in dealSoundDelays(cards)) {
      Timer(delay, () => play(Sfx.cardDeal));
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
