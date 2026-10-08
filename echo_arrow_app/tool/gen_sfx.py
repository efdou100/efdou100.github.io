"""효과음 합성기. python3 tool/gen_sfx.py → assets/audio/*.wav"""
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

def noise(dur, vol, a=0.002, r=2.0, lp=0.0):
    n = int(SR * dur); out = []; prev = 0.0
    for i in range(n):
        s = random.random() * 2 - 1
        if lp: prev = prev + lp * (s - prev); s = prev
        out.append(s * vol * env(i, n, a, r))
    return out

def silence(dur): return [0.0] * int(SR * dur)

# 시위 소리: 낮게 떨어지는 삼각파 + 짧은 바람 노이즈
save('twang', mix(tone(0.22, 230, 92, 'tri', 0.45), noise(0.09, 0.22, lp=0.35)))
# 메아리 발사: 높고 맑은 두 음
save('echo', mix(tone(0.28, 1320, 990, 'sine', 0.16), seq(silence(0.03), tone(0.2, 1980, 1500, 'sine', 0.08))))
# 튕김: 음이 반음씩 올라가는 8단계
for k in range(10):
    f = 480 * (1.1225 ** k)
    save(f'bounce_{k}', mix(tone(0.12, f, f, 'sine', 0.38), tone(0.06, f * 2, f * 2, 'tri', 0.08)))
save('stick', mix(noise(0.12, 0.45, lp=0.12), tone(0.12, 110, 60, 'sine', 0.4)))
save('gate_stick', mix(noise(0.12, 0.4, lp=0.3), tone(0.12, 160, 70, 'sine', 0.35)))
save('switch', seq(tone(0.05, 660, 660, 'square', 0.12), tone(0.05, 880, 880, 'square', 0.12), tone(0.12, 1320, 1320, 'square', 0.12)))
save('gate_open', mix(noise(0.35, 0.18, lp=0.5), tone(0.3, 300, 620, 'sine', 0.18)))
save('gate_close', mix(noise(0.3, 0.16, lp=0.2), tone(0.25, 520, 240, 'sine', 0.18)))
for k in range(4):
    base = 784 * (1.26 ** k)
    save(f'hit_{k}', mix(tone(0.38, base, base, 'sine', 0.36), seq(silence(0.04), tone(0.4, base * 1.5, base * 1.5, 'tri', 0.14)), noise(0.05, 0.12)))
save('win', mix(*[seq(silence(i * 0.07), tone(0.65, f, f, 'tri', 0.2, vib=0.006)) for i, f in enumerate([523, 659, 784, 1047, 1319])],
                *[seq(silence(i * 0.07), tone(0.65, f / 2, f / 2, 'sine', 0.1)) for i, f in enumerate([523, 659, 784, 1047, 1319])]))
save('fail', seq(tone(0.25, 392, 392, 'tri', 0.25), tone(0.25, 330, 330, 'tri', 0.25), tone(0.4, 262, 250, 'tri', 0.25)))
save('oops', mix(tone(0.3, 600, 300, 'square', 0.12), tone(0.3, 900, 420, 'tri', 0.16)))
save('fizzle', noise(0.22, 0.14, lp=0.25))
save('ice', mix(noise(0.25, 0.35), seq(tone(0.1, 1800, 1260, 'tri', 0.14), tone(0.1, 2400, 1680, 'tri', 0.12), tone(0.12, 1500, 1050, 'tri', 0.1))))
save('portal', mix(tone(0.26, 300, 900, 'sine', 0.3), seq(silence(0.05), tone(0.24, 900, 300, 'sine', 0.12))))
save('prism', mix(*[seq(silence(i * 0.035), tone(0.32, f, f, 'sine', 0.16)) for i, f in enumerate([1047, 1319, 1568, 2093])]))
save('shield', mix(tone(0.12, 1400, 900, 'square', 0.12), noise(0.05, 0.25)))
save('rotate', mix(tone(0.09, 520, 780, 'tri', 0.25), noise(0.06, 0.1, lp=0.4)))
save('click', tone(0.05, 900, 900, 'square', 0.1))
save('coin', seq(tone(0.05, 1320, 1320, 'square', 0.12), tone(0.12, 1980, 1980, 'square', 0.12)))
save('star', mix(tone(0.4, 1568, 2093, 'sine', 0.25, vib=0.01), noise(0.1, 0.06)))
save('chest', seq(tone(0.08, 392, 392, 'tri', 0.3), tone(0.08, 523, 523, 'tri', 0.3), mix(tone(0.5, 784, 784, 'tri', 0.3, vib=0.01), noise(0.3, 0.1, lp=0.6))))
save('purchase', seq(tone(0.06, 880, 880, 'sine', 0.25), tone(0.06, 1175, 1175, 'sine', 0.25), tone(0.25, 1760, 1760, 'sine', 0.28)))
save('pop', tone(0.08, 400, 900, 'sine', 0.3))
# 등불 폭발: 낮은 쿵 + 터지는 노이즈 + 반짝임
save('boom', mix(tone(0.55, 120, 40, 'sine', 0.55), noise(0.45, 0.4, lp=0.25), seq(silence(0.06), tone(0.3, 1600, 900, 'tri', 0.08))))
# 유리 마개 깨짐: 높은 파편음 여러 개
save('crack', mix(noise(0.3, 0.3, lp=0.7), *[seq(silence(i * 0.03), tone(0.14, f, f * 0.8, 'tri', 0.12)) for i, f in enumerate([2600, 3100, 2200, 3500])]))
# 되쏘기 고리: 붙잡을 때 위로 감기는 소리, 놓을 때 튕기는 소리
save('relay_catch', mix(tone(0.3, 400, 1200, 'sine', 0.22, vib=0.02), noise(0.08, 0.08, lp=0.4)))
save('relay', mix(tone(0.16, 900, 300, 'tri', 0.3), noise(0.06, 0.14, lp=0.4)))
print('ok')
