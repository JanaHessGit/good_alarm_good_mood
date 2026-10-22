"""Builds the alarm sounds in assets/: three 20-second intros (chime,
marimba, soft piano), each followed by an upbeat, original wake-up tune
("Sunny Side Up"), plus a classic beep. All synthesized here, free to use.

Run:  python3 tools/make_alarm_sound.py              (built-in tune)
      python3 tools/make_alarm_sound.py my_song.mp3  (your own song after the chime)
Needs numpy, plus ffmpeg for MP3 output and for using your own song.
Keep CHIME_SECONDS in sync with SettingsStore.songAfterSeconds.
"""
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

SR = 32000
CHIME_SECONDS = 20
BPM = 116
BEAT = 60 / BPM
rng = np.random.default_rng(7)


def note_hz(n):  # MIDI note number -> Hz
    return 440.0 * 2 ** ((n - 69) / 12)


def env(n, attack=0.005, decay=3.0):
    t = np.arange(n) / SR
    a = np.minimum(1, t / max(attack, 1e-4))
    return a * np.exp(-decay * t)


def tone(freq, dur, kind='epiano', decay=3.0, vol=1.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    if kind == 'epiano':
        w = np.sin(2 * np.pi * freq * t) + 0.35 * np.sin(2 * np.pi * 2 * freq * t) \
            + 0.12 * np.sin(2 * np.pi * 3 * freq * t + 0.3)
    elif kind == 'bass':
        w = np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(2 * np.pi * 2 * freq * t)
    elif kind == 'lead':
        vib = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * t) * np.minimum(1, t / 0.15)
        ph = 2 * np.pi * freq * np.cumsum(vib) / SR
        w = (2 / np.pi) * np.arcsin(np.sin(ph)) + 0.2 * np.sin(2 * ph)  # soft triangle
    elif kind == 'bell':
        w = np.sin(2 * np.pi * freq * t) + 0.4 * np.sin(2 * np.pi * 2.76 * freq * t)
    else:
        raise ValueError(kind)
    return vol * w * env(n, decay=decay)


def add(buf, start_s, sig):
    i = int(start_s * SR)
    j = min(len(buf), i + len(sig))
    if i < len(buf):
        buf[i:j] += sig[: j - i]


# ---------------------------------------------------------------- chime
def chime_part():
    buf = np.zeros(int(CHIME_SECONDS * SR))
    pattern = [72, 76, 79, 84]  # C E G C, the original Dawnbox chime
    t = 0.0
    while t < CHIME_SECONDS - 2.6:
        for k, n in enumerate(pattern):
            add(buf, t + k * 0.45, tone(note_hz(n), 1.6, 'bell', decay=3.5, vol=0.55))
        t += 2.8
    # last second fades so the song can take over
    fade = np.linspace(1, 0, SR)
    buf[-SR:] *= fade
    return buf


