"""배경음 합성 (몽환적인 밤 숲 패드 + 종소리). python3 tool/gen_bgm.py → assets/audio/bgm_home.wav, bgm_game.wav
실제 작곡 음원이 생기면 같은 이름으로 덮어쓰면 된다 (.ogg 로 바꾸면 lib/app/sfx.dart 의 _bgmExt 만 수정)."""
import math, os, random, struct, wave
SR = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')

def note(n):  # MIDI → Hz
    return 440 * 2 ** ((n - 69) / 12)

def render(name, chords, bpm, bars_per_chord, bell_density, seed, vol=0.32):
    random.seed(seed)
    beat = 60 / bpm
    chord_len = beat * 4 * bars_per_chord
    total = chord_len * len(chords)
    n = int(SR * total)
    buf = [0.0] * n
    # 패드: 화음마다 천천히 커졌다 작아지는 사인파 묶음 (살짝 어긋난 두 줄로 넓게)
    for ci, ch in enumerate(chords):
        start = int(ci * chord_len * SR)
        length = int(chord_len * SR * 1.25)  # 다음 화음과 겹치게
        for m in ch:
            for det in (-0.12, 0.12):
                f = note(m) * 2 ** (det / 12)
                ph = random.random() * 6.28
                for i in range(length):
                    j = (start + i) % n
                    t = i / SR
                    env = min(1, t / 1.6) * min(1, max(0, (length / SR - t) / 2.2))
                    buf[j] += math.sin(ph + 2 * math.pi * f * t) * env * 0.05
    # 종소리: 화음 구성음을 높은 옥타브에서 드문드문
    steps = int(total / (beat / 2))
    for s in range(steps):
        if random.random() > bell_density: continue
        ch = chords[int(s * beat / 2 / chord_len) % len(chords)]
        m = random.choice(ch) + 24
        f = note(m)
        start = int(s * beat / 2 * SR)
        for i in range(int(SR * 1.8)):
            j = (start + i) % n
            t = i / SR
            env = math.exp(-t * 2.6) * min(1, t / 0.005)
            buf[j] += (math.sin(2 * math.pi * f * t) + 0.3 * math.sin(2 * math.pi * f * 2.76 * t) * math.exp(-t * 6)) * env * 0.045
    # 저음 숨소리 (아주 약한 노이즈 바람)
    lp = 0.0
    for i in range(n):
        lp += 0.01 * ((random.random() * 2 - 1) - lp)
        buf[i] += lp * 0.12 * (0.6 + 0.4 * math.sin(2 * math.pi * i / n * 2))
    peak = max(abs(v) for v in buf) or 1
    with wave.open(os.path.join(OUT, name + '.wav'), 'w') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(v / peak * vol * 32000)) for v in buf))

# 홈: 따뜻하고 느린 진행 (F - Am - Dm - C, 장조풍)
render('bgm_home', [[53, 60, 65, 69], [57, 60, 64, 69], [50, 57, 62, 65], [48, 55, 60, 64]], 64, 2, 0.32, 3)
# 게임: 조금 더 신비롭게 (Am - F - G - Em)
render('bgm_game', [[45, 57, 60, 64], [41, 57, 60, 65], [43, 55, 59, 62], [40, 55, 59, 64]], 72, 2, 0.22, 7, vol=0.26)
print('ok')
