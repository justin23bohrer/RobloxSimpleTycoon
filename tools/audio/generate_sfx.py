#!/usr/bin/env python3
"""Synthesize SimpleTycoon's original Caleb Full Event / Cookie Party audio.

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

Cookie Party (Config.CookiePartySounds):

  party_music.wav        upbeat chiptune loop, 120 BPM, 4 bars (8 s), seamless
  collect_pop.wav        tiny bubbly pop (Normal / Chocolate cookie)
  collect_golden.wav     bright two-note chime + sparkle (Golden cookie)
  collect_giant.wav      thump + fast rising arpeggio + splash (Giant cookie)
  countdown_tick.wav     short woodblock tick (pitched up per second in game)
  finale_boom.wav        huge boom: sub drop, rumble, crack, crash, chord stab
  caleb_laugh.wav        cartoony "ha-ha-ha-ha" (voiced syllables, falling)
  caleb_spit.wav         "ptoo" pop + airy whoosh (Caleb throws a cookie)

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


# Cookie Party ---------------------------------------------------------------


def swept_noise(seconds, rng, lowpass_fn, highpass=0.0):
    """Noise through a one-pole lowpass whose coefficient follows lowpass_fn(t)."""
    n = int(seconds * RATE)
    out = []
    lp = 0.0
    prev_in = 0.0
    hp = 0.0
    for i in range(n):
        x = rng.uniform(-1.0, 1.0)
        lp += lowpass_fn(i / RATE) * (x - lp)
        y = lp
        if highpass:
            hp = highpass * (hp + y - prev_in)
            prev_in = y
            y = hp
        out.append(y)
    return out


def kick(seconds=0.28):
    k = tone(lambda t: 45 + 110 * math.exp(-t * 28), seconds, harmonics=((1, 1.0), (2, 0.12)))
    return apply(k, envelope(len(k), 0.001, seconds * 0.9, 2.0))


SQUARE = ((1, 1.0), (3, 0.33), (5, 0.2), (7, 0.14))  # chiptune-ish
BASS = ((1, 1.0), (2, 0.5), (3, 0.3), (4, 0.18))


def party_music(rng):
    """Upbeat chiptune loop: 120 BPM, 4 bars of C - G - Am - F (8 s).

    Like cookie_rain, every note is placed on a circular timeline, so tails
    that run past the end wrap to the start and the loop has no seam.
    """
    beat = 0.5  # 120 BPM
    bars = (
        ("C3", ("C5", "E5", "G5", "C6"), ("E5", "G5", "C6", "G5")),
        ("G2", ("B4", "D5", "G5", "B5"), ("D5", "G5", "B5", "G5")),
        ("A2", ("C5", "E5", "A5", "C6"), ("C5", "E5", "A5", "E5")),
        ("F2", ("C5", "F5", "A5", "C6"), ("C5", "F5", "A5", "C6")),
    )
    length = beat * 4 * len(bars)
    n = int(length * RATE)
    out = [0.0] * n

    def add(src, at, gain):
        start = int(at * RATE)
        for i, s in enumerate(src):
            out[(start + i) % n] += s * gain

    kick_sound = kick()
    for bar, (root, arp, melody) in enumerate(bars):
        bar_start = bar * 4 * beat
        root_hz = note(root)
        for b in range(4):
            t = bar_start + b * beat
            add(kick_sound, t, 0.9)
            # Clap on beats 2 and 4.
            if b % 2 == 1:
                clap = noise(0.16, rng, highpass=0.75, lowpass=0.55)
                add(apply(clap, envelope(len(clap), 0.002, 0.15, 2.2)), t, 0.35)
            # Melody: one bell per beat.
            add(bell(note(melody[b]), 0.45, decay=5.0, bright=0.7), t, 0.22)
        for e in range(8):
            t = bar_start + e * beat / 2
            # Bass: octave bounce on 8th notes.
            f = root_hz * (2 if e % 2 else 1)
            bass = tone(lambda _t, f=f: f, beat / 2 * 0.9, harmonics=BASS)
            add(apply(bass, envelope(len(bass), 0.004, 0.1, 1.5)), t, 0.32)
            # Hi-hat on every 8th (off-beats a bit louder).
            hat = noise(0.045, rng, highpass=0.95, lowpass=0.9)
            add(apply(hat, envelope(len(hat), 0.001, 0.04, 3.0)), t, 0.12 if e % 2 == 0 else 0.2)
        for x in range(16):
            # Chip arpeggio on 16th notes, quiet.
            f = note(arp[x % 4])
            chip = tone(lambda _t, f=f: f, beat / 4 * 0.8, harmonics=SQUARE)
            add(apply(chip, envelope(len(chip), 0.003, 0.05, 1.5)), bar_start + x * beat / 4, 0.07)

    mean = sum(out) / n
    return [s - mean for s in out]


def collect_pop(rng):
    """Tiny bubbly pop: a fast upward sine blip with a little sparkle."""
    out = []
    blip = tone(lambda t: 480 + 650 * min(1.0, t / 0.07), 0.09, harmonics=((1, 1.0), (2, 0.2)))
    mix_into(out, apply(blip, envelope(len(blip), 0.002, 0.06, 1.6)), 0.0, 0.8)
    mix_into(out, bell(note("C7"), 0.18, decay=14.0, bright=0.4), 0.03, 0.25)
    return fade_edges(out, 0.002, 0.02)


def collect_golden(rng):
    """Bright two-note chime (E6 -> B6) with a high sparkle on top."""
    out = []
    mix_into(out, bell(note("E6"), 0.7, decay=4.0), 0.0, 0.45)
    mix_into(out, bell(note("B6"), 0.8, decay=3.5), 0.07, 0.45)
    mix_into(out, bell(note("E7"), 0.5, decay=6.0, bright=0.5), 0.14, 0.2)
    sparkle = noise(0.5, rng, highpass=0.96, lowpass=0.7)
    mix_into(out, apply(sparkle, envelope(len(sparkle), 0.002, 0.45, 2.5)), 0.05, 0.12)
    return fade_edges(out, 0.002, 0.1)


def collect_giant(rng):
    """Big score: a low thump, a fast rising arpeggio, then a splash."""
    out = []
    mix_into(out, kick(0.4), 0.0, 0.8)
    for i, name in enumerate(("C5", "E5", "G5", "C6", "E6", "G6", "C7")):
        mix_into(out, bell(note(name), 0.6, decay=4.0, bright=0.8), 0.04 + i * 0.045, 0.3)
    crash = noise(0.9, rng, highpass=0.92, lowpass=0.7)
    mix_into(out, apply(crash, envelope(len(crash), 0.002, 0.85, 2.6)), 0.32, 0.25)
    return fade_edges(out, 0.002, 0.1)


def countdown_tick(rng):
    """Short woodblock tick (the game raises its pitch each second)."""
    out = []
    block = bell(880, 0.16, decay=22.0, bright=0.6)
    mix_into(out, block, 0.0, 0.8)
    click = noise(0.012, rng, highpass=0.7, lowpass=0.8)
    mix_into(out, apply(click, envelope(len(click), 0.0005, 0.011, 2.0)), 0.0, 0.4)
    return fade_edges(out, 0.001, 0.02)


def finale_boom(rng):
    """The finale: sub drop + rumble + crack + crash + a big major chord."""
    out = []
    sub = tone(lambda t: 30 + 90 * math.exp(-t * 4), 2.0, harmonics=((1, 1.0), (2, 0.25)))
    mix_into(out, apply(sub, envelope(len(sub), 0.003, 1.9, 1.8)), 0.0, 1.0)
    rumble = noise(1.8, rng, lowpass=0.05)
    mix_into(out, apply(rumble, envelope(len(rumble), 0.005, 1.7, 2.0)), 0.0, 1.4)
    crack = noise(0.06, rng, highpass=0.6, lowpass=0.9)
    mix_into(out, apply(crack, envelope(len(crack), 0.0005, 0.055, 2.0)), 0.0, 0.6)
    crash = noise(2.2, rng, highpass=0.93, lowpass=0.65)
    mix_into(out, apply(crash, envelope(len(crash), 0.002, 2.1, 2.8)), 0.02, 0.35)
    for name, amp in (("C4", 1.0), ("G4", 0.8), ("C5", 0.8), ("E5", 0.7), ("G5", 0.5)):
        f = note(name)
        stab = tone(lambda t, f=f: f, 1.6, harmonics=((1, 1.0), (2, 0.5), (3, 0.3), (4, 0.15)), vibrato=(5.5, 0.004))
        mix_into(out, apply(stab, envelope(len(stab), 0.01, 1.3, 1.6)), 0.05, 0.16 * amp)
    for i, name in enumerate(("C7", "G6", "E6", "C6")):
        mix_into(out, bell(note(name), 0.8, decay=3.5, bright=0.5), 0.15 + i * 0.09, 0.12)
    return fade_edges(out, 0.001, 0.3)


def caleb_laugh(rng):
    """Cartoony 'ha-ha-ha-ha-ha': voiced syllables that fall in pitch."""
    out = []
    vowel = ((1, 0.6), (2, 1.0), (3, 0.8), (4, 0.45), (5, 0.25), (6, 0.12))
    for i in range(5):
        start = i * 0.17
        f0 = 300 - i * 18
        syl = tone(lambda t, f0=f0: f0 * (1.05 - 0.6 * t), 0.13, harmonics=vowel, vibrato=(9, 0.015))
        mix_into(out, apply(syl, envelope(len(syl), 0.015, 0.09, 1.4)), start + 0.02, 0.3)
        breath = noise(0.05, rng, highpass=0.5, lowpass=0.4)
        mix_into(out, apply(breath, envelope(len(breath), 0.005, 0.04, 1.5)), start, 0.25)
    return fade_edges(out, 0.003, 0.05)


def caleb_spit(rng):
    """'Ptoo': a lip pop, then an airy whoosh that sweeps up and away."""
    out = []
    pop = tone(lambda t: 60 + 140 * math.exp(-t * 40), 0.07, harmonics=((1, 1.0), (2, 0.3)))
    mix_into(out, apply(pop, envelope(len(pop), 0.001, 0.06, 1.8)), 0.0, 0.7)
    click = noise(0.01, rng, highpass=0.6, lowpass=0.9)
    mix_into(out, apply(click, envelope(len(click), 0.0005, 0.009, 2.0)), 0.0, 0.4)
    whoosh_len = 0.5
    whoosh = swept_noise(whoosh_len, rng, lambda t: 0.04 + 0.5 * math.sin(math.pi * t / whoosh_len) ** 2, highpass=0.8)
    whoosh_env = [math.sin(math.pi * i / len(whoosh)) ** 1.5 for i in range(len(whoosh))]
    mix_into(out, apply(whoosh, whoosh_env), 0.04, 0.8)
    return fade_edges(out, 0.001, 0.05)


SOUNDS = (
    ("caleb_full.wav", caleb_full),
    ("celebration_start.wav", celebration_start),
    ("caleb_grow.wav", caleb_grow),
    ("cookie_rain.wav", cookie_rain),
    ("trophy_claim.wav", trophy_claim),
    ("event_end.wav", event_end),
    ("party_music.wav", party_music),
    ("collect_pop.wav", collect_pop),
    ("collect_golden.wav", collect_golden),
    ("collect_giant.wav", collect_giant),
    ("countdown_tick.wav", countdown_tick),
    ("finale_boom.wav", finale_boom),
    ("caleb_laugh.wav", caleb_laugh),
    ("caleb_spit.wav", caleb_spit),
)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for name, make in SOUNDS:
        rng = random.Random(f"SimpleTycoon:{name}")  # fixed seed per file
        write_wav(name, make(rng))


if __name__ == "__main__":
    main()
