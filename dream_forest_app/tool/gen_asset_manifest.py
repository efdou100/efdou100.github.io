"""전체 에셋 목록(현재 사용 + 앞으로 추가할 콘텐츠)을 한곳에서 관리해요.

python3 tool/gen_asset_manifest.py
  → docs/asset_manifest.json  (로컬 자동화가 한 줄씩 읽어서 Gemini 로 생성)
  → docs/ASSET_LIST.md         (사람이 보는 목록)

status: used = 지금 게임이 이 id 를 찾아요 (파일만 넣으면 바로 교체)
        planned = 앞으로 추가할 콘텐츠 (시스템 구현 때 이 id 를 그대로 써요)
"""
import json, os

ROOT = os.path.join(os.path.dirname(__file__), '..')

# ───────── 화풍 기준 (모든 이미지 프롬프트 앞에 붙여요) ─────────
STYLE = {
    'image_prefix': (
        'High-quality 2D mobile game asset, cute but premium fantasy style like a top-grossing casual RPG, '
        'clean vector-like shapes with soft painterly shading, bold readable silhouette, '
        'warm magical night-forest palette (deep teal, violet, amber glow), subtle rim light, '
        'no text, no watermark, no frame, single subject centered, '
    ),
    'sprite_suffix': 'side view facing RIGHT, full body, transparent background (PNG alpha), no ground shadow, no background elements.',
    'icon_suffix': 'game UI icon, centered, transparent background (PNG alpha), slight glow, readable at 64px.',
    'bg_suffix': 'wide horizontal parallax layer for a side-scrolling game, seamless left-right tiling, transparent sky area (PNG alpha) unless it is the sky layer, no characters.',
    'tile_suffix': 'square seamless game tile, top-down lighting from above, transparent where empty, tiles seamlessly left and right.',
    'negative': 'text, letters, logo, watermark, signature, blurry, low resolution, jpeg artifacts, photo, 3D render, multiple subjects, cropped subject',
    'audio_prefix': 'Game audio for a cute premium fantasy side-scrolling action RPG set in a magical night forest. ',
}

CHAPTERS = [
    (1, '잠든 숲', 'sleepy night forest with giant trees, glowing mushrooms, fireflies, moonlight'),
    (2, '버섯 동굴', 'underground cavern of giant bioluminescent mushrooms, crystals, dripping moss'),
    (3, '안개 늪', 'misty swamp with lily pads, twisted roots, will-o-wisps, purple fog'),
    (4, '눈꽃 고원', 'snowy highland with frosted pines, aurora sky, ice crystals'),
    (5, '잿불 화산숲', 'volcanic forest with charred trees, glowing lava cracks, embers floating'),
    (6, '별빛 하늘섬', 'floating sky islands at night, starry sky, crystal bridges, clouds'),
]

assets = []

def add(id, category, size, ko, desc, prompt, status='planned', kind='image', transparent=True, ext='png', extra=None):
    folder = 'images' if kind == 'image' else 'audio'
    a = {
        'id': id, 'type': kind, 'category': category, 'status': status,
        'path': f'assets/{folder}/{id}.{ext}',
        'ko': ko, 'desc': desc, 'prompt': prompt,
    }
    if kind == 'image':
        a['size'] = size
        a['transparent'] = transparent
    else:
        a['duration_sec'] = size
    if extra:
        a.update(extra)
    assets.append(a)

# ───────── 주인공: 부위별(종이인형 방식) ─────────
PLAYER_PARTS = [
    ('head', [512, 480], '머리(후드+얼굴)', 'Head of a young hooded archer: green hood with pointed tip falling back, round cute face, big eyes, brown bangs, looking right. ONLY the head and hood.'),
    ('body', [384, 448], '몸통', 'Torso of the archer: green cloak tunic with leather belt and small amber scarf knot at the neck. ONLY the torso, no head, no arms, no legs.'),
    ('cape', [384, 448], '망토 뒷자락', 'Back flap of a short dark green cape flowing to the LEFT (behind the character). ONLY the cape piece.'),
    ('leg_front', [160, 256], '앞다리', 'One leg of the archer pointing straight down: dark green trousers and small brown leather boot. ONLY one leg.'),
    ('leg_back', [160, 256], '뒷다리', 'One leg of the archer pointing straight down, slightly darker shade (it is behind the body). ONLY one leg.'),
    ('bow', [288, 448], '활', 'Elegant wooden recurve bow held vertically, string on the LEFT side, small leaf ornaments, a hand gripping the middle. ONLY the bow and hand.'),
    ('full', [512, 704], '통짜 캐릭터(부위가 없을 때 대체)', 'Full body cute young hooded archer in green cloak with amber scarf, holding a wooden bow, idle pose.'),
]
for pid, size, ko, prompt in PLAYER_PARTS:
    add(f'player/{pid}', 'player', size, ko, '주인공 부위. 피벗은 docs/ASSET_PIPELINE.md 표 참고', prompt, status='used',
        extra={'suffix': 'sprite'})