def marimba_part():
    """Bright marimba arpeggios that climb a little every bar."""
    buf = np.zeros(int(CHIME_SECONDS * SR))
    step = 60 / 132 / 2
    seq = [72, 76, 79, 76, 74, 77, 81, 77, 76, 79, 84, 79, 74, 77, 79, 83]
    t, i = 0.0, 0
    while t < CHIME_SECONDS - 1.0:
        n = seq[i % len(seq)] + (12 if (i // 32) % 2 else 0)
        add(buf, t, tone(note_hz(n), 0.5, 'bell', decay=9, vol=0.5))
        add(buf, t, tone(note_hz(n - 12), 0.4, 'epiano', decay=10, vol=0.15))
        t += step
        i += 1
    buf[-SR:] *= np.linspace(1, 0, SR)
    return buf


def piano_part():
    """Slow, soft piano chords that get gradually louder."""
    buf = np.zeros(int(CHIME_SECONDS * SR))
    prog = [[60, 64, 67, 72], [57, 60, 64, 69], [53, 57, 60, 65], [55, 59, 62, 67]]
    t, k = 0.0, 0
    while t < CHIME_SECONDS - 1.5:
        chord = prog[k % 4]
        level = 0.25 + 0.6 * t / CHIME_SECONDS
        for j, n in enumerate(chord):  # rolled chord
            add(buf, t + j * 0.12, tone(note_hz(n), 3.0, 'epiano', decay=1.2, vol=0.3 * level))
        t += 2.4
        k += 1
    buf[-SR:] *= np.linspace(1, 0, SR)
    return buf


def beep_full(seconds=60):
    """Classic digital alarm: beep-beep-beep-beep, pause. For deep sleepers."""
    buf = np.zeros(int(seconds * SR))
    t = 0.0
    while t < seconds - 1:
        for k in range(4):
            n = int(0.09 * SR)
            tt = np.arange(n) / SR
            beep = np.sign(np.sin(2 * np.pi * 2048 * tt)) * 0.6 + np.sin(2 * np.pi * 4096 * tt) * 0.2
            beep *= np.minimum(1, np.minimum(tt / 0.003, (0.09 - tt) / 0.003))
            add(buf, t + k * 0.16, beep)
        t += 1.0
    return buf


# ---------------------------------------------------------------- song
CHORDS = {  # MIDI notes, around middle C
    'C': [60, 64, 67], 'G': [59, 62, 67], 'Am': [57, 60, 64], 'F': [57, 60, 65],
    'Dm': [57, 62, 65], 'Em': [59, 64, 67],
}
ROOT = {'C': 36, 'G': 43, 'Am': 45, 'F': 41, 'Dm': 38, 'Em': 40}

VERSE = ['C', 'G', 'Am', 'F'] * 2
CHORUS = ['F', 'G', 'Em', 'Am', 'F', 'G', 'C', 'C']

# melody: (beat offset within bar, MIDI note, length in beats)
MEL_A = [
    [(0, 72, 1), (1, 74, .5), (1.5, 76, 1.5), (3, 79, 1)],
    [(0, 79, 1.5), (1.5, 77, .5), (2, 76, 1), (3, 74, 1)],
    [(0, 76, 1), (1, 72, 1), (2, 69, 1.5), (3.5, 72, .5)],
    [(0, 74, 2), (2, 72, 1), (3, 69, 1)],
]
MEL_B = [
    [(0, 81, 1), (1, 79, 1), (2, 77, 1), (3, 76, 1)],
    [(0, 74, 1.5), (1.5, 76, .5), (2, 79, 2)],
    [(0, 79, 1), (1, 81, .5), (1.5, 79, .5), (2, 76, 2)],
    [(0, 72, 1), (1, 74, 1), (2, 76, 1), (3, 77, 1)],
    [(0, 81, 1.5), (1.5, 79, .5), (2, 77, 1), (3, 76, 1)],
    [(0, 74, 1), (1, 76, 1), (2, 79, 2)],
    [(0, 84, 2), (2, 79, 1), (3, 76, 1)],
    [(0, 72, 3)],
]


def kick(dur=0.35):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = 110 * np.exp(-18 * t) + 45
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-9 * t)


def noise_hit(dur, decay, hp=True, vol=1.0):
    n = int(dur * SR)
    w = rng.standard_normal(n)
    if hp:  # crude high-pass: difference of samples
        w = np.diff(w, prepend=0)
    return vol * w * np.exp(-decay * np.arange(n) / SR)


def smooth(x, k):
    """Simple low-pass (moving average) to take the harsh edge off noise."""
    return np.convolve(x, np.ones(k) / k, mode='same')


def song_part():
    bars = VERSE + CHORUS + VERSE + CHORUS
    total = len(bars) * 4 * BEAT + 2.0
    buf = np.zeros(int(total * SR))
    for b, name in enumerate(bars):
        bar_t = b * 4 * BEAT
        section = (b // 8) % 2  # 0 verse, 1 chorus
        # chords: offbeat "skank" stabs keep it bouncy
        for beat in range(4):
            for off in (0.5,) if section == 0 else (0, 0.5):
                for n in CHORDS[name]:
                    add(buf, bar_t + (beat + off) * BEAT, tone(note_hz(n), 0.5, 'epiano', decay=7, vol=0.16))
        # bass: root on 1, octave on 2.5, fifth on 3
        r = ROOT[name]
        for off, n in ((0, r), (1.5, r + 12), (2, r + 7), (3, r)):
            add(buf, bar_t + off * BEAT, tone(note_hz(n), BEAT * 0.9, 'bass', decay=2.5, vol=0.42))
        # drums
        for beat in range(4):
            add(buf, bar_t + beat * BEAT, kick() * (0.75 if beat in (0, 2) else 0.35))
            if beat in (1, 3):
                add(buf, bar_t + beat * BEAT, smooth(noise_hit(0.15, 28, vol=0.07), 4))
            for e in (0, 0.5):
                add(buf, bar_t + (beat + e) * BEAT, smooth(noise_hit(0.04, 120, vol=0.02), 2))
        # melody
        mel = MEL_A[b % 4] if section == 0 else MEL_B[b % 8]
        for off, n, ln in mel:
            add(buf, bar_t + off * BEAT, tone(note_hz(n), ln * BEAT + 0.2, 'lead', decay=1.6, vol=0.26))
            if section == 1:  # sparkle an octave up in the chorus
                add(buf, bar_t + off * BEAT, tone(note_hz(n + 12), 0.6, 'bell', decay=6, vol=0.05))
    buf = smooth(buf, 3)  # soften the very top end of the whole mix
    # gentle fade in and out so the loop back to the chime is smooth
    fi = int(0.4 * SR)
    buf[:fi] *= np.linspace(0, 1, fi)
    fo = int(2.0 * SR)
    buf[-fo:] *= np.linspace(1, 0, fo)
    return buf


def soft_limit(x):
    x = x / (np.max(np.abs(x)) + 1e-9)
    return np.tanh(1.6 * x) / np.tanh(1.6)


def load_song(path):
    """Decodes any audio file to mono float samples with ffmpeg."""
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', path, '-f', 's16le', '-ac', '1', '-ar', str(SR), '-'],
        check=True, capture_output=True,
    ).stdout
    return np.frombuffer(raw, dtype='<i2').astype(np.float64) / 32768


def write_mp3(audio, path):
    pcm = (np.clip(audio, -1, 1) * 32000).astype('<i2')
    wav = path.with_suffix('.wav')
    with wave.open(str(wav), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(wav), '-b:a', '128k', str(path)], check=True)
    wav.unlink()
    print(f'{path.name}: {len(audio) / SR:.1f} s')


def main():
    assets = Path(__file__).resolve().parent.parent / 'assets'
    if len(sys.argv) > 1:
        song = load_song(sys.argv[1])
        song = song / (np.max(np.abs(song)) + 1e-9) * 0.9
    else:
        song = soft_limit(song_part()) * 0.85
    # 20 s intro, then the wake-up song (keep names in sync with AlarmSound)
    for name, intro in (('chime', chime_part), ('marimba', marimba_part), ('piano', piano_part)):
        write_mp3(np.concatenate([soft_limit(intro()) * 0.8, song]), assets / f'alarm_{name}.mp3')
    # no song: a plain, insistent beep
    write_mp3(soft_limit(beep_full()) * 0.7, assets / 'alarm_beep.mp3')


if __name__ == '__main__':
    main()
