# 에셋 일괄 생성·교체 가이드

이미지·효과음·배경음을 **로컬에서 자동으로 한꺼번에 만들어 넣기** 위한 기록이에요.
게임은 정해진 경로에 파일이 있으면 그걸 쓰고, 없으면 지금의 벡터 그림과 합성음으로 그려요.
그래서 **파일을 넣고 다시 빌드하기만 하면** 교체돼요. 코드는 고칠 필요 없어요.

- 전체 목록(사람용): [`ASSET_LIST.md`](ASSET_LIST.md)
- 전체 목록(자동화용): [`asset_manifest.json`](asset_manifest.json) — 항목 305개
- 목록 고치기: `tool/gen_asset_manifest.py` 를 고치고 `python3 tool/gen_asset_manifest.py`

---

## 1. 전체 흐름

```
asset_manifest.json 읽기
  └─ 항목마다 (status 로 거르기: 먼저 "used" 부터)
       ├─ 프롬프트 만들기 = style.image_prefix + 항목.prompt + style.<suffix>_suffix
       ├─ Chrome MCP 로 Gemini 열기 → 프롬프트 입력 → 생성 → 이미지 저장
       ├─ 후처리: python3 tool/process_assets.py <받은파일> <항목 id>
       │    (배경 제거 확인, 여백 자르기, 규격 크기로 맞추기, 경로에 저장)
       └─ 다음 항목
python3 tool/check_assets.py   ← 빠진 것·규격이 틀린 것 보고
flutter run                    ← 바로 확인
```

### 로컬 자동화 순서 (Gemini + Chrome MCP)
1. `docs/asset_manifest.json` 을 읽어요.
2. **화풍을 먼저 고정**: `player/full` 하나를 여러 번 뽑아 마음에 드는 걸 고르고, 그 그림을 이후 모든 요청에 **참고 이미지로 첨부**해요. 그래야 그림체가 통일돼요.
3. 항목마다 Chrome MCP 로:
   1. Gemini 대화창에 참고 이미지 + 프롬프트를 넣어요.
      - 이미지 프롬프트 = `style.image_prefix` + `prompt` + (`suffix` 가 `sprite` / `icon` / `bg` / `tile` 이면 각각 `style.sprite_suffix` 등)
      - 끝에 `Avoid: ` + `style.negative`
   2. 생성된 이미지를 내려받아요.
   3. `python3 tool/process_assets.py <내려받은 파일> <id>` 로 정리해서 `path` 위치에 저장해요.
4. 같은 몬스터의 `_charge`(공격 예고 자세)처럼 변형이 필요하면 원본을 참고 이미지로 넣고 "same character, crouching/ready to attack pose" 로 요청해요.
5. 다 끝나면 `python3 tool/check_assets.py` → `flutter run`.

### 효과음·배경음
- `type: "audio"` 항목. `style.audio_prefix` + `prompt` 를 오디오 생성 도구에 넣어요.
- 효과음은 `duration_sec` 길이 안쪽, **앞에 무음 없이** 바로 소리가 나게.
- 배경음은 **끊김 없이 반복**되게 (시작과 끝이 이어지게).
- 저장: `assets/audio/sfx/<이름>.ogg`, `assets/audio/bgm/<이름>.ogg` (mp3, wav 도 돼요).

---

## 2. 폴더와 이름 규칙

| 폴더 | id 예시 | 쓰는 곳 |
|---|---|---|
| `assets/images/player/` | `player/head` | 주인공 부위 / 통짜 / 스킨 |
| `assets/images/monster/` | `monster/slime`, `monster/slime_charge` | 몬스터·보스 (`_charge` = 공격 예고 자세, 선택) |
| `assets/images/skill/` | `skill/fire` | 스킬 아이콘 (레벨업 카드, HUD) |
| `assets/images/equip/` | `equip/bow_moon` | 장비 아이콘 |
| `assets/images/item/` | `item/coin` | 코인, 꿈 조각, 상자, 포털 |
| `assets/images/bg/` | `bg/ch1_far` | 배경 레이어 (챕터별) |
| `assets/images/tile/` | `tile/ch1_ground_top` | 타일 (챕터별) |
| `assets/images/ui/` | `ui/logo` | 로고, 버튼, 메뉴 아이콘, NPC |
| `assets/images/codex/` | `codex/frame` | 도감 |
| `assets/audio/sfx/` | `shoot.ogg` | 효과음 (없으면 `assets/audio/default/` 합성음) |
| `assets/audio/bgm/` | `stage_ch1.ogg` | 배경음 (없으면 무음) |

- 파일 이름 = id 의 `/` 뒤 부분 + 확장자. 소문자와 `_` 만.
- 이미지: **PNG (투명 배경)**. 배경 하늘·지도·메뉴 배경만 불투명.
- 모든 캐릭터·몬스터는 **오른쪽을 보는 옆모습**. 왼쪽은 게임이 뒤집어서 그려요.
- **그림자, 바닥, 글자 넣지 않기** (로고만 예외).
- 그림 주변 여백은 거의 없이(`process_assets.py` 가 잘라줘요).

---

## 3. 규격

