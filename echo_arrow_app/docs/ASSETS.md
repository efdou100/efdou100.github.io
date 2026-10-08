# 이미지 에셋 목록 (Gemini 프롬프트)

총 68장. 아트 기준은 [ART_DIRECTION.md](ART_DIRECTION.md).

저장 규칙: 받은 이미지를 `raw/<id에서 / 를 __ 로 바꾼 이름>.png` 로 저장 → `python3 tool/process_assets.py raw/` → `python3 tool/check_assets.py`

공통 스타일(모든 프롬프트에 이미 포함):

> hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark

## 캐릭터

### `char/archer_idle` — 512×512 · 투명

```
a tiny chibi forest archer named Lumi, two heads tall, wearing a navy blue hooded cloak whose hood tips look like small cat ears, cream colored round face with two big black dot eyes and pink blush, a small crescent moon brooch, standing calmly facing the viewer, holding a glowing golden crescent-moon bow at the side. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `char/archer_draw` — 512×512 · 투명

```
a tiny chibi forest archer named Lumi, two heads tall, wearing a navy blue hooded cloak whose hood tips look like small cat ears, cream colored round face with two big black dot eyes and pink blush, a small crescent moon brooch, seen from behind three-quarter view, pulling a glowing golden crescent-moon bow upward, determined. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `char/archer_cheer` — 512×512 · 투명
- 메모: 클리어 화면

```
a tiny chibi forest archer named Lumi, two heads tall, wearing a navy blue hooded cloak whose hood tips look like small cat ears, cream colored round face with two big black dot eyes and pink blush, a small crescent moon brooch, jumping with joy, arms up, sparkles around. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `char/bow` — 256×256 · 투명
- 메모: 오른쪽을 향한 활. 코드가 조준 방향으로 회전

```
a glowing golden crescent-moon shaped bow, horizontal, string on the left, bow curve opening to the right, magical soft gold glow. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `char/arrow` — 256×64 · 투명
- 메모: 오른쪽을 향한 화살

```
a slim magical arrow pointing right, golden shaft, glowing star-shaped tip, small feather fletching. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

## 정령

### `spirit/sleep` — 256×256 · 투명

```
a palm-sized round glowing forest spirit called Dozy, perfectly round soft body, two tiny leaf ears like bunny ears on top, pale sky blue glowing body, eyes closed as gentle curved lines, pink blush cheeks, peacefully sleeping. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `spirit/awake` — 256×256 · 투명

```
a palm-sized round glowing forest spirit called Dozy, perfectly round soft body, two tiny leaf ears like bunny ears on top, bright warm golden glowing body, happy smiling eyes shaped like ^ ^, small sparkles around, delighted. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `spirit/baby_sleep` — 256×256 · 투명

```
a palm-sized round glowing forest spirit called Dozy, perfectly round soft body, two tiny leaf ears like bunny ears on top but smaller and baby-like, pastel pink glowing body, sleeping, a small red 'do not touch' prohibition circle sign floating above its head. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `spirit/baby_cry` — 256×256 · 투명

```
a palm-sized round glowing forest spirit called Dozy, perfectly round soft body, two tiny leaf ears like bunny ears on top but smaller and baby-like, pastel pink body, woken up and crying with big tears, upset. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `spirit/shield` — 256×256 · 투명
- 메모: 방패 정령에 겹쳐 그림. 오른쪽이 방패 앞면

```
a silver half-moon shaped shield, curved like a crescent arc, polished metal with soft blue highlights, front view, the arc opens to the left. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

## 장치

### `tile/wood` — 512×64 · 투명
- 메모: 나무 벽. 가로로 반복

```
a horizontal mossy-free wooden log beam, tileable left to right, warm brown bark with light grain, side view. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `tile/moss` — 512×64 · 투명
- 메모: 이끼 벽. 가로로 반복

```
a horizontal strip of thick fluffy glowing green moss, tileable left to right, side view, small dew drops. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `tile/wood_block` — 256×128 · 투명

```
a rectangular wooden plank block, rounded corners, warm brown wood with grain, front view. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `tile/moss_block` — 256×128 · 투명

```
a rectangular block completely covered in fluffy glowing green moss, rounded corners, front view. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `tile/ice` — 256×64 · 투명

```
a horizontal slab of translucent pale blue ice, crystal clear with small cracks, front view. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `device/mirror` — 256×48 · 투명

```
a long thin magical mirror bar, polished silver surface reflecting light, ornate thin gold frame ends, horizontal. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `device/bumper` — 256×256 · 투명

```
a round bouncy forest mushroom cap seen from above-front, glossy pink red cap with cream white spots, short cream stem. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `device/portal_a` — 256×256 · 투명

```
a swirling magical portal ring, warm orange spiral energy around a dark center, front view. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `device/portal_b` — 256×256 · 투명

