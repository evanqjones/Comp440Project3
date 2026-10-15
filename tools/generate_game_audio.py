"""Original procedural game audio. Python standard library; no samples/downloads.

Run from any directory: python tools/generate_game_audio.py
Output: 22,050 Hz mono signed 16-bit PCM WAV, suitable for Godot desktop/Web.
SPDX-License-Identifier: CC0-1.0 (generated WAV assets; see assets/audio/README.md)
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
TAU = 2 * math.pi
OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio"


def write(name, seconds, sample, peak=0.6, loop=False):
    values = [sample(i / RATE) for i in range(round(seconds * RATE))]
    if not loop:
        for i in range(len(values)):
            values[i] *= min(1, i / 100, (len(values) - 1 - i) / 200)
    maximum = max(abs(v) for v in values) or 1
    data = b"".join(struct.pack("<h", round(v / maximum * peak * 32767)) for v in values)
    with wave.open(str(OUTPUT / (name + ".wav")), "wb") as wav:
        wav.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        wav.writeframes(data)
    print(name, len(data), "PCM bytes")


def impact(seed, heavy=False):
    rng = random.Random(seed)
    filtered = 0.0

    def sample(t):
        nonlocal filtered
        filtered = 0.65 * filtered + 0.35 * rng.uniform(-1, 1)
        heel = math.sin(TAU * (78 if heavy else 114) * t) * math.exp(-t * 35)
        sole = filtered * math.exp(-t * 23) * (1 - math.exp(-t * 140))
        toe = filtered * math.exp(-((t - 0.075) / 0.027) ** 2) * 0.28
        return heel * (0.65 if heavy else 0.38) + sole * 0.7 + toe

    return sample


def door():
    rng = random.Random(4403)
    filtered = 0.0

    def sample(t):
        nonlocal filtered
        filtered = filtered * 0.88 + rng.uniform(-1, 1) * 0.12
        swing = math.sin(math.pi * min(t / 0.62, 1)) * filtered * 0.8
        hinge = math.sin(TAU * (245 * t + 14 * t * t)) * math.sin(math.pi * min(t / 0.7, 1)) * 0.12
        latch = math.exp(-t * 70) * (filtered + math.sin(TAU * 170 * t)) * 0.7
        return swing + hinge + latch

    return sample


def pickup(t):
    return sum(math.sin(TAU * hz * max(0, t - delay)) * math.exp(-max(0, t - delay) * 9)
               for hz, delay in ((660, 0), (990, 0.075), (1320, 0.15)) if t >= delay)


def bell(t):
    # Metallic, mildly inharmonic school bell with a mechanical strike train.
    result = 0
    for delay in (0, 0.12, 0.24, 0.36, 0.48, 0.60):
        age = t - delay
        if age >= 0:
            for hz, gain, decay in ((832, 1, 3.2), (1198, 0.45, 4), (1664, 0.25, 5), (2341, 0.12, 7)):
                result += gain * math.sin(TAU * hz * age) * math.exp(-age * decay)
    return result


def ambience(chase=False):
    # Frequencies are integer multiples of 1/8 Hz: sample-perfect periodic loops.
    rng = random.Random(4405 if chase else 4404)
    partials = [(rng.randint(480, 4200) / 8, rng.random() * TAU, rng.uniform(0.003, 0.012))
                for _ in range(36)]

    def sample(t):
        air = sum(gain * math.sin(TAU * hz * t + phase) for hz, phase, gain in partials)
        if chase:
            pulse = 0.72 + 0.28 * math.sin(TAU * 0.75 * t)
            return pulse * (0.42 * math.sin(TAU * 43 * t) + 0.28 * math.sin(TAU * 43.125 * t)
                            + 0.15 * math.sin(TAU * 58.25 * t)) + air * 0.5
        return 0.18 * math.sin(TAU * 50 * t) + 0.08 * math.sin(TAU * 100 * t) + air

    return sample


def capture():
    rng = random.Random(4406)

    def sample(t):
        noise = rng.uniform(-1, 1) * math.exp(-t * 19)
        fall = math.sin(TAU * (180 * t - 80 * t * t)) * math.exp(-t * 8)
        metal = math.sin(TAU * 1273 * t) * math.exp(-t * 22) * 0.2
        return noise * 0.4 + fall * 0.7 + metal

    return sample


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    write("footstep_walk", 0.24, impact(4401), 0.55)
    write("footstep_sprint", 0.30, impact(4402, True), 0.65)
    write("door_open", 0.78, door(), 0.6)
    write("item_pickup", 0.65, pickup, 0.45)
    write("school_bell", 2.4, bell, 0.6)
    write("school_ambience", 8, ambience(), 0.4, loop=True)
    write("chase_tension", 8, ambience(True), 0.5, loop=True)
    write("capture_hit", 0.7, capture(), 0.65)


if __name__ == "__main__":
    main()
