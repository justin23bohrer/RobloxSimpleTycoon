#!/usr/bin/env python3
"""Synthesize SimpleTycoon's original Caleb Full Event sound effects.

Plain Python 3 standard library only (wave, math, struct, random). Every
sound is made from scratch here (sine/square-ish tones, pitch sweeps,
filtered noise), so there are no copyright or licensing questions.

Writes 16-bit, 44.1 kHz, mono WAV files to tools/audio/out/:

  caleb_full.wav         big cartoony "boing" + burp-like fanfare hit
  celebration_start.wav  party horn + rising arpeggio + cymbal-ish noise
  caleb_grow.wav         short rising "bloop" (Caleb is fed)
  cookie_rain.wav        soft sparkle/patter that loops cleanly
  trophy_claim.wav       bright "ta-da" chime
  event_end.wav          descending gentle chime

Run:  python3 tools/audio/generate_sfx.py
The output is deterministic (fixed random seed), so re-running gives the
same files. See tools/audio/README.md for uploading them to Roblox.
"""

import math
import os
import random
import struct
import wave

RATE = 44100
PEAK = 0.89  # normalize every file to about -1 dBFS (never clips)
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")

TAU = 2 * math.pi


# Building blocks ------------------------------------------------------------


def silence(seconds):
    return [0.0] * int(seconds * RATE)


def mix_into(dest, src, start_seconds=0.0, gain=1.0):
    """Add src into dest starting at start_seconds (dest grows if needed)."""
    start = int(start_seconds * RATE)
    end = start + len(src)
    if end > len(dest):
        dest.extend([0.0] * (end - len(dest)))
    for i, s in enumerate(src):
        dest[start + i] += s * gain
    return dest


def envelope(n, attack, release, curve=1.0):
    """Linear attack, then a decay to 0 shaped by curve (>1 = faster fall)."""
    a = max(1, int(attack * RATE))
    r = max(1, int(release * RATE))
    env = []
    for i in range(n):
        if i < a:
            v = i / a
        else:
            v = 1.0
        left = n - i
        if left < r:
            v *= (left / r) ** curve
        env.append(v)
    return env


def tone(freq_fn, seconds, harmonics=((1, 1.0),), vibrato=(0.0, 0.0)):
    """A tone whose frequency follows freq_fn(t). harmonics = (mult, amp)."""
    n = int(seconds * RATE)
    vib_rate, vib_depth = vibrato
    phase = 0.0
    out = []
    for i in range(n):
        t = i / RATE
        f = freq_fn(t)
        if vib_depth:
            f *= 1.0 + vib_depth * math.sin(TAU * vib_rate * t)
        phase += TAU * f / RATE
        s = 0.0
        for mult, amp in harmonics:
            s += amp * math.sin(phase * mult)
        out.append(s)
    return out


def apply(samples, env):
    return [s * e for s, e in zip(samples, env)]


def noise(seconds, rng, highpass=0.0, lowpass=1.0):
    """White noise through simple one-pole filters (coefficients 0..1)."""
    n = int(seconds * RATE)
    out = []
    lp = 0.0
    prev_in = 0.0
    hp = 0.0
    for _ in range(n):
        x = rng.uniform(-1.0, 1.0)
        lp += lowpass * (x - lp)
        y = lp
        if highpass:
            hp = highpass * (hp + y - prev_in)
            prev_in = y
            y = hp
        out.append(y)
    return out


def bell(freq, seconds, decay=4.0, bright=1.0):
    """A chime: inharmonic-ish partials with an exponential decay."""
    partials = ((1.0, 1.0), (2.0, 0.45 * bright), (3.01, 0.22 * bright), (4.2, 0.12 * bright))
    n = int(seconds * RATE)
    out = []
    for i in range(n):
        t = i / RATE
        s = 0.0
        for mult, amp in partials:
            s += amp * math.sin(TAU * freq * mult * t) * math.exp(-decay * mult * 0.6 * t)
        attack = min(1.0, i / (0.003 * RATE))
        out.append(s * attack)
    return out


