"""이미지 에셋 목록 + Gemini 프롬프트 생성 → docs/asset_manifest.json, docs/ASSETS.md
python3 tool/gen_asset_manifest.py
게임 코드가 찾는 id 와 같아야 한다 (lib/app/art.dart 의 Art.has('<id>')).
"""
import json, os

ROOT = os.path.join(os.path.dirname(__file__), '..')
STYLE = ("hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, "
         "warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, "
         "mobile puzzle game asset, high quality, clean silhouette, no text, no watermark")
GREEN = "isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background"

assets = []
def add(id, size, desc, transparent=True, group='', note=''):
    prompt = f"{desc}. {STYLE}. " + (GREEN if transparent else "full-bleed scene, no border")
    assets.append({'id': id, 'path': f'assets/images/{id}.png', 'size': size, 'transparent': transparent,
                   'group': group, 'prompt': prompt, 'note': note})

# ---------- 캐릭터 ----------
lumi = ("a tiny chibi forest archer named Lumi, two heads tall, wearing a navy blue hooded cloak whose hood tips look like small cat ears, "
        "cream colored round face with two big black dot eyes and pink blush, a small crescent moon brooch")
add('char/archer_idle', [512, 512], f"{lumi}, standing calmly facing the viewer, holding a glowing golden crescent-moon bow at the side", group='캐릭터')
add('char/archer_draw', [512, 512], f"{lumi}, seen from behind three-quarter view, pulling a glowing golden crescent-moon bow upward, determined", group='캐릭터')
add('char/archer_cheer', [512, 512], f"{lumi}, jumping with joy, arms up, sparkles around", group='캐릭터', note='클리어 화면')
add('char/bow', [256, 256], "a glowing golden crescent-moon shaped bow, horizontal, string on the left, bow curve opening to the right, magical soft gold glow", group='캐릭터', note='오른쪽을 향한 활. 코드가 조준 방향으로 회전')
add('char/arrow', [256, 64], "a slim magical arrow pointing right, golden shaft, glowing star-shaped tip, small feather fletching", group='캐릭터', note='오른쪽을 향한 화살')

dozy = ("a palm-sized round glowing forest spirit called Dozy, perfectly round soft body, two tiny leaf ears like bunny ears on top")
add('spirit/sleep', [256, 256], f"{dozy}, pale sky blue glowing body, eyes closed as gentle curved lines, pink blush cheeks, peacefully sleeping", group='정령')
add('spirit/awake', [256, 256], f"{dozy}, bright warm golden glowing body, happy smiling eyes shaped like ^ ^, small sparkles around, delighted", group='정령')
add('spirit/baby_sleep', [256, 256], f"{dozy} but smaller and baby-like, pastel pink glowing body, sleeping, a small red 'do not touch' prohibition circle sign floating above its head", group='정령')
add('spirit/baby_cry', [256, 256], f"{dozy} but smaller and baby-like, pastel pink body, woken up and crying with big tears, upset", group='정령')
add('spirit/shield', [256, 256], "a silver half-moon shaped shield, curved like a crescent arc, polished metal with soft blue highlights, front view, the arc opens to the left", group='정령', note='방패 정령에 겹쳐 그림. 오른쪽이 방패 앞면')