# 주인공 스킨(장비 외형) 계획
for sid, ko, p in [('skin_moon', '달빛 궁수', 'silver-blue hood with moon embroidery'), ('skin_ember', '잿불 궁수', 'red-orange hood with ember patterns'),
                   ('skin_frost', '서리 궁수', 'white-blue hood with frost fur trim'), ('skin_star', '별의 궁수', 'deep navy hood with glittering star patterns')]:
    add(f'player/{sid}_full', 'player', [512, 704], ko, '스킨(상점·이벤트 보상)', f'Full body cute young hooded archer, {p}, holding a bow, idle pose.', extra={'suffix': 'sprite'})

# ───────── 몬스터 (챕터마다 6종 + 중간보스 + 최종보스) ─────────
MONSTERS = {
    1: [('slime', '슬라임', '천천히 다가오다 웅크린 뒤 덮쳐요', 'cute round green jelly slime with big shiny eyes', 'used'),
        ('slime_split', '분열 슬라임', '쓰러지면 작은 슬라임 둘로 나뉘어요', 'bigger blue jelly slime with small crystals floating inside', 'used'),
        ('slime_mini', '꼬마 슬라임', '분열 슬라임에서 나와요. 빠르고 약해요', 'tiny light-blue baby slime, mischievous face', 'used'),
        ('mush_spore', '포자버섯', '부풀었다가 포자 3발을 쏴요', 'red-capped mushroom creature with white spots and tiny feet, puffy cheeks', 'used'),
        ('bat', '박쥐', '조준선을 그린 뒤 돌진해요', 'small purple bat with big ears and yellow eyes, wings spread', 'used'),
        ('wisp', '도깨비불', '거리를 두고 유도탄을 쏴요', 'floating blue spirit flame with cute face and wispy tail', 'used')],
    2: [('cave_beetle', '수정 딱정벌레', '등껍질이 단단해 앞에서는 피해가 줄어요', 'cave beetle with glowing crystal shell'),
        ('glow_snail', '빛 달팽이', '느리지만 지나간 자리에 독 점액을 남겨요', 'snail with glowing mushroom shell'),
        ('spore_puff', '포자 복어', '터지면서 주변에 포자를 흩뿌려요', 'puffy round spore creature like a pufferfish'),
        ('cave_bat_king', '동굴 큰박쥐', '세 마리가 함께 돌진해요', 'large dark violet cave bat with crystal fangs'),
        ('rock_golem_mini', '꼬마 바위 골렘', '느리게 걷다 땅을 쳐서 충격파를 보내요', 'small cute rock golem with moss and glowing runes'),
        ('crystal_imp', '수정 도깨비', '순간이동하며 수정 조각을 던져요', 'small imp made of purple crystal')],
    3: [('frog_knight', '개구리 기사', '방패로 막다가 혀로 끌어당겨요', 'frog knight with leaf shield and twig spear'),
        ('swamp_eel', '늪 장어', '물 위로 튀어올라 포물선으로 덮쳐요', 'slimy green eel leaping'),
        ('mist_ghost', '안개 유령', '반투명해졌다 나타나며 공격해요', 'translucent misty ghost with lantern'),
        ('lily_turtle', '연잎 거북', '등이 발판이 돼요. 공격하면 숨어요', 'turtle with a big lily pad on its back'),
        ('mosquito', '대왕 모기', '빠르게 지그재그로 날아와요', 'cute but annoying big mosquito'),
        ('root_snake', '뿌리 뱀', '땅속에서 솟아올라 물어요', 'snake made of twisted roots')],
    4: [('snow_bunny', '눈토끼', '높이 뛰어 위에서 내려찍어요', 'fluffy white snow rabbit with ice crystals on ears'),
        ('ice_slime', '얼음 슬라임', '닿으면 잠깐 느려져요', 'transparent icy slime with snowflake inside'),
        ('frost_owl', '서리 부엉이', '위에서 얼음 깃털을 흩뿌려요', 'white owl with frost feathers'),
        ('yeti_cub', '아기 설인', '눈덩이를 굴려 보내요', 'cute baby yeti holding a snowball'),
        ('icicle_bat', '고드름 박쥐', '천장에 매달렸다 떨어져요', 'bat with icicle wings'),
        ('aurora_wisp', '오로라 정령', '색이 바뀔 때마다 패턴이 달라져요', 'rainbow aurora spirit')],
    5: [('ember_slime', '잿불 슬라임', '쓰러진 자리에 불길을 남겨요', 'orange lava slime with ember glow'),
        ('fire_fox', '불여우', '불꽃 꼬리로 빠르게 돌진해요', 'small fox with flaming tail'),
        ('magma_crab', '용암 게', '집게로 막고 화염탄을 쏴요', 'crab with molten rock shell'),
        ('ash_crow', '잿빛 까마귀', '무리지어 위에서 급강하해요', 'dark crow with glowing ember eyes'),
        ('lava_golem', '용암 골렘', '느리지만 아주 단단해요', 'golem of cooled lava with glowing cracks'),
        ('fire_sprite', '불꽃 요정', '불꽃 고리를 퍼뜨려요', 'tiny fire fairy')],
    6: [('star_jelly', '별 해파리', '천천히 떠다니며 별가루를 떨어뜨려요', 'floating jellyfish made of starlight'),
        ('cloud_sheep', '구름 양', '구름 발판을 만들었다 없애요', 'fluffy sheep made of clouds'),
        ('comet_bird', '혜성 새', '꼬리를 끌며 직선으로 돌진해요', 'bird with comet tail'),
        ('moon_knight', '달 기사', '초승달 검기를 날려요', 'small armored knight with crescent moon helmet'),
        ('nebula_eye', '성운의 눈', '레이저를 회전하며 쏴요', 'floating eyeball inside a swirling nebula'),
        ('crystal_dragonling', '수정 아기용', '수정 숨결을 뿜어요', 'baby dragon made of crystal')],
}
BOSSES = {
    1: [('boss_king_slime', '킹 슬라임', '착지 지점 표시 → 쿵! 땅을 타는 충격파', 'giant pink king slime wearing a golden crown', 'used'),
        ('boss_dream_lord', '꿈의 군주', '포자 비, 돌진, 소환, 회전탄', 'mysterious floating lord in a violet robe with a huge glowing mushroom hat', 'used')],
    2: [('boss_crystal_queen', '수정 여왕 거미', '거미줄로 발판을 묶고 수정을 쏴요', 'giant crystal spider queen'),
        ('boss_mushroom_titan', '버섯 거인', '몸에서 버섯이 자라 소환해요', 'enormous walking mushroom titan')],
    3: [('boss_swamp_hag', '늪 마녀', '독 웅덩이와 개구리 소환', 'swamp witch riding a giant frog'),
        ('boss_hydra', '늪 히드라', '머리 셋이 따로 공격해요', 'three-headed swamp hydra')],
    4: [('boss_frost_yeti', '서리 설인왕', '얼음 기둥을 세우고 눈사태', 'huge yeti king with icy crown'),
        ('boss_aurora_stag', '오로라 사슴', '빛의 길을 따라 돌진해요', 'majestic stag with aurora antlers')],
    5: [('boss_lava_dragon', '용암 드래곤', '화염 숨결과 용암 비', 'lava dragon with glowing cracks'),
        ('boss_phoenix', '불사조', '쓰러지면 한 번 되살아나요', 'flaming phoenix')],
    6: [('boss_star_whale', '별고래', '하늘섬 사이를 헤엄치며 공격', 'giant whale made of night sky and stars'),
        ('boss_dream_eater', '꿈을 먹는 자', '최종 보스. 지금까지의 패턴을 섞어 써요', 'final boss: shadowy dream-eater with many glowing eyes and starry cloak')],
}
for ch, mons in MONSTERS.items():
    for m in mons:
        mid, ko, desc, look = m[:4]
        st = m[4] if len(m) > 4 else 'planned'
        add(f'monster/{mid}', 'monster', [512, 512], ko, f'{ch}챕터 · {desc}', f'{look}, cute enemy monster.', status=st,
            extra={'suffix': 'sprite', 'chapter': ch, 'variants': ['_charge (공격 예고 자세, 선택)']})
