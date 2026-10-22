"""Builds assets/quiz_wait.mp3: light "thinking" music that loops while a
quiz or riddle waits for an answer. Original, synthesized here, free to use.

Run:  python3 tools/make_quiz_music.py
Needs numpy and ffmpeg. Uses the helpers of make_alarm_sound.py.
"""
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from make_alarm_sound import SR, add, note_hz, noise_hit, smooth, tone, write_mp3  # noqa: E402

BPM = 96
BEAT = 60 / BPM
BARS = 8  # 8 bars at 96 BPM = 20 seconds, one full loop

# Playful minor progression: Am  F  C  E | Am  F  Dm  E
CHORDS = [
    [57, 60, 64], [53, 57, 60], [55, 60, 64], [56, 59, 64],
    [57, 60, 64], [53, 57, 60], [57, 62, 65], [56, 59, 64],
]
BASS = [45, 41, 48, 40, 45, 41, 38, 40]

# Pizzicato-style "hmm, let me think" motif, (beat, note, length in beats).
MOTIF = [
    [(0, 69, .5), (1, 72, .5), (2, 76, .5), (3, 74, .5)],
    [(0, 72, .5), (1, 69, .5), (2.5, 72, .5), (3, 69, .5)],
    [(0, 67, .5), (1, 72, .5), (2, 76, .5), (3, 79, .5)],
    [(0, 76, 1), (2, 71, .5), (2.5, 68, .5), (3, 71, .5)],
    [(0, 69, .5), (1, 72, .5), (2, 76, .5), (3, 74, .5)],
    [(0, 72, .5), (1, 69, .5), (2.5, 72, .5), (3, 77, .5)],
    [(0, 74, .5), (1, 77, .5), (2, 81, .5), (3, 77, .5)],
    [(0, 76, 1.5), (2, 71, .5), (3, 68, .5)],
]


def quiz_loop():
    length = int(BARS * 4 * BEAT * SR)
    buf = np.zeros(length + 3 * SR)  # tail room, folded back below
    for b in range(BARS):
        t0 = b * 4 * BEAT
        # soft plucked chords on beats 2 and 4
        for beat in (1, 3):
            for n in CHORDS[b]:
                add(buf, t0 + beat * BEAT, tone(note_hz(n), 0.4, 'epiano', decay=9, vol=0.10))
        # walking bass, staccato
        r = BASS[b]
        for beat, n in ((0, r), (1, r + 7), (2, r + 12), (3, r + 7)):
            add(buf, t0 + beat * BEAT, tone(note_hz(n), 0.35, 'bass', decay=8, vol=0.36))
        # clock tick on every 8th, tock on the beat
        for e in range(8):
            vol = 0.035 if e % 2 == 0 else 0.02
            add(buf, t0 + e * BEAT / 2, smooth(noise_hit(0.03, 160, vol=vol), 3))
        # the motif, plucked
        for beat, n, ln in MOTIF[b]:
            add(buf, t0 + beat * BEAT, tone(note_hz(n), ln * BEAT + 0.15, 'bell', decay=7, vol=0.16))
    # fold the ringing tail back onto the start, so the loop is seamless
    tail = buf[length:]
    buf = buf[:length]
    buf[: len(tail)] += tail
    buf = smooth(buf, 3)
    return buf / (np.max(np.abs(buf)) + 1e-9) * 0.7


def main():
    assets = Path(__file__).resolve().parent.parent / 'assets'
    write_mp3(quiz_loop(), assets / 'quiz_wait.mp3')


if __name__ == '__main__':
    main()