| 분류 | 크기(px) | 비고 |
|---|---|---|
| 주인공 부위 | 아래 피벗 표 참고 | 부위마다 비율이 중요해요 |
| 주인공 통짜 `player/full` | 512×704 | 부위 이미지가 없을 때 대신 써요 (움직임은 덜 자연스러움) |
| 몬스터 | 512×512 | 발이 아래 가장자리에 닿게 |
| 보스 | 1024×1024 | |
| 아이콘 (스킬·장비·아이템·메뉴) | 256×256 | 64px 로 줄여도 알아보이게 |
| 배경 레이어 far/mid/near | 4096×1080 | **좌우가 이어지게**, 위·옆을 숲으로 감싸는 구도, 아래 1/3 은 땅에 가려져요 |
| 배경 하늘 | 2048×1080 | 불투명 |
| 타일 | 128×128 (윗면 128×160) | `ground_top` 은 위쪽 32px 이 풀이 삐져나온 부분 |
| 발판 | 128×48 | |

### 주인공 부위 피벗 (종이인형 방식)
캐릭터 높이 약 54(게임 단위) 기준. 게임이 아래 사각형에 이미지를 **꽉 채워** 그려요.
그림을 그 비율에 맞춰야 자연스러워요. (원점 = 발 가운데, 오른쪽 +x, 위쪽 -y)

| id | 그려지는 사각형 (x, y, 너비, 높이) | 회전 중심 | 비율(가로:세로) |
|---|---|---|---|
| `player/leg_back`, `player/leg_front` | (-4, -1, 9, 14) — 엉덩이 기준 | 위쪽 가운데 (엉덩이) | 0.64 |
| `player/cape` | (-21, -33, 20, 28) 달릴수록 왼쪽으로 늘어남 | — | 0.71 |
| `player/body` | (-12, -34, 24, 28) | — | 0.86 |
| `player/head` | (-17, -53, 32, 30) | — | 1.07 |
| `player/bow` | (-6, -16, 22, 32) — 손 위치 기준, 조준 방향으로 회전 | 손(왼쪽 가운데) | 0.69 |

- 다리는 위쪽 가운데가 엉덩이, 아래쪽이 발이에요. 게임이 엉덩이를 축으로 흔들어 달리기를 만들어요.
- 활은 왼쪽 가운데를 손잡이로 그려요. 시위는 왼쪽, 활대는 오른쪽으로 휘게.
- 부위가 하나라도 없으면 그 부위만 벡터로 그려요. 섞여도 깨지지 않아요.

---

## 4. 지금 게임이 찾는 파일 (status = used)

**파일만 넣으면 바로 바뀌어요.** 정확한 목록은 `ASSET_LIST.md` 의 ✅ 표시예요.

- 주인공 부위 7개, 몬스터 6종 + 보스 2종 (+ 각 `_charge` 선택)
- 스킬 아이콘 18개
- 아이템: 코인, 꿈 조각, 회복 하트, 상자(닫힘/열림), 포털(닫힘/열림)
- 1챕터 배경 4장 + 메뉴 배경, 1챕터 타일 9종 + 수정 스위치
- 효과음 27개, 배경음 5개 (타이틀, 지도, 캠프, 1챕터 스테이지, 1챕터 보스)

## 5. 앞으로 만들 시스템이 쓸 파일 (status = planned)

같은 이름 규칙을 그대로 쓰도록 미리 정해뒀어요. 시스템을 만들 때 이 id 로 연결해요.

- 몬스터 30종 + 보스 10종 (2~6챕터), 신규 스킬 22종, 장비 24종 (활·망토·모자·부적), 스킨 4종
- 2~6챕터 배경·타일·배경음, 챕터 지도
- 로비, 상점·출석·미션·도감·장비·랭킹·우편·설정 메뉴 아이콘, 카드 테두리, NPC
- 효과음 13개 (구매, 뽑기, 출석, 미션 완료, 보스 등장 등)

---

## 6. 도구

| 명령 | 하는 일 |
|---|---|
| `python3 tool/gen_asset_manifest.py` | 목록(JSON·MD) 다시 만들기 |
| `python3 tool/process_assets.py 받은파일.png monster/slime` | 여백 자르기 → 규격 크기 안에 비율 유지로 맞추기 → 경로에 저장. 배경이 투명하지 않으면 경고 |
| `python3 tool/process_assets.py --dir 받은폴더/` | 폴더 안 파일 이름이 id 의 마지막 부분과 같으면 한꺼번에 처리 (예: `slime.png` → `monster/slime`) |
| `python3 tool/check_assets.py` | 빠진 파일, 규격 다른 파일, 목록에 없는 파일 보고 |

후처리 도구는 Pillow(`pip install pillow`)가 필요해요. 배경 자동 제거가 필요하면 `pip install rembg` 를 깔면 도구가 알아서 써요.

## 7. 성능 메모
- 이미지는 **필요할 때 불러와요**. 스테이지에 들어갈 때 그 챕터 타일·배경·몬스터·주인공만 미리 불러요.
- 그래도 4096px 배경 여러 장은 메모리를 많이 써요. 출시 전에 WebP 로 바꾸고, 배경은 2048px 로 줄여도 화면 품질 차이가 거의 없어요.