for ch, bs in BOSSES.items():
    for b in bs:
        bid, ko, desc, look = b[:4]
        st = b[4] if len(b) > 4 else 'planned'
        add(f'monster/{bid}', 'boss', [1024, 1024], ko, f'{ch}챕터 보스 · {desc}', f'{look}, imposing but cute boss monster, dramatic glow.', status=st,
            extra={'suffix': 'sprite', 'chapter': ch, 'variants': ['_charge (공격 예고 자세, 선택)']})

# ───────── 스킬 아이콘 (지금 17종 + 횡스크롤 전용 신규 23종) ─────────
SKILLS = [
    ('multishot', '멀티샷', 'two arrows flying in quick succession', 'used'), ('front', '정면 화살 +1', 'three parallel arrows', 'used'),
    ('diagonal', '사선 화살', 'three arrows fanning out', 'used'), ('back', '뒤쪽 화살', 'arrows flying left and right from a center', 'used'),
    ('pierce', '관통', 'arrow piercing through a target', 'used'), ('ricochet', '벽 도탄', 'arrow bouncing off a stone wall with sparks', 'used'),
    ('fire', '화염 화살', 'flaming arrow', 'used'), ('frost', '빙결 화살', 'ice crystal arrow with snowflake', 'used'),
    ('lightning', '번개 화살', 'arrow crackling with lightning', 'used'), ('attack', '공격력', 'glowing sharp arrowhead', 'used'),
    ('haste', '속사', 'double chevron speed lines with arrow', 'used'), ('crit', '급소 노리기', 'golden crosshair target', 'used'),
    ('orbit', '수호 구슬', 'glowing orbs orbiting a star', 'used'), ('vampire', '흡혈', 'red drop with leaf', 'used'),
    ('heart', '생명의 이슬', 'heart-shaped dew drop', 'used'), ('shield', '나뭇잎 방패', 'shield made of a big leaf', 'used'),
    ('focus', '깊은 집중', 'glowing eye with blue aura', 'used'), ('chain', '연쇄 화살', 'arrow jumping between enemies with light trail', 'used'),
    ('ground_bounce', '물수제비 화살', 'arrow skipping along the ground like a stone on water'), ('arrow_rain', '화살비', 'many arrows falling from the sky'),
    ('sky_shot', '내려찍기', 'arrow shooting downward from a jumping archer'), ('boomerang', '부메랑 화살', 'curved arrow returning'),
    ('split_arrow', '세 갈래 화살', 'arrow splitting into three on impact'), ('giant_arrow', '거대 화살', 'huge glowing arrow'),
    ('explosive', '폭발 화살', 'arrow with bomb tip exploding'), ('poison', '독 화살', 'green dripping poison arrow'),
    ('wind', '바람 화살', 'arrow with swirling wind knocking back'), ('homing', '유도 화살', 'arrow curving toward a target'),
    ('wall_splat', '벽 꽂기', 'enemy slammed into a wall with impact stars'), ('juggle', '띄우기', 'enemy knocked up into the air'),
    ('ice_nova', '얼음 폭발', 'ring of ice spikes'), ('thunder', '천둥 소환', 'lightning bolt striking from cloud'),
    ('clone', '그림자 분신', 'shadow copy of the archer'), ('owl_pet', '부엉이 친구', 'cute owl companion'),
    ('magnet', '자석', 'magnet pulling coins'), ('gold_rush', '황금 사냥', 'pile of gold coins'),
    ('xp_boost', '깨달음', 'glowing book with stars'), ('revive', '불사조 깃털', 'phoenix feather'),
    ('thorns', '가시 갑옷', 'armor with thorns reflecting damage'), ('slow_aura', '시간의 고리', 'clock ring slowing time'),
]
for sid, ko, look, *st in SKILLS:
    add(f'skill/{sid}', 'skill', [256, 256], ko, '스킬 아이콘', f'{look}.', status=st[0] if st else 'planned', extra={'suffix': 'icon'})