```
a swirling magical portal ring, cool blue spiral energy around a dark center, front view. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `device/prism` — 256×256 · 투명

```
a floating diamond-shaped rainbow prism crystal, faceted, refracting rainbow light, front view. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `device/switch_off` — 256×256 · 투명

```
a round ancient stone rune button, dark slate with a faint cyan triangle rune, front view. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `device/switch_on` — 256×256 · 투명

```
a round ancient stone rune button glowing bright cyan, triangle rune shining, energy sparkles, front view. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `device/gate` — 512×48 · 투명

```
a horizontal magical barrier bar of violet energy with flowing runes, tileable left to right. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

## 배경

### `bg/world1_game` — 1080×1920
- 메모: 게임 화면

```
vertical mobile game background, an enchanted night forest with old oak trees at the left and right edges, fireflies, mossy rocks at the bottom, a huge full moon behind clouds at the top. The center 70% of the image is dark, calm and empty for gameplay, decorations only near the edges and bottom, a small flat grassy ledge at the bottom center. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. full-bleed scene, no border
```

### `bg/world1_map` — 1080×2700
- 메모: 홈 지도. 세로로 이어 붙임

```
tall vertical world map background for a level select screen, an enchanted night forest with old oak trees at the left and right edges, fireflies, mossy rocks at the bottom, a huge full moon behind clouds at the top, a winding dirt path area in the middle left empty, lush scenery along both sides, seamless top and bottom edges. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. full-bleed scene, no border
```

### `bg/world2_game` — 1080×1920
- 메모: 게임 화면

```
vertical mobile game background, a silver misty birch forest at night with floating mirror shards glinting at the edges, pale blue fog. The center 70% of the image is dark, calm and empty for gameplay, decorations only near the edges and bottom, a small flat grassy ledge at the bottom center. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. full-bleed scene, no border
```

### `bg/world2_map` — 1080×2700
- 메모: 홈 지도. 세로로 이어 붙임

```
tall vertical world map background for a level select screen, a silver misty birch forest at night with floating mirror shards glinting at the edges, pale blue fog, a winding dirt path area in the middle left empty, lush scenery along both sides, seamless top and bottom edges. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. full-bleed scene, no border
```

### `bg/world3_game` — 1080×1920
- 메모: 게임 화면

```
vertical mobile game background, a glowing crystal cave with purple and teal crystal pillars at the edges, sparkling ore on the dark ceiling like stars. The center 70% of the image is dark, calm and empty for gameplay, decorations only near the edges and bottom, a small flat grassy ledge at the bottom center. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. full-bleed scene, no border
```

### `bg/world3_map` — 1080×2700
- 메모: 홈 지도. 세로로 이어 붙임

```
tall vertical world map background for a level select screen, a glowing crystal cave with purple and teal crystal pillars at the edges, sparkling ore on the dark ceiling like stars, a winding dirt path area in the middle left empty, lush scenery along both sides, seamless top and bottom edges. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. full-bleed scene, no border
```

### `bg/world4_game` — 1080×1920
- 메모: 게임 화면

```
vertical mobile game background, a deep valley at night with flowing green and violet aurora in the sky, floating ancient rune stones and an old stone arch at the edges. The center 70% of the image is dark, calm and empty for gameplay, decorations only near the edges and bottom, a small flat grassy ledge at the bottom center. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. full-bleed scene, no border
```

### `bg/world4_map` — 1080×2700
- 메모: 홈 지도. 세로로 이어 붙임

```
tall vertical world map background for a level select screen, a deep valley at night with flowing green and violet aurora in the sky, floating ancient rune stones and an old stone arch at the edges, a winding dirt path area in the middle left empty, lush scenery along both sides, seamless top and bottom edges. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. full-bleed scene, no border
```

### `bg/world5_game` — 1080×1920
- 메모: 게임 화면

```
vertical mobile game background, floating islands in outer space, a bright milky way, shooting stars, golden starlight. The center 70% of the image is dark, calm and empty for gameplay, decorations only near the edges and bottom, a small flat grassy ledge at the bottom center. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. full-bleed scene, no border
```

### `bg/world5_map` — 1080×2700
- 메모: 홈 지도. 세로로 이어 붙임

```
tall vertical world map background for a level select screen, floating islands in outer space, a bright milky way, shooting stars, golden starlight, a winding dirt path area in the middle left empty, lush scenery along both sides, seamless top and bottom edges. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. full-bleed scene, no border
```

### `bg/home_sky` — 1080×1920

```
a calm deep indigo night sky with soft clouds, many tiny stars and a big glowing crescent moon at the upper right. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. full-bleed scene, no border
```

## 지도

### `map/node_open` — 256×256 · 투명

```
a round stepping-stone medallion for a level select map, smooth blue-grey stone with a soft silver rim, top-down slightly tilted. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `map/node_current` — 256×256 · 투명