# ---------- 장치 ----------
add('tile/wood', [512, 64], "a horizontal mossy-free wooden log beam, tileable left to right, warm brown bark with light grain, side view", group='장치', note='나무 벽. 가로로 반복')
add('tile/moss', [512, 64], "a horizontal strip of thick fluffy glowing green moss, tileable left to right, side view, small dew drops", group='장치', note='이끼 벽. 가로로 반복')
add('tile/wood_block', [256, 128], "a rectangular wooden plank block, rounded corners, warm brown wood with grain, front view", group='장치')
add('tile/moss_block', [256, 128], "a rectangular block completely covered in fluffy glowing green moss, rounded corners, front view", group='장치')
add('tile/ice', [256, 64], "a horizontal slab of translucent pale blue ice, crystal clear with small cracks, front view", group='장치')
add('device/mirror', [256, 48], "a long thin magical mirror bar, polished silver surface reflecting light, ornate thin gold frame ends, horizontal", group='장치')
add('device/bumper', [256, 256], "a round bouncy forest mushroom cap seen from above-front, glossy pink red cap with cream white spots, short cream stem", group='장치')
add('device/portal_a', [256, 256], "a swirling magical portal ring, warm orange spiral energy around a dark center, front view", group='장치')
add('device/portal_b', [256, 256], "a swirling magical portal ring, cool blue spiral energy around a dark center, front view", group='장치')
add('device/prism', [256, 256], "a floating diamond-shaped rainbow prism crystal, faceted, refracting rainbow light, front view", group='장치')
add('device/switch_off', [256, 256], "a round ancient stone rune button, dark slate with a faint cyan triangle rune, front view", group='장치')
add('device/switch_on', [256, 256], "a round ancient stone rune button glowing bright cyan, triangle rune shining, energy sparkles, front view", group='장치')
add('device/gate', [512, 48], "a horizontal magical barrier bar of violet energy with flowing runes, tileable left to right", group='장치')

# ---------- 월드 배경 ----------
worlds = {
    1: "an enchanted night forest with old oak trees at the left and right edges, fireflies, mossy rocks at the bottom, a huge full moon behind clouds at the top",
    2: "a silver misty birch forest at night with floating mirror shards glinting at the edges, pale blue fog",
    3: "a glowing crystal cave with purple and teal crystal pillars at the edges, sparkling ore on the dark ceiling like stars",
    4: "a deep valley at night with flowing green and violet aurora in the sky, floating ancient rune stones and an old stone arch at the edges",
    5: "floating islands in outer space, a bright milky way, shooting stars, golden starlight",
}
for w, d in worlds.items():
    add(f'bg/world{w}_game', [1080, 1920],
        f"vertical mobile game background, {d}. The center 70% of the image is dark, calm and empty for gameplay, decorations only near the edges and bottom, a small flat grassy ledge at the bottom center", transparent=False, group='배경', note='게임 화면')
    add(f'bg/world{w}_map', [1080, 2700],
        f"tall vertical world map background for a level select screen, {d}, a winding dirt path area in the middle left empty, lush scenery along both sides, seamless top and bottom edges", transparent=False, group='배경', note='홈 지도. 세로로 이어 붙임')
add('bg/home_sky', [1080, 1920], "a calm deep indigo night sky with soft clouds, many tiny stars and a big glowing crescent moon at the upper right", transparent=False, group='배경')

# ---------- 지도 ----------
add('map/node_open', [256, 256], "a round stepping-stone medallion for a level select map, smooth blue-grey stone with a soft silver rim, top-down slightly tilted", group='지도')
add('map/node_current', [256, 256], "a round stepping-stone medallion glowing warm gold, magical light rising from it, slightly tilted top view", group='지도')
add('map/node_locked', [256, 256], "a round dark mossy stepping-stone with a small iron padlock, dim, slightly tilted top view", group='지도')
add('map/node_boss', [256, 256], "a large ornate round stone medallion with a golden crown emblem and moon carvings, glowing, slightly tilted top view", group='지도')
add('map/node_hard', [256, 256], "a round stepping-stone medallion with a red magical flame ring around it, slightly tilted top view", group='지도')

