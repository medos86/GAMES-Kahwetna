"""Génère les sons de remplacement de l'issue #820 (WAV 44,1 kHz, mono, 16 bits).

Ces fichiers sont synthétisés par ce script (aucune source tierce) : ils sont remplaçables
par des sons CC0 (Kenney Casino Audio / UI Audio) en gardant les mêmes noms et durées max.
Usage : python3 tool/gen_placeholder_sounds.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
ROOT = Path(__file__).resolve().parent.parent / "assets" / "sounds"
random.seed(820)


def write(path: Path, samples: list[float]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 0.8 * 32767)) for s in samples)
        w.writeframes(frames)


def tone(freq_fn, seconds: float, decay: float, noise: float = 0.0) -> list[float]:
    n = int(seconds * RATE)
    out, phase = [], 0.0
    for i in range(n):
        t = i / RATE
        phase += 2 * math.pi * freq_fn(t) / RATE
        env = math.exp(-decay * t)
        out.append(env * ((1 - noise) * math.sin(phase) + noise * random.uniform(-1, 1)))
    return out


def fade_edges(s: list[float], ms: float = 4) -> list[float]:
    k = int(RATE * ms / 1000)
    for i in range(min(k, len(s))):
        s[i] *= i / k
        s[-1 - i] *= i / k
    return s


SOUNDS = {
    "menu/ui_click.wav": lambda: tone(lambda t: 1800, 0.12, 40),
    "menu/ui_open.wav": lambda: tone(lambda t: 600 + 300 * t / 0.3, 0.3, 8),
    "cards/card_deal.wav": lambda: tone(lambda t: 2400, 0.5, 14, noise=0.85),
    "cards/card_flip.wav": lambda: tone(lambda t: 3000, 0.25, 22, noise=0.9),
    "ludo/pawn_move.wav": lambda: tone(lambda t: 420, 0.2, 18),
    "ludo/pawn_home.wav": lambda: tone(
        lambda t: [523, 659, 784][min(2, int(t / 0.2))], 0.8, 3),
    "common/capture.wav": lambda: tone(lambda t: 800 - 600 * min(t, 0.8) / 0.8, 0.8, 4, noise=0.2),
    "common/dice.wav": lambda: [
        s * (1.0 if random.random() > 0.15 else 0.2)
        for s in tone(lambda t: 1200, 1.2, 2.5, noise=0.95)
    ],
}

if __name__ == "__main__":
    for rel, make in SOUNDS.items():
        write(ROOT / rel, fade_edges(make()))
        print("écrit", rel)
