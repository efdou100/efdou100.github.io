"""방 템플릿 생성기. 좌표로 맵을 그려서 lib/game/rooms/room_templates.dart 를 만든다.
기호: # 땅  = 발판(아래에서 통과)  C 부서지는 발판  ^ 가시  J 스프링 버섯  T 가시덩굴(주기)
      h 수정 다리(수정을 맞히면 잠깐 생김)  S 수정  M/- 좌우 이동 발판  V/| 상하 이동 발판
      @ 시작  P 포털  R 보물상자  o 코인  * 꿈 조각
      s 슬라임  x 분열 슬라임  m 포자버섯  b 박쥐  w 도깨비불  K 킹 슬라임  L 꿈의 군주
python3 tool/gen_rooms.py 로 다시 만든다."""
import os

ROOMS = []

class Room:
    def __init__(s, id, type, tier, W, H=14, ground=10, waves=0, hints=None):
        s.id, s.type, s.tier, s.W, s.H, s.waves = id, type, tier, W, H, waves
        s.hints = hints or []
        s.g = [['.'] * W for _ in range(H)]
        for y in range(H):
            s.g[y][0] = '#'; s.g[y][W - 1] = '#'
        if ground is not None:
            s.fill(0, ground, W - 1, H - 1, '#')
        ROOMS.append(s)
    def fill(s, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                s.g[y][x] = c
        return s
    def put(s, x, y, txt):
        for i, c in enumerate(txt):
            s.g[y][x + i] = c
        return s
    def pit(s, x0, x1, top=10):
        return s.fill(x0, top, x1, s.H - 1, '.')
    def rows(s):
        return [''.join(r) for r in s.g]

# ───────── 1단계: 손맛 ─────────
r = Room('t_intro', 'combat', 1, 44, waves=1, hints=[
    (2, '좌우로 끌면 달려요'), (9, '톡 치거나 위로 튕기면 점프'), (17, '손을 떼면 멈춰서 자동으로 쏴요'),
    (27, '적이 빨갛게 번쩍이면 공격 신호! 움직여서 피해요')])
r.put(3, 9, '@').fill(12, 9, 14, 9, '#').pit(19, 19).put(20, 9, '.')
r.put(24, 9, 's').put(31, 9, 's').put(36, 9, 's').put(41, 9, 'P')
r.put(12, 8, 'ooo').put(18, 8, 'o').put(19, 7, 'o').put(20, 8, 'o')

r = Room('c1_glade', 'combat', 1, 36, waves=2)
r.put(3, 9, '@').put(11, 6, '====').put(24, 6, '====')
r.put(12, 9, 's').put(23, 9, 's').put(31, 9, 'm').put(19, 4, 'b').put(33, 9, 'P')
r.put(12, 5, 'oo').put(25, 5, 'oo')

r = Room('c1_twin', 'combat', 1, 34, waves=2)
r.put(2, 9, '@').fill(14, 8, 19, 9, '#').put(6, 7, '====').put(24, 7, '====')
r.put(8, 9, 's').put(17, 7, 'm').put(26, 9, 's').put(28, 4, 'b').put(31, 9, 'P').put(7, 6, 'oo')

r = Room('c1_hollow', 'combat', 1, 32, waves=2)
r.put(2, 9, '@').put(8, 7, '===').put(14, 5, '====').put(21, 7, '===')
r.fill(13, 9, 18, 9, '#')
r.put(10, 9, 's').put(16, 8, 'm').put(23, 9, 's').put(16, 2, 'b').put(29, 9, 'P').put(15, 4, 'oo')

r = Room('p1_steps', 'platform', 1, 42)
r.put(3, 9, '@').pit(10, 11).fill(18, 8, 21, 9, '#').pit(22, 24)
r.put(29, 7, '===').put(30, 6, '*').put(14, 9, 's').put(34, 9, 's').put(39, 9, 'P')
r.put(10, 7, 'oo').put(22, 6, 'ooo').put(18, 7, 'o')

r = Room('p1_bounce', 'platform', 1, 38, hints=[(8, '버섯을 밟으면 높이 튀어 올라요')])
r.put(3, 9, '@').put(14, 9, 'J').fill(16, 3, 21, 9, '#').put(19, 2, '*')
r.put(14, 7, 'o').put(14, 5, 'o').put(14, 3, 'o')
r.put(28, 9, 'm').put(32, 9, 's').put(35, 9, 'P')

# ───────── 2단계: 움직이는 발판, 부서지는 발판 ─────────
r = Room('p2_river', 'platform', 2, 44, hints=[(6, '움직이는 발판에 올라타요')])
r.put(3, 9, '@').pit(12, 27).put(13, 9, 'MM' + '-' * 11)
r.put(18, 6, '====').put(19, 5, '*').put(20, 4, 'b')
for x in (15, 18, 21, 24):
    r.put(x, 7, 'o')
r.put(33, 9, 's').put(41, 9, 'P')

r = Room('p2_crumble', 'platform', 2, 42, hints=[(6, '금 간 발판은 금방 무너져요. 멈추지 마세요')])
r.put(3, 9, '@').pit(10, 31)
for x in (11, 16, 21, 26):
    r.put(x, 9, 'CCC')
r.put(22, 6, '*').put(17, 7, 'o').put(27, 7, 'o').put(12, 7, 'o')
r.put(37, 9, 'm').put(39, 9, 'P')

r = Room('c2_lift', 'combat', 2, 36, waves=2)
r.put(3, 9, '@').fill(26, 5, 34, 9, '#').put(23, 9, 'VV')
for y in range(5, 9):
    r.put(23, y, '|')
r.put(9, 9, 's').put(16, 9, 'm').put(20, 9, 's').put(12, 4, 'b').put(31, 4, 'P').put(28, 4, 'o').put(10, 6, '===').put(11, 5, '*')

r = Room('p2_springs', 'platform', 2, 46)
r.put(3, 9, '@').pit(9, 30)
r.fill(12, 10, 14, 13, '#').put(13, 9, 'J').put(15, 4, '======').put(17, 3, '*')
r.fill(24, 10, 26, 13, '#').put(25, 9, 'J').put(27, 4, '=======')
r.put(13, 6, 'o').put(25, 6, 'o').put(21, 3, 'b').put(38, 9, 'm').put(43, 9, 'P')

r = Room('c2_pits', 'combat', 2, 38, waves=2)
r.put(3, 9, '@').pit(17, 19).put(16, 7, '=====').put(6, 6, '===').put(29, 6, '===')
r.put(10, 9, 's').put(24, 9, 'm').put(31, 9, 's').put(18, 3, 'b').put(35, 9, 'P').put(17, 6, 'ooo')

# ───────── 3단계: 타이밍, 수정 다리, 세로 등반 ─────────
r = Room('p3_thorns', 'platform', 3, 46, hints=[(4, '가시덩굴이 들어갈 때 지나가요')])
r.put(3, 9, '@')
for x in (9, 18, 27, 36):
    r.put(x, 9, 'TTTT').fill(x - 1, 0, x + 4, 7, '#')
r.put(15, 7, '*').put(14, 8, 'o').put(23, 8, 'o').put(32, 8, 'o')
r.put(43, 9, 'P')

r = Room('p3_bridge', 'platform', 3, 40, hints=[(4, '멈춰서 건너편 수정을 맞히면 다리가 생겨요. 서둘러요!')])
r.put(3, 9, '@').pit(10, 29).put(10, 10, 'h' * 20).put(32, 9, 'S')
r.put(15, 5, 'b').put(24, 4, 'b').put(19, 7, '*').put(13, 8, 'o').put(26, 8, 'o').put(37, 9, 'P')

r = Room('p3_climb', 'platform', 3, 26, H=26, ground=22, hints=[(3, '위로 올라가요')])
r.put(3, 21, '@')
r.put(8, 19, '====').put(13, 16, 'CCCC').put(18, 13, '====').put(12, 10, 'CCC')
r.put(7, 7, 'MM' + '-' * 5).fill(1, 4, 6, 5, '#').put(3, 3, 'P')
r.put(22, 10, '==').put(22, 9, '*').put(19, 12, 'b').put(9, 18, 'o').put(15, 15, 'o').put(20, 12, 'o')

r = Room('c3_thorns', 'combat', 3, 38, waves=3)
r.put(3, 9, '@').put(12, 9, 'TTT').put(23, 9, 'TTT').put(8, 6, '====').put(17, 5, '====').put(27, 6, '====')
r.put(10, 9, 'x').put(19, 4, 'w').put(26, 9, 'm').put(31, 9, 's').put(35, 9, 'P')

r = Room('c3_storm', 'combat', 3, 40, waves=3)
r.put(3, 9, '@').pit(9, 10).pit(29, 30).put(8, 7, '====').put(28, 7, '====').put(15, 5, '==========')
r.put(14, 9, 'x').put(20, 4, 'w').put(24, 9, 'm').put(34, 9, 's').put(12, 3, 'b').put(37, 9, 'P')

# ───────── 보상 / 보스 ─────────
r = Room('reward', 'reward', 1, 26, hints=[(4, '상자를 열면 스킬을 하나 더 골라요')])
r.put(3, 9, '@').put(12, 9, 'R').put(9, 6, '===').put(10, 5, 'oo').put(16, 6, '===').put(17, 5, 'oo').put(23, 9, 'P')

r = Room('boss_king', 'boss', 1, 30)
r.put(3, 9, '@').put(4, 6, '====').put(22, 6, '====').put(19, 9, 'K').put(26, 9, 'P')

r = Room('boss_lord', 'boss', 3, 34)
r.put(3, 9, '@').put(5, 6, '====').put(15, 4, '====').put(25, 6, '====').put(22, 9, 'L').put(30, 9, 'P')

# ───────── 출력 ─────────
out = ['// GENERATED by tool/gen_rooms.py — 직접 고치지 말고 생성기를 고친 뒤 다시 실행하세요.',
       "import 'room_template.dart';", '', 'const List<RoomTemplate> kRoomTemplates = [']
for r in ROOMS:
    rows = r.rows()
    assert all(len(x) == r.W for x in rows), r.id
    flat = ''.join(rows)
    assert flat.count('@') == 1 and flat.count('P') == 1, r.id
    hints = ', '.join(f"RoomHint({x}, '{t}')" for x, t in r.hints)
    out.append(f"  RoomTemplate(id: '{r.id}', type: RoomType.{r.type}, tier: {r.tier}, waves: {r.waves}, hints: [{hints}], rows: [")
    for row in rows:
        out.append(f"    '{row}',")
    out.append('  ]),')
out.append('];')
path = os.path.join(os.path.dirname(__file__), '..', 'lib', 'game', 'rooms', 'room_templates.dart')
os.makedirs(os.path.dirname(path), exist_ok=True)
open(path, 'w', encoding='utf-8').write('\n'.join(out) + '\n')
print('rooms:', len(ROOMS))
for r in ROOMS:
    if r.id in ('p3_climb', 'p2_river', 'p3_bridge', 'p1_bounce'):
        print(r.id); print('\n'.join(r.rows()))