# ---------- UI 아이콘 ----------
icons = {
    'ui/coin': "a shiny gold coin with an engraved crescent moon",
    'ui/heart': "a glossy plump red heart with a white highlight",
    'ui/heart_inf': "a glossy plump cyan heart with an infinity symbol glow",
    'ui/star': "a plump glowing golden star",
    'ui/chest': "a small wooden treasure chest with gold trim, closed, glowing light leaking from the seams",
    'ui/chest_open': "a small wooden treasure chest with gold trim, open, bright golden light and coins bursting out",
    'ui/booster_aim': "a magical golden dotted guiding line with three bounce sparkles, icon",
    'ui/booster_extra': "a single golden glowing arrow with a plus sparkle, icon",
    'ui/booster_split': "a golden arrow splitting into three glowing branches, icon",
    'ui/hint': "a glowing lightbulb made of moonlight, icon",
    'ui/icon_checkin': "a cute calendar page with a red ribbon and a gold star sticker, icon",
    'ui/icon_daily': "a small sunrise over a hill with a single arrow, icon",
    'ui/icon_streak': "a cute magical cyan flame, icon",
    'ui/icon_shop': "a cute merchant bag full of gold coins, icon",
    'ui/icon_pass': "a golden medal ribbon with a moon emblem, icon",
    'ui/icon_gift': "a wrapped gift box with a gold ribbon, icon",
    'ui/icon_settings': "a cute brass gear, icon",
}
for k, v in icons.items():
    add(k, [256, 256], v, group='UI')
add('ui/logo', [1024, 512], "game logo text 'ECHO ARROW' in rounded bold golden letters with a glowing cyan O shaped like a ripple, a crescent moon bow behind the text", group='UI', note='로고만 글자 허용. 한국어판은 코드 글자 사용')

# ---------- 상점 ----------
shop = {
    'shop/starter': "a bundle of a gold coin pile, three magical arrows and a small heart, gift ribbon",
    'shop/noads': "a cute scroll with a crossed-out play button, icon",
    'shop/piggy': "a cute round glass jar shaped like a sleeping spirit, filled with glowing gold coins",
    'shop/pass': "a golden ticket with a crescent moon and arrow emblem",
    'shop/coins_s': "a small handful of gold moon coins",
    'shop/coins_m': "a cloth pouch of gold moon coins",
    'shop/coins_l': "a wooden box full of gold moon coins",
    'shop/coins_xl': "a big treasure chest overflowing with gold moon coins",
    'shop/coins_xxl': "a huge mountain of gold moon coins with gems, glowing",
}
for k, v in shop.items():
    add(k, [256, 256], v, group='상점')

# ---------- 앱 아이콘 ----------
add('icon/app_icon', [1024, 1024], f"app icon, {lumi} drawing a glowing golden crescent-moon bow, a glowing cyan arrow trail echo behind, deep indigo background, bold readable silhouette", transparent=False, group='아이콘', note='flutter_launcher_icons 원본')
add('icon/app_icon_fg', [1024, 1024], f"app icon foreground only, {lumi} drawing a glowing golden crescent-moon bow, centered with generous padding", group='아이콘', note='안드로이드 적응형 아이콘 전경(가운데 66%만 보임)')

with open(os.path.join(ROOT, 'docs', 'asset_manifest.json'), 'w', encoding='utf-8') as f:
    json.dump({'version': 1, 'style': STYLE, 'assets': assets}, f, ensure_ascii=False, indent=1)

lines = ['# 이미지 에셋 목록 (Gemini 프롬프트)', '',
         f'총 {len(assets)}장. 아트 기준은 [ART_DIRECTION.md](ART_DIRECTION.md).',
         '', '저장 규칙: 받은 이미지를 `raw/<id에서 / 를 __ 로 바꾼 이름>.png` 로 저장 → `python3 tool/process_assets.py raw/` → `python3 tool/check_assets.py`', '',
         '공통 스타일(모든 프롬프트에 이미 포함):', '', f'> {STYLE}', '']
groups = []
for a in assets:
    if a['group'] not in groups: groups.append(a['group'])
for g in groups:
    lines += [f'## {g}', '']
    for a in assets:
        if a['group'] != g: continue
        lines.append(f"### `{a['id']}` — {a['size'][0]}×{a['size'][1]}{' · 투명' if a['transparent'] else ''}")
        if a['note']: lines.append(f"- 메모: {a['note']}")
        lines += ['', '```', a['prompt'], '```', '']
with open(os.path.join(ROOT, 'docs', 'ASSETS.md'), 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
print(len(assets), 'assets')