# ───────── 장비 (활·망토·모자·부적 × 등급) ─────────
RARITIES = [('common', '일반'), ('rare', '희귀'), ('epic', '영웅'), ('legend', '전설')]
EQUIP = {
    'bow': ('활', [('oak', '참나무'), ('moon', '달빛'), ('ember', '잿불'), ('frost', '서리'), ('star', '별빛'), ('dream', '꿈결')], 'recurve bow'),
    'cloak': ('망토', [('moss', '이끼'), ('night', '밤하늘'), ('flame', '불꽃'), ('aurora', '오로라'), ('cloud', '구름'), ('dream', '꿈결')], 'short hooded cloak'),
    'hood': ('모자', [('leaf', '나뭇잎'), ('owl', '부엉이'), ('fox', '여우'), ('snow', '눈꽃'), ('crown', '작은 왕관'), ('dream', '꿈결')], 'hat / hood'),
    'charm': ('부적', [('acorn', '도토리'), ('feather', '깃털'), ('crystal', '수정'), ('ember', '불씨'), ('star', '별조각'), ('dream', '꿈결')], 'small magical charm pendant'),
}
for slot, (slot_ko, themes, look) in EQUIP.items():
    for i, (tid, tko) in enumerate(themes):
        rid, rko = RARITIES[min(3, i * 4 // len(themes))]
        add(f'equip/{slot}_{tid}', 'equip', [256, 256], f'{tko} {slot_ko}', f'{rko} 등급 장비', f'{tid} themed {look}, {rid} rarity item, item icon.',
            extra={'suffix': 'icon', 'slot': slot, 'rarity': rid})

# ───────── 아이템 ─────────
ITEMS = [
    ('coin', '코인', 'shiny gold coin with leaf emblem', 'used'), ('dream_shard', '꿈 조각', 'glowing star-shaped crystal shard', 'used'),
    ('heal_heart', '회복 하트', 'pink heart-shaped berry', 'used'), ('chest_closed', '보물상자(닫힘)', 'wooden treasure chest with gold trim, closed', 'used'),
    ('chest_open', '보물상자(열림)', 'same wooden treasure chest, open with golden light', 'used'),
    ('portal_closed', '포털(닫힘)', 'ancient stone arch portal, dim runes, inactive', 'used'),
    ('portal_open', '포털(열림)', 'same stone arch portal, swirling green-gold magical light', 'used'),
    ('gem', '보석', 'sparkling blue gem'), ('energy', '에너지', 'glowing green leaf energy drop'), ('ticket', '도전 티켓', 'golden ticket with leaf'),
    ('key', '열쇠', 'ornate golden key'), ('chest_silver', '은 상자', 'silver treasure chest'), ('chest_gold', '금 상자', 'golden treasure chest'),
    ('chest_dream', '꿈의 상자', 'magical violet treasure chest with stars'), ('scroll', '강화 주문서', 'magic scroll'),
]
for iid, ko, look, *st in ITEMS:
    add(f'item/{iid}', 'item', [256, 256], ko, '아이템', f'{look}.', status=st[0] if st else 'planned', extra={'suffix': 'icon'})

# ───────── 배경 (챕터별 4장 + 메뉴) ─────────
for ch, ko, theme in CHAPTERS:
    st = 'used' if ch == 1 else 'planned'
    add(f'bg/ch{ch}_sky', 'bg', [2048, 1080], f'{ko} 하늘', '가장 뒤 하늘 (불투명)', f'{theme}, sky only with moon/stars, no trees.', status=st, transparent=False, extra={'suffix': 'bg'})
    add(f'bg/ch{ch}_far', 'bg', [4096, 1080], f'{ko} 먼 풍경', '시차 0.12', f'{theme}, distant silhouettes, low contrast, misty.', status=st, extra={'suffix': 'bg'})
    add(f'bg/ch{ch}_mid', 'bg', [4096, 1080], f'{ko} 중간 숲', '시차 0.3', f'{theme}, mid-distance trees and shapes, medium contrast.', status=st, extra={'suffix': 'bg'})
    add(f'bg/ch{ch}_near', 'bg', [4096, 1080], f'{ko} 가까운 숲', '시차 0.55, 아래쪽은 땅에 가려져요', f'{theme}, close large trunks and glowing plants framing the top and sides.', status=st, extra={'suffix': 'bg'})
    add(f'bg/map_ch{ch}', 'bg', [2560, 1080], f'{ko} 지도', '스테이지 지도 배경', f'{theme}, top-down-ish storybook world map with a winding path, no text.', transparent=False, extra={'suffix': 'bg'})
add('bg/menu', 'bg', [2560, 1440], '메뉴 배경', '타이틀·캠프 화면', 'magical night forest clearing with giant moon and fireflies, cozy, wide shot.', status='used', transparent=False, extra={'suffix': 'bg'})
add('bg/lobby', 'bg', [2560, 1440], '로비(캠프) 배경', '홈 화면: 모닥불과 텐트', 'cozy forest camp at night with campfire, tent, lanterns, wide shot.', transparent=False, extra={'suffix': 'bg'})

# ───────── 타일 (챕터별) ─────────
TILES = [('ground', '흙 속', [128, 128], 'ground soil fill texture, stones and roots'),
         ('ground_top', '윗면(풀)', [128, 160], 'ground block with grass and small flowers on top edge (top 32px is grass overhang)'),
         ('plank', '나무 발판', [128, 48], 'thin wooden plank platform'),
         ('crumble', '부서지는 발판', [128, 48], 'cracked fragile wooden plank'),
         ('spring', '스프링 버섯', [160, 160], 'bouncy pink mushroom cap trampoline'),
         ('thorn', '가시덩굴', [128, 128], 'purple thorny vine spikes pointing up'),
         ('bridge', '수정 다리', [128, 48], 'glowing violet crystal bridge plank'),
         ('mover', '움직이는 발판', [256, 64], 'mossy floating log platform with glowing runes'),
         ('lift', '승강 발판', [256, 64], 'stone slab elevator platform with lantern')]
for ch, ko, theme in CHAPTERS:
    for tid, tko, size, look in TILES:
        add(f'tile/ch{ch}_{tid}', 'tile', size, f'{ko} {tko}', '타일', f'{look}, themed for {theme}.', status='used' if ch == 1 else 'planned', extra={'suffix': 'tile', 'chapter': ch})
add('tile/crystal', 'tile', [192, 256], '수정 스위치', '쏘면 다리가 생겨요', 'floating violet diamond crystal with glow.', status='used', extra={'suffix': 'icon'})

# ───────── UI ─────────
for uid, ko, size, look, st in [
    ('logo', '게임 로고 (꿈의 숲)', [1600, 640], 'game logo text "꿈의 숲" in cute rounded Korean letters with glowing amber gradient and leaf decorations (this one MAY include the title text)', 'planned'),
    ('app_icon', '앱 아이콘', [1024, 1024], 'app icon: cute hooded archer face with glowing forest background, rounded square composition', 'planned'),
    ('splash', '스플래시', [2560, 1440], 'splash art of the hooded archer aiming a bow in the moonlit forest', 'planned'),
    ('frame_common', '카드 테두리(일반)', [512, 768], 'ornate card frame, teal', 'planned'), ('frame_rare', '카드 테두리(희귀)', [512, 768], 'ornate card frame, blue', 'planned'),
    ('frame_epic', '카드 테두리(영웅)', [512, 768], 'ornate card frame, purple with sparkles', 'planned'), ('frame_legend', '카드 테두리(전설)', [512, 768], 'ornate card frame, gold with rays', 'planned'),
    ('btn_primary', '기본 버튼', [512, 160], 'rounded glossy amber button base, empty', 'planned'), ('btn_secondary', '보조 버튼', [512, 160], 'rounded glossy teal button base, empty', 'planned'),
    ('panel', '패널 틀', [1024, 640], 'wooden-and-leaf ornate panel frame, empty center', 'planned'),
    ('menu_shop', '상점 아이콘', [256, 256], 'shop icon: little market stall', 'planned'), ('menu_attendance', '출석 아이콘', [256, 256], 'calendar with leaf stamp', 'planned'),
    ('menu_mission', '미션 아이콘', [256, 256], 'quest scroll with checkmark', 'planned'), ('menu_codex', '도감 아이콘', [256, 256], 'monster encyclopedia book', 'planned'),
    ('menu_equip', '장비 아이콘', [256, 256], 'bow and cloak', 'planned'), ('menu_ranking', '랭킹 아이콘', [256, 256], 'trophy', 'planned'),
    ('menu_mail', '우편 아이콘', [256, 256], 'letter with seal', 'planned'), ('menu_settings', '설정 아이콘', [256, 256], 'gear made of wood', 'planned'),
    ('stamp', '출석 도장', [256, 256], 'round leaf stamp mark', 'planned'), ('star', '별', [256, 256], 'golden star', 'planned'),
    ('npc_owl', 'NPC 부엉이 할아버지', [768, 768], 'wise old owl NPC with glasses and scarf, quest giver', 'planned'),
    ('npc_merchant', 'NPC 상인 다람쥐', [768, 768], 'squirrel merchant with big backpack', 'planned'),
]:
    add(f'ui/{uid}', 'ui', size, ko, 'UI', f'{look}.', status=st, extra={'suffix': 'icon'})

# ───────── 도감 프레임 (몬스터 그림은 monster/ 를 그대로 써요) ─────────
add('codex/frame', 'codex', [768, 1024], '도감 카드 틀', '몬스터 카드 배경', 'storybook page card frame with vines, empty center.', extra={'suffix': 'icon'})
add('codex/unknown', 'codex', [512, 512], '미발견 실루엣 배경', '아직 못 만난 몬스터', 'dark mysterious silhouette placeholder with question mark glow (no letters).', extra={'suffix': 'icon'})

# ───────── 효과음 ─────────
SFX = [
    ('shoot', '활 쏘기', 0.2, 'short soft bow twang with whoosh', 'used'), ('hit', '명중', 0.15, 'punchy soft impact thud with tiny crunch', 'used'),
    ('crit', '치명타', 0.25, 'sharp bright impact with sparkle ring', 'used'), ('kill', '처치', 0.3, 'satisfying pop with magical sparkle', 'used'),
    ('jump', '점프', 0.15, 'light cute jump whoosh', 'used'), ('land', '착지', 0.12, 'soft grass landing thump', 'used'),
    ('spring', '버섯 점프', 0.35, 'boingy rubbery mushroom bounce', 'used'), ('coin', '코인', 0.2, 'bright two-note coin chime', 'used'),
    ('xp', '경험치', 0.08, 'tiny twinkle pickup', 'used'), ('levelup', '레벨업', 0.8, 'uplifting magical level up arpeggio', 'used'),
    ('hurt', '피격', 0.3, 'player hurt grunt-free impact with low thud', 'used'), ('portal', '포털', 0.7, 'magical portal whoosh with shimmer', 'used'),
    ('crumble', '발판 붕괴', 0.4, 'wood cracking and breaking', 'used'), ('bridge', '수정 다리', 0.5, 'crystal chime ascending', 'used'),
    ('tele', '공격 예고', 0.12, 'short warning blip', 'used'), ('boom', '폭발', 0.5, 'soft magical explosion', 'used'),
    ('thud', '보스 착지', 0.5, 'heavy ground slam', 'used'), ('select', '선택', 0.15, 'UI select click with sparkle', 'used'),
    ('chest', '상자 열기', 0.7, 'treasure chest open with golden jingle', 'used'), ('shield', '방패', 0.3, 'leafy shield block whoosh', 'used'),
    ('freeze', '빙결', 0.25, 'ice crackle freeze', 'used'), ('zap', '번개', 0.2, 'electric zap', 'used'), ('focus', '집중', 0.6, 'time slow whoosh deepening', 'used'),
    ('bounce', '화살 튕김', 0.1, 'bright ricochet ping (pitch can rise)', 'used'), ('splat', '벽 꽂기', 0.25, 'chunky wall slam crunch', 'used'),
    ('victory', '클리어 팡파레', 2.5, 'short triumphant fanfare', 'used'), ('defeat', '패배', 2.0, 'gentle sad but hopeful jingle', 'used'),
    ('ui_open', '창 열기', 0.2, 'soft UI panel open'), ('ui_close', '창 닫기', 0.15, 'soft UI panel close'), ('purchase', '구매', 0.6, 'cash register sparkle'),
    ('gacha_open', '뽑기', 1.2, 'suspenseful chest rumble then pop'), ('gacha_legend', '전설 등장', 2.0, 'epic legendary reveal with choir'),
    ('attendance', '출석 도장', 0.5, 'stamp thunk with chime'), ('mission_done', '미션 완료', 0.8, 'cheerful completion chime'),
    ('equip', '장착', 0.3, 'cloth and metal equip sound'), ('upgrade', '강화 성공', 0.8, 'anvil ring with sparkle'), ('boss_roar', '보스 등장', 1.5, 'cute but powerful monster roar'),
    ('boss_phase', '보스 2페이즈', 1.0, 'dramatic power-up surge'), ('rope', '밧줄 오르기', 0.3, 'rope creak'), ('water', '물 첨벙', 0.4, 'water splash'),
]
for sid, ko, dur, look, *st in SFX:
    add(f'sfx/{sid}', 'sfx', dur, ko, '효과음', look + '.', status=st[0] if st else 'planned', kind='audio', ext='ogg')

# ───────── 배경음 ─────────
BGM = [('title', '타이틀', 90, 'dreamy magical forest theme, music box, soft strings, memorable melody', 'used'),
       ('map', '스테이지 지도', 90, 'cozy adventurous walking theme, light percussion, flute', 'used'),
       ('camp', '캠프·상점', 90, 'warm campfire acoustic guitar and ocarina', 'used'),
       ('lobby', '로비', 90, 'relaxing hub theme, gentle harp')]
for ch, ko, theme in CHAPTERS:
    BGM.append((f'stage_ch{ch}', f'{ko} 스테이지', 120, f'upbeat action-adventure loop for {theme}, 120-140 BPM, catchy', 'used' if ch == 1 else 'planned'))
    BGM.append((f'boss_ch{ch}', f'{ko} 보스', 120, f'intense but cute boss battle loop for {theme}, driving drums', 'used' if ch == 1 else 'planned'))
for bid, ko, dur, look, *st in BGM:
    add(f'bgm/{bid}', 'bgm', dur, ko, '배경음 (끊김 없이 반복되게)', look + ', seamless loop.', status=st[0] if st else 'planned', kind='audio', ext='ogg')

# ───────── 출력 ─────────
manifest = {'version': 1, 'style': STYLE, 'chapters': [{'n': n, 'ko': k, 'theme': t} for n, k, t in CHAPTERS], 'assets': assets}
os.makedirs(os.path.join(ROOT, 'docs'), exist_ok=True)
json.dump(manifest, open(os.path.join(ROOT, 'docs', 'asset_manifest.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)

cats = {}
for a in assets:
    cats.setdefault(a['category'], []).append(a)
names = {'player': '주인공', 'monster': '몬스터', 'boss': '보스', 'skill': '스킬 아이콘', 'equip': '장비', 'item': '아이템', 'bg': '배경',
         'tile': '타일', 'ui': 'UI', 'codex': '도감', 'sfx': '효과음', 'bgm': '배경음'}
lines = ['# 에셋 전체 목록', '', '`python3 tool/gen_asset_manifest.py` 로 만든 파일이에요. 직접 고치지 말고 생성기를 고쳐요.', '',
         '| 분류 | 전체 | 지금 사용 | 계획 |', '|---|---|---|---|']
for c, items in cats.items():
    used = sum(1 for a in items if a['status'] == 'used')
    lines.append(f'| {names.get(c, c)} | {len(items)} | {used} | {len(items) - used} |')
lines.append(f'| **합계** | **{len(assets)}** | **{sum(1 for a in assets if a["status"] == "used")}** | |')
for c, items in cats.items():
    lines += ['', f'## {names.get(c, c)}', '', '| 상태 | 파일 | 이름 | 규격 | 설명 |', '|---|---|---|---|---|']
    for a in items:
        spec = f"{a['size'][0]}×{a['size'][1]}" if a['type'] == 'image' else f"{a['duration_sec']}초"
        lines.append(f"| {'✅' if a['status'] == 'used' else '·'} | `{a['path']}` | {a['ko']} | {spec} | {a['desc']} |")
open(os.path.join(ROOT, 'docs', 'ASSET_LIST.md'), 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
print('assets', len(assets), {c: len(v) for c, v in cats.items()})
