"""Generate the game's short, original weapon sound effects as PCM WAV files."""

import math
import random
import struct
import wave
from pathlib import Path

RATE = 44_100
OUTPUT = Path(__file__).parents[1] / "assets" / "audio" / "weapons"


def envelope(t: float, duration: float, attack: float = 0.01, decay: float = 2.8) -> float:
    return min(t / attack, 1.0) * max(0.0, 1.0 - t / duration) ** decay


def render(name: str, duration: float, tone) -> None:
    rng = random.Random(name)
    samples = []
    for index in range(int(RATE * duration)):
        t = index / RATE
        value = max(-1.0, min(1.0, tone(t, duration, rng)))
        samples.append(struct.pack("<h", int(value * 25_000)))
    OUTPUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as output:
        output.setparams((1, 2, RATE, len(samples), "NONE", "not compressed"))
        output.writeframes(b"".join(samples))


def chirp(start: float, end: float, noise: float = 0.0, pulse: float = 0.0):
    def tone(t, duration, rng):
        phase = math.tau * (start * t + (end - start) * t * t / (2 * duration))
        signal = math.sin(phase) + 0.35 * math.sin(phase * 2.03)
        if pulse:
            signal *= 0.65 + 0.35 * math.sin(math.tau * pulse * t)
        return envelope(t, duration) * (0.42 * signal + noise * rng.uniform(-1, 1))
    return tone


def thud(frequency: float, noise: float = 0.3):
    def tone(t, duration, rng):
        body = math.sin(math.tau * frequency * t * (1.0 - 0.45 * t / duration))
        return envelope(t, duration, 0.004, 3.8) * (0.62 * body + noise * rng.uniform(-1, 1))
    return tone


SOUNDS = {
    "sword_launch": (0.22, chirp(1250, 240, 0.18)),
    "sword_hit": (0.16, thud(190, 0.45)),
    "axe_launch": (0.32, chirp(210, 620, 0.22, 18)),
    "axe_hit": (0.24, thud(92, 0.55)),
    "laser_gun_launch": (0.18, chirp(1900, 520, 0.04)),
    "laser_gun_hit": (0.13, chirp(760, 180, 0.32)),
    "lightning_whip_launch": (0.27, chirp(180, 1650, 0.38, 42)),
    "lightning_whip_hit": (0.20, chirp(1200, 95, 0.48, 55)),
    "bomb_launch": (0.24, chirp(280, 720, 0.08)),
    "bomb_hit": (0.52, thud(58, 0.7)),
    "thunder_orb_book_launch": (0.38, chirp(260, 1050, 0.08, 9)),
    "thunder_orb_book_hit": (0.23, chirp(980, 210, 0.28, 34)),
    "azure_dragon_launch": (0.42, chirp(170, 920, 0.16, 7)),
    "azure_dragon_hit": (0.28, thud(125, 0.48)),
    "nine_treasure_pagoda_launch": (0.52, chirp(420, 1260, 0.03, 6)),
    "nine_treasure_pagoda_hit": (0.38, chirp(880, 360, 0.06, 11)),
}


if __name__ == "__main__":
    for sound_name, (sound_duration, generator) in SOUNDS.items():
        render(sound_name, sound_duration, generator)
    assert len(list(OUTPUT.glob("*.wav"))) == len(SOUNDS)