```
a round stepping-stone medallion glowing warm gold, magical light rising from it, slightly tilted top view. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `map/node_locked` — 256×256 · 투명

```
a round dark mossy stepping-stone with a small iron padlock, dim, slightly tilted top view. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `map/node_boss` — 256×256 · 투명

```
a large ornate round stone medallion with a golden crown emblem and moon carvings, glowing, slightly tilted top view. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `map/node_hard` — 256×256 · 투명

```
a round stepping-stone medallion with a red magical flame ring around it, slightly tilted top view. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

## UI

### `ui/coin` — 256×256 · 투명

```
a shiny gold coin with an engraved crescent moon. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/heart` — 256×256 · 투명

```
a glossy plump red heart with a white highlight. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/heart_inf` — 256×256 · 투명

```
a glossy plump cyan heart with an infinity symbol glow. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/star` — 256×256 · 투명

```
a plump glowing golden star. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/chest` — 256×256 · 투명

```
a small wooden treasure chest with gold trim, closed, glowing light leaking from the seams. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/chest_open` — 256×256 · 투명

```
a small wooden treasure chest with gold trim, open, bright golden light and coins bursting out. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/booster_aim` — 256×256 · 투명

```
a magical golden dotted guiding line with three bounce sparkles, icon. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/booster_extra` — 256×256 · 투명

```
a single golden glowing arrow with a plus sparkle, icon. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/booster_split` — 256×256 · 투명

```
a golden arrow splitting into three glowing branches, icon. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/hint` — 256×256 · 투명

```
a glowing lightbulb made of moonlight, icon. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/icon_checkin` — 256×256 · 투명

```
a cute calendar page with a red ribbon and a gold star sticker, icon. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/icon_daily` — 256×256 · 투명

```
a small sunrise over a hill with a single arrow, icon. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/icon_streak` — 256×256 · 투명

```
a cute magical cyan flame, icon. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/icon_shop` — 256×256 · 투명

```
a cute merchant bag full of gold coins, icon. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/icon_pass` — 256×256 · 투명

```
a golden medal ribbon with a moon emblem, icon. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/icon_gift` — 256×256 · 투명

```
a wrapped gift box with a gold ribbon, icon. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/icon_settings` — 256×256 · 투명

```
a cute brass gear, icon. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `ui/logo` — 1024×512 · 투명
- 메모: 로고만 글자 허용. 한국어판은 코드 글자 사용

```
game logo text 'ECHO ARROW' in rounded bold golden letters with a glowing cyan O shaped like a ripple, a crescent moon bow behind the text. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

## 상점

### `shop/starter` — 256×256 · 투명

```
a bundle of a gold coin pile, three magical arrows and a small heart, gift ribbon. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `shop/noads` — 256×256 · 투명

```
a cute scroll with a crossed-out play button, icon. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `shop/piggy` — 256×256 · 투명

```
a cute round glass jar shaped like a sleeping spirit, filled with glowing gold coins. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `shop/pass` — 256×256 · 투명

```
a golden ticket with a crescent moon and arrow emblem. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `shop/coins_s` — 256×256 · 투명

```
a small handful of gold moon coins. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `shop/coins_m` — 256×256 · 투명

```
a cloth pouch of gold moon coins. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `shop/coins_l` — 256×256 · 투명

```
a wooden box full of gold moon coins. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `shop/coins_xl` — 256×256 · 투명

```
a big treasure chest overflowing with gold moon coins. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

### `shop/coins_xxl` — 256×256 · 투명

```
a huge mountain of gold moon coins with gems, glowing. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```

## 아이콘

### `icon/app_icon` — 1024×1024
- 메모: flutter_launcher_icons 원본

```
app icon, a tiny chibi forest archer named Lumi, two heads tall, wearing a navy blue hooded cloak whose hood tips look like small cat ears, cream colored round face with two big black dot eyes and pink blush, a small crescent moon brooch drawing a glowing golden crescent-moon bow, a glowing cyan arrow trail echo behind, deep indigo background, bold readable silhouette. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. full-bleed scene, no border
```

### `icon/app_icon_fg` — 1024×1024 · 투명
- 메모: 안드로이드 적응형 아이콘 전경(가운데 66%만 보임)

```
app icon foreground only, a tiny chibi forest archer named Lumi, two heads tall, wearing a navy blue hooded cloak whose hood tips look like small cat ears, cream colored round face with two big black dot eyes and pink blush, a small crescent moon brooch drawing a glowing golden crescent-moon bow, centered with generous padding. hand-painted storybook illustration, soft painterly brush texture, cute rounded shapes, warm golden moonlight rim light from the upper left, deep indigo shadows, gentle glow, mobile puzzle game asset, high quality, clean silhouette, no text, no watermark. isolated, centered, on a solid pure green (#00FF00) background, no shadow on the background
```