def note(name):
    """'C5' -> Hz (equal temperament, A4 = 440)."""
    names = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    semis = names[name[0]]
    rest = name[1:]
    if rest.startswith("#"):
        semis += 1
        rest = rest[1:]
    elif rest.startswith("b"):
        semis -= 1
        rest = rest[1:]
    octave = int(rest)
    return 440.0 * 2 ** ((semis + (octave - 4) * 12) / 12)


def fade_edges(samples, fade_in=0.004, fade_out=0.02):
    n = len(samples)
    a = int(fade_in * RATE)
    b = int(fade_out * RATE)
    for i in range(min(a, n)):
        samples[i] *= i / a
    for i in range(min(b, n)):
        samples[n - 1 - i] *= i / b
    return samples


def normalize(samples, peak=PEAK):
    top = max(abs(s) for s in samples) or 1.0
    return [s * peak / top for s in samples]


def write_wav(name, samples):
    samples = normalize(samples)
    path = os.path.join(OUT_DIR, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = b"".join(
            struct.pack("<h", max(-32767, min(32767, int(round(s * 32767))))) for s in samples
        )
        w.writeframes(frames)
    print(f"wrote {path} ({len(samples) / RATE:.2f} s)")


# The sounds -----------------------------------------------------------------


def caleb_full(rng):
    """Big cartoony 'boing' + low burp-ish growl, then a brass-ish hit."""
    out = []
    # Boing: a pitch that drops then wobbles, with a springy vibrato.
    boing_len = 0.9

    def boing_freq(t):
        return 90 + 260 * math.exp(-t * 6) + 25 * math.sin(TAU * 11 * t) * math.exp(-t * 3)

    boing = tone(boing_freq, boing_len, harmonics=((1, 1.0), (2, 0.35), (3, 0.15)))
    mix_into(out, apply(boing, envelope(len(boing), 0.005, 0.6, 1.6)), 0.0, 0.8)

    # Burp: a low, rough, slightly falling buzz (amplitude-modulated).
    burp_len = 0.55
    burp = tone(
        lambda t: 75 - 20 * t,
        burp_len,
        harmonics=((1, 1.0), (2, 0.6), (3, 0.4), (4, 0.25), (5, 0.15)),
        vibrato=(23, 0.06),
    )
    rough = noise(burp_len, rng, lowpass=0.08)
    burp = [b * (0.75 + 0.6 * r) for b, r in zip(burp, rough)]
    mix_into(out, apply(burp, envelope(len(burp), 0.03, 0.3, 1.2)), 0.18, 0.55)

    # Fanfare hit: a bright major chord stab (C major) with a little swell.
    chord_len = 1.1
    for name, amp in (("C4", 1.0), ("E4", 0.8), ("G4", 0.8), ("C5", 0.6)):
        f = note(name)
        stab = tone(lambda t, f=f: f, chord_len, harmonics=((1, 1.0), (2, 0.5), (3, 0.3), (4, 0.15)),
                    vibrato=(5.5, 0.004))
        mix_into(out, apply(stab, envelope(len(stab), 0.02, 0.8, 1.5)), 0.55, 0.32 * amp)
    crash = noise(0.8, rng, highpass=0.9, lowpass=0.6)
    mix_into(out, apply(crash, envelope(len(crash), 0.002, 0.75, 2.5)), 0.55, 0.25)
    return fade_edges(out)


def celebration_start(rng):
    """Party horn blat, rising C-major arpeggio, cymbal-ish noise splash."""
    out = []
    # Party horn: a buzzy tone that bends up, with a flutter.
    horn_len = 0.5
    horn = tone(
        lambda t: 330 + 160 * min(1.0, t / 0.15),
        horn_len,
        harmonics=((1, 1.0), (2, 0.7), (3, 0.5), (4, 0.35), (5, 0.25), (6, 0.15)),
        vibrato=(28, 0.02),
    )
    mix_into(out, apply(horn, envelope(len(horn), 0.01, 0.12, 1.0)), 0.0, 0.35)

    # Rising arpeggio: C5 E5 G5 C6 E6 G6.
    step = 0.085
    for i, name in enumerate(("C5", "E5", "G5", "C6", "E6", "G6")):
        b = bell(note(name), 0.7, decay=3.5, bright=0.8)
        mix_into(out, b, 0.35 + i * step, 0.35)

    # Cymbal-ish splash at the top of the arpeggio.
    crash = noise(1.2, rng, highpass=0.92, lowpass=0.7)
    mix_into(out, apply(crash, envelope(len(crash), 0.002, 1.15, 2.8)), 0.35 + 5 * step, 0.3)
    return fade_edges(out)


def caleb_grow(rng):
    """Short rising 'bloop' (a sine sweep with a soft pop)."""
    length = 0.28

    def freq(t):
        x = t / length
        return 220 + 520 * x * x

    b = tone(freq, length, harmonics=((1, 1.0), (2, 0.18)))
    out = apply(b, envelope(len(b), 0.008, 0.12, 1.4))
    return fade_edges(out, 0.003, 0.03)


def cookie_rain(rng):
    """Soft sparkle/patter bed, 3 s, seamless when looped.

    Events are placed on a circular timeline: any tail that runs past the
    end wraps around to the start, so the last sample flows into the first.
    """
    length = 3.0
    n = int(length * RATE)
    out = [0.0] * n

    def add_wrapped(src, start, gain):
        for i, s in enumerate(src):
            out[(start + i) % n] += s * gain

    # Soft patter: short filtered-noise ticks, like little cookies landing.
    for _ in range(52):
        tick = noise(0.035, rng, highpass=0.6, lowpass=0.35)
        tick = apply(tick, envelope(len(tick), 0.001, 0.034, 2.5))
        add_wrapped(tick, rng.randrange(n), rng.uniform(0.15, 0.35))

    # Sparkles: tiny high bells from a pentatonic scale.
    scale = ("C6", "D6", "E6", "G6", "A6", "C7", "D7", "E7")
    for _ in range(20):
        b = bell(note(rng.choice(scale)), 0.45, decay=7.0, bright=0.5)
        add_wrapped(b, rng.randrange(n), rng.uniform(0.12, 0.28))

    # Very quiet airy bed (also wrapped), so the loop never goes fully silent.
    bed = noise(length, rng, highpass=0.97, lowpass=0.15)
    add_wrapped(bed, 0, 0.04)

    # Remove any DC offset so the loop point has no click.
    mean = sum(out) / n
    return [s - mean for s in out]


def trophy_claim(rng):
    """Bright 'ta-da': a short pickup note then a sustained major chord."""
    out = []
    # "ta"
    for name in ("G5", "B5"):
        mix_into(out, bell(note(name), 0.25, decay=6.0), 0.0, 0.4)
    # "da!" (C major, held, with a little shimmer)
    for name, amp in (("C6", 1.0), ("E6", 0.8), ("G6", 0.7), ("C7", 0.45)):
        f = note(name)
        sus = tone(lambda t, f=f: f, 1.3, harmonics=((1, 1.0), (2, 0.3), (3, 0.12)), vibrato=(6, 0.003))
        mix_into(out, apply(sus, envelope(len(sus), 0.01, 1.1, 1.6)), 0.14, 0.18 * amp)
        mix_into(out, bell(f, 1.3, decay=2.5), 0.14, 0.25 * amp)
    sparkle = noise(0.6, rng, highpass=0.95, lowpass=0.6)
    mix_into(out, apply(sparkle, envelope(len(sparkle), 0.002, 0.55, 2.5)), 0.14, 0.12)
    return fade_edges(out)


def event_end(rng):
    """Descending gentle chime: G5 E5 C5 G4, soft and slow."""
    out = []
    for i, name in enumerate(("G5", "E5", "C5", "G4")):
        mix_into(out, bell(note(name), 1.4, decay=2.2, bright=0.5), i * 0.22, 0.35)
    return fade_edges(out, 0.004, 0.15)


SOUNDS = (
    ("caleb_full.wav", caleb_full),
    ("celebration_start.wav", celebration_start),
    ("caleb_grow.wav", caleb_grow),
    ("cookie_rain.wav", cookie_rain),
    ("trophy_claim.wav", trophy_claim),
    ("event_end.wav", event_end),
)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, make in SOUNDS:
        rng = random.Random(f"SimpleTycoon:{name}")  # fixed seed per file
        write_wav(name, make(rng))


if __name__ == "__main__":
    main()
