"""효과음 합성기. python3 tool/gen_sfx.py → assets/audio/*.wav (짧고 가벼운 8bit 느낌)"""
import math, os, random, struct, wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')
os.makedirs(OUT, exist_ok=True)
random.seed(7)

def env(i, n, a=0.005, r=None):
    t = i / SR; dur = n / SR
    at = min(1.0, t / a) if a > 0 else 1.0
    rel = (1 - t / dur) ** (r or 2)
    return at * rel

def tone(dur, f0, f1, kind='sine', vol=0.5, noise=0.0, a=0.004, r=2.0, vib=0.0):
    n = int(SR * dur); out = []; ph = 0.0
    for i in range(n):
        k = i / n
        f = f0 * (f1 / f0) ** k
        if vib: f *= 1 + vib * math.sin(i / SR * 2 * math.pi * 18)
        ph += 2 * math.pi * f / SR
        if kind == 'sine': s = math.sin(ph)
        elif kind == 'square': s = 1.0 if math.sin(ph) > 0 else -1.0
        elif kind == 'tri': s = 2 / math.pi * math.asin(math.sin(ph))
        else: s = 2 * ((ph / (2 * math.pi)) % 1) - 1
        if noise: s = s * (1 - noise) + (random.random() * 2 - 1) * noise
        out.append(s * vol * env(i, n, a, r))
    return out

def mix(*tracks):
    n = max(len(t) for t in tracks); out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t): out[i] += v
    return out

def seq(*parts):
    out = []
    for p in parts: out += p
    return out

def save(name, data):
    path = os.path.join(OUT, name + '.wav')
    with wave.open(path, 'w') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, v)) * 32000)) for v in data))

save('shoot', mix(tone(0.07, 1400, 600, 'tri', 0.28), tone(0.05, 3000, 1200, 'saw', 0.05, noise=0.6)))
save('hit', mix(tone(0.08, 260, 110, 'square', 0.22), tone(0.06, 900, 300, 'saw', 0.12, noise=0.8)))
save('crit', mix(tone(0.12, 1300, 380, 'square', 0.2), tone(0.1, 2600, 900, 'tri', 0.18), tone(0.08, 500, 200, 'saw', 0.15, noise=0.9)))
save('kill', mix(tone(0.16, 520, 120, 'square', 0.22), tone(0.14, 1800, 200, 'saw', 0.1, noise=0.85)))
save('jump', tone(0.13, 300, 720, 'sine', 0.35))
save('land', tone(0.07, 160, 70, 'sine', 0.4, noise=0.3))
save('spring', mix(tone(0.28, 220, 900, 'sine', 0.4, vib=0.08), tone(0.12, 120, 300, 'tri', 0.2)))
save('coin', seq(tone(0.05, 1320, 1320, 'square', 0.12), tone(0.12, 1980, 1980, 'square', 0.12)))
save('xp', tone(0.06, 1500, 2300, 'sine', 0.16))
save('levelup', seq(tone(0.08, 523, 523, 'tri', 0.3), tone(0.08, 659, 659, 'tri', 0.3), tone(0.08, 784, 784, 'tri', 0.3), tone(0.3, 1046, 1046, 'tri', 0.32, vib=0.01)))
save('hurt', mix(tone(0.25, 240, 70, 'saw', 0.3), tone(0.2, 400, 100, 'square', 0.1, noise=0.5)))
save('portal', mix(tone(0.6, 300, 1200, 'sine', 0.3, vib=0.04), tone(0.6, 450, 1800, 'tri', 0.12)))
save('crumble', tone(0.3, 180, 60, 'saw', 0.25, noise=0.85, r=1.5))
save('bridge', seq(tone(0.07, 880, 880, 'sine', 0.25), tone(0.07, 1108, 1108, 'sine', 0.25), tone(0.2, 1318, 1318, 'sine', 0.25)))
save('tele', tone(0.09, 820, 760, 'square', 0.1))
save('boom', mix(tone(0.4, 140, 40, 'saw', 0.4, noise=0.7, r=1.5), tone(0.3, 80, 30, 'sine', 0.5)))
save('thud', mix(tone(0.35, 110, 35, 'sine', 0.7), tone(0.2, 200, 60, 'saw', 0.15, noise=0.8)))
save('select', seq(tone(0.05, 700, 700, 'sine', 0.25), tone(0.1, 1050, 1050, 'sine', 0.25)))
save('chest', seq(tone(0.1, 392, 392, 'tri', 0.3), tone(0.1, 523, 523, 'tri', 0.3), tone(0.35, 784, 784, 'tri', 0.3, vib=0.015)))
save('shield', mix(tone(0.2, 1200, 600, 'sine', 0.3), tone(0.2, 1800, 900, 'tri', 0.15)))
save('freeze', tone(0.16, 2200, 1200, 'sine', 0.2, noise=0.2))
save('zap', tone(0.12, 1800, 300, 'saw', 0.18, noise=0.5))
save('focus', mix(tone(0.5, 200, 800, 'sine', 0.35), tone(0.5, 300, 1200, 'tri', 0.1)))
print('ok', len(os.listdir(OUT)))
