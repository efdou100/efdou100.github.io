# 에셋 전체 목록

`python3 tool/gen_asset_manifest.py` 로 만든 파일이에요. 직접 고치지 말고 생성기를 고쳐요.

| 분류 | 전체 | 지금 사용 | 계획 |
|---|---|---|---|
| 주인공 | 11 | 7 | 4 |
| 몬스터 | 36 | 6 | 30 |
| 보스 | 12 | 2 | 10 |
| 스킬 아이콘 | 40 | 18 | 22 |
| 장비 | 24 | 0 | 24 |
| 아이템 | 15 | 7 | 8 |
| 배경 | 32 | 5 | 27 |
| 타일 | 55 | 10 | 45 |
| UI | 22 | 0 | 22 |
| 도감 | 2 | 0 | 2 |
| 효과음 | 40 | 27 | 13 |
| 배경음 | 16 | 5 | 11 |
| **합계** | **305** | **87** | |

## 주인공

| 상태 | 파일 | 이름 | 규격 | 설명 |
|---|---|---|---|---|
| ✅ | `assets/images/player/head.png` | 머리(후드+얼굴) | 512×480 | 주인공 부위. 피벗은 docs/ASSET_PIPELINE.md 표 참고 |
| ✅ | `assets/images/player/body.png` | 몸통 | 384×448 | 주인공 부위. 피벗은 docs/ASSET_PIPELINE.md 표 참고 |
| ✅ | `assets/images/player/cape.png` | 망토 뒷자락 | 384×448 | 주인공 부위. 피벗은 docs/ASSET_PIPELINE.md 표 참고 |
| ✅ | `assets/images/player/leg_front.png` | 앞다리 | 160×256 | 주인공 부위. 피벗은 docs/ASSET_PIPELINE.md 표 참고 |
| ✅ | `assets/images/player/leg_back.png` | 뒷다리 | 160×256 | 주인공 부위. 피벗은 docs/ASSET_PIPELINE.md 표 참고 |
| ✅ | `assets/images/player/bow.png` | 활 | 288×448 | 주인공 부위. 피벗은 docs/ASSET_PIPELINE.md 표 참고 |
| ✅ | `assets/images/player/full.png` | 통짜 캐릭터(부위가 없을 때 대체) | 512×704 | 주인공 부위. 피벗은 docs/ASSET_PIPELINE.md 표 참고 |
| · | `assets/images/player/skin_moon_full.png` | 달빛 궁수 | 512×704 | 스킨(상점·이벤트 보상) |
| · | `assets/images/player/skin_ember_full.png` | 잿불 궁수 | 512×704 | 스킨(상점·이벤트 보상) |
| · | `assets/images/player/skin_frost_full.png` | 서리 궁수 | 512×704 | 스킨(상점·이벤트 보상) |
| · | `assets/images/player/skin_star_full.png` | 별의 궁수 | 512×704 | 스킨(상점·이벤트 보상) |

## 몬스터

| 상태 | 파일 | 이름 | 규격 | 설명 |
|---|---|---|---|---|
| ✅ | `assets/images/monster/slime.png` | 슬라임 | 512×512 | 1챕터 · 천천히 다가오다 웅크린 뒤 덮쳐요 |
| ✅ | `assets/images/monster/slime_split.png` | 분열 슬라임 | 512×512 | 1챕터 · 쓰러지면 작은 슬라임 둘로 나뉘어요 |
| ✅ | `assets/images/monster/slime_mini.png` | 꼬마 슬라임 | 512×512 | 1챕터 · 분열 슬라임에서 나와요. 빠르고 약해요 |
| ✅ | `assets/images/monster/mush_spore.png` | 포자버섯 | 512×512 | 1챕터 · 부풀었다가 포자 3발을 쏴요 |
| ✅ | `assets/images/monster/bat.png` | 박쥐 | 512×512 | 1챕터 · 조준선을 그린 뒤 돌진해요 |
| ✅ | `assets/images/monster/wisp.png` | 도깨비불 | 512×512 | 1챕터 · 거리를 두고 유도탄을 쏴요 |
| · | `assets/images/monster/cave_beetle.png` | 수정 딱정벌레 | 512×512 | 2챕터 · 등껍질이 단단해 앞에서는 피해가 줄어요 |
| · | `assets/images/monster/glow_snail.png` | 빛 달팽이 | 512×512 | 2챕터 · 느리지만 지나간 자리에 독 점액을 남겨요 |
| · | `assets/images/monster/spore_puff.png` | 포자 복어 | 512×512 | 2챕터 · 터지면서 주변에 포자를 흩뿌려요 |
| · | `assets/images/monster/cave_bat_king.png` | 동굴 큰박쥐 | 512×512 | 2챕터 · 세 마리가 함께 돌진해요 |
| · | `assets/images/monster/rock_golem_mini.png` | 꼬마 바위 골렘 | 512×512 | 2챕터 · 느리게 걷다 땅을 쳐서 충격파를 보내요 |
| · | `assets/images/monster/crystal_imp.png` | 수정 도깨비 | 512×512 | 2챕터 · 순간이동하며 수정 조각을 던져요 |
| · | `assets/images/monster/frog_knight.png` | 개구리 기사 | 512×512 | 3챕터 · 방패로 막다가 혀로 끌어당겨요 |
| · | `assets/images/monster/swamp_eel.png` | 늪 장어 | 512×512 | 3챕터 · 물 위로 튀어올라 포물선으로 덮쳐요 |
| · | `assets/images/monster/mist_ghost.png` | 안개 유령 | 512×512 | 3챕터 · 반투명해졌다 나타나며 공격해요 |
| · | `assets/images/monster/lily_turtle.png` | 연잎 거북 | 512×512 | 3챕터 · 등이 발판이 돼요. 공격하면 숨어요 |
| · | `assets/images/monster/mosquito.png` | 대왕 모기 | 512×512 | 3챕터 · 빠르게 지그재그로 날아와요 |
| · | `assets/images/monster/root_snake.png` | 뿌리 뱀 | 512×512 | 3챕터 · 땅속에서 솟아올라 물어요 |
| · | `assets/images/monster/snow_bunny.png` | 눈토끼 | 512×512 | 4챕터 · 높이 뛰어 위에서 내려찍어요 |
| · | `assets/images/monster/ice_slime.png` | 얼음 슬라임 | 512×512 | 4챕터 · 닿으면 잠깐 느려져요 |
| · | `assets/images/monster/frost_owl.png` | 서리 부엉이 | 512×512 | 4챕터 · 위에서 얼음 깃털을 흩뿌려요 |
| · | `assets/images/monster/yeti_cub.png` | 아기 설인 | 512×512 | 4챕터 · 눈덩이를 굴려 보내요 |
| · | `assets/images/monster/icicle_bat.png` | 고드름 박쥐 | 512×512 | 4챕터 · 천장에 매달렸다 떨어져요 |
| · | `assets/images/monster/aurora_wisp.png` | 오로라 정령 | 512×512 | 4챕터 · 색이 바뀔 때마다 패턴이 달라져요 |
| · | `assets/images/monster/ember_slime.png` | 잿불 슬라임 | 512×512 | 5챕터 · 쓰러진 자리에 불길을 남겨요 |
| · | `assets/images/monster/fire_fox.png` | 불여우 | 512×512 | 5챕터 · 불꽃 꼬리로 빠르게 돌진해요 |
| · | `assets/images/monster/magma_crab.png` | 용암 게 | 512×512 | 5챕터 · 집게로 막고 화염탄을 쏴요 |
| · | `assets/images/monster/ash_crow.png` | 잿빛 까마귀 | 512×512 | 5챕터 · 무리지어 위에서 급강하해요 |
| · | `assets/images/monster/lava_golem.png` | 용암 골렘 | 512×512 | 5챕터 · 느리지만 아주 단단해요 |
| · | `assets/images/monster/fire_sprite.png` | 불꽃 요정 | 512×512 | 5챕터 · 불꽃 고리를 퍼뜨려요 |
| · | `assets/images/monster/star_jelly.png` | 별 해파리 | 512×512 | 6챕터 · 천천히 떠다니며 별가루를 떨어뜨려요 |
| · | `assets/images/monster/cloud_sheep.png` | 구름 양 | 512×512 | 6챕터 · 구름 발판을 만들었다 없애요 |
| · | `assets/images/monster/comet_bird.png` | 혜성 새 | 512×512 | 6챕터 · 꼬리를 끌며 직선으로 돌진해요 |
| · | `assets/images/monster/moon_knight.png` | 달 기사 | 512×512 | 6챕터 · 초승달 검기를 날려요 |
| · | `assets/images/monster/nebula_eye.png` | 성운의 눈 | 512×512 | 6챕터 · 레이저를 회전하며 쏴요 |
| · | `assets/images/monster/crystal_dragonling.png` | 수정 아기용 | 512×512 | 6챕터 · 수정 숨결을 뿜어요 |

## 보스

| 상태 | 파일 | 이름 | 규격 | 설명 |
|---|---|---|---|---|
| ✅ | `assets/images/monster/boss_king_slime.png` | 킹 슬라임 | 1024×1024 | 1챕터 보스 · 착지 지점 표시 → 쿵! 땅을 타는 충격파 |
| ✅ | `assets/images/monster/boss_dream_lord.png` | 꿈의 군주 | 1024×1024 | 1챕터 보스 · 포자 비, 돌진, 소환, 회전탄 |
| · | `assets/images/monster/boss_crystal_queen.png` | 수정 여왕 거미 | 1024×1024 | 2챕터 보스 · 거미줄로 발판을 묶고 수정을 쏴요 |
| · | `assets/images/monster/boss_mushroom_titan.png` | 버섯 거인 | 1024×1024 | 2챕터 보스 · 몸에서 버섯이 자라 소환해요 |
| · | `assets/images/monster/boss_swamp_hag.png` | 늪 마녀 | 1024×1024 | 3챕터 보스 · 독 웅덩이와 개구리 소환 |
| · | `assets/images/monster/boss_hydra.png` | 늪 히드라 | 1024×1024 | 3챕터 보스 · 머리 셋이 따로 공격해요 |
| · | `assets/images/monster/boss_frost_yeti.png` | 서리 설인왕 | 1024×1024 | 4챕터 보스 · 얼음 기둥을 세우고 눈사태 |
| · | `assets/images/monster/boss_aurora_stag.png` | 오로라 사슴 | 1024×1024 | 4챕터 보스 · 빛의 길을 따라 돌진해요 |
| · | `assets/images/monster/boss_lava_dragon.png` | 용암 드래곤 | 1024×1024 | 5챕터 보스 · 화염 숨결과 용암 비 |
| · | `assets/images/monster/boss_phoenix.png` | 불사조 | 1024×1024 | 5챕터 보스 · 쓰러지면 한 번 되살아나요 |
| · | `assets/images/monster/boss_star_whale.png` | 별고래 | 1024×1024 | 6챕터 보스 · 하늘섬 사이를 헤엄치며 공격 |
| · | `assets/images/monster/boss_dream_eater.png` | 꿈을 먹는 자 | 1024×1024 | 6챕터 보스 · 최종 보스. 지금까지의 패턴을 섞어 써요 |

## 스킬 아이콘

| 상태 | 파일 | 이름 | 규격 | 설명 |
|---|---|---|---|---|
| ✅ | `assets/images/skill/multishot.png` | 멀티샷 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/front.png` | 정면 화살 +1 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/diagonal.png` | 사선 화살 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/back.png` | 뒤쪽 화살 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/pierce.png` | 관통 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/ricochet.png` | 벽 도탄 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/fire.png` | 화염 화살 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/frost.png` | 빙결 화살 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/lightning.png` | 번개 화살 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/attack.png` | 공격력 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/haste.png` | 속사 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/crit.png` | 급소 노리기 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/orbit.png` | 수호 구슬 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/vampire.png` | 흡혈 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/heart.png` | 생명의 이슬 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/shield.png` | 나뭇잎 방패 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/focus.png` | 깊은 집중 | 256×256 | 스킬 아이콘 |
| ✅ | `assets/images/skill/chain.png` | 연쇄 화살 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/ground_bounce.png` | 물수제비 화살 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/arrow_rain.png` | 화살비 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/sky_shot.png` | 내려찍기 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/boomerang.png` | 부메랑 화살 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/split_arrow.png` | 세 갈래 화살 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/giant_arrow.png` | 거대 화살 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/explosive.png` | 폭발 화살 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/poison.png` | 독 화살 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/wind.png` | 바람 화살 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/homing.png` | 유도 화살 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/wall_splat.png` | 벽 꽂기 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/juggle.png` | 띄우기 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/ice_nova.png` | 얼음 폭발 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/thunder.png` | 천둥 소환 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/clone.png` | 그림자 분신 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/owl_pet.png` | 부엉이 친구 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/magnet.png` | 자석 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/gold_rush.png` | 황금 사냥 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/xp_boost.png` | 깨달음 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/revive.png` | 불사조 깃털 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/thorns.png` | 가시 갑옷 | 256×256 | 스킬 아이콘 |
| · | `assets/images/skill/slow_aura.png` | 시간의 고리 | 256×256 | 스킬 아이콘 |

## 장비

| 상태 | 파일 | 이름 | 규격 | 설명 |
|---|---|---|---|---|
| · | `assets/images/equip/bow_oak.png` | 참나무 활 | 256×256 | 일반 등급 장비 |
| · | `assets/images/equip/bow_moon.png` | 달빛 활 | 256×256 | 일반 등급 장비 |
| · | `assets/images/equip/bow_ember.png` | 잿불 활 | 256×256 | 희귀 등급 장비 |
| · | `assets/images/equip/bow_frost.png` | 서리 활 | 256×256 | 영웅 등급 장비 |
| · | `assets/images/equip/bow_star.png` | 별빛 활 | 256×256 | 영웅 등급 장비 |
| · | `assets/images/equip/bow_dream.png` | 꿈결 활 | 256×256 | 전설 등급 장비 |
| · | `assets/images/equip/cloak_moss.png` | 이끼 망토 | 256×256 | 일반 등급 장비 |
| · | `assets/images/equip/cloak_night.png` | 밤하늘 망토 | 256×256 | 일반 등급 장비 |
| · | `assets/images/equip/cloak_flame.png` | 불꽃 망토 | 256×256 | 희귀 등급 장비 |
| · | `assets/images/equip/cloak_aurora.png` | 오로라 망토 | 256×256 | 영웅 등급 장비 |
| · | `assets/images/equip/cloak_cloud.png` | 구름 망토 | 256×256 | 영웅 등급 장비 |
| · | `assets/images/equip/cloak_dream.png` | 꿈결 망토 | 256×256 | 전설 등급 장비 |
| · | `assets/images/equip/hood_leaf.png` | 나뭇잎 모자 | 256×256 | 일반 등급 장비 |
| · | `assets/images/equip/hood_owl.png` | 부엉이 모자 | 256×256 | 일반 등급 장비 |
| · | `assets/images/equip/hood_fox.png` | 여우 모자 | 256×256 | 희귀 등급 장비 |
| · | `assets/images/equip/hood_snow.png` | 눈꽃 모자 | 256×256 | 영웅 등급 장비 |
| · | `assets/images/equip/hood_crown.png` | 작은 왕관 모자 | 256×256 | 영웅 등급 장비 |
| · | `assets/images/equip/hood_dream.png` | 꿈결 모자 | 256×256 | 전설 등급 장비 |
| · | `assets/images/equip/charm_acorn.png` | 도토리 부적 | 256×256 | 일반 등급 장비 |
| · | `assets/images/equip/charm_feather.png` | 깃털 부적 | 256×256 | 일반 등급 장비 |
| · | `assets/images/equip/charm_crystal.png` | 수정 부적 | 256×256 | 희귀 등급 장비 |
| · | `assets/images/equip/charm_ember.png` | 불씨 부적 | 256×256 | 영웅 등급 장비 |
| · | `assets/images/equip/charm_star.png` | 별조각 부적 | 256×256 | 영웅 등급 장비 |
| · | `assets/images/equip/charm_dream.png` | 꿈결 부적 | 256×256 | 전설 등급 장비 |

## 아이템

| 상태 | 파일 | 이름 | 규격 | 설명 |
|---|---|---|---|---|
| ✅ | `assets/images/item/coin.png` | 코인 | 256×256 | 아이템 |
| ✅ | `assets/images/item/dream_shard.png` | 꿈 조각 | 256×256 | 아이템 |
| ✅ | `assets/images/item/heal_heart.png` | 회복 하트 | 256×256 | 아이템 |
| ✅ | `assets/images/item/chest_closed.png` | 보물상자(닫힘) | 256×256 | 아이템 |
| ✅ | `assets/images/item/chest_open.png` | 보물상자(열림) | 256×256 | 아이템 |
| ✅ | `assets/images/item/portal_closed.png` | 포털(닫힘) | 256×256 | 아이템 |
| ✅ | `assets/images/item/portal_open.png` | 포털(열림) | 256×256 | 아이템 |
| · | `assets/images/item/gem.png` | 보석 | 256×256 | 아이템 |
| · | `assets/images/item/energy.png` | 에너지 | 256×256 | 아이템 |
| · | `assets/images/item/ticket.png` | 도전 티켓 | 256×256 | 아이템 |
| · | `assets/images/item/key.png` | 열쇠 | 256×256 | 아이템 |
| · | `assets/images/item/chest_silver.png` | 은 상자 | 256×256 | 아이템 |
| · | `assets/images/item/chest_gold.png` | 금 상자 | 256×256 | 아이템 |
| · | `assets/images/item/chest_dream.png` | 꿈의 상자 | 256×256 | 아이템 |
| · | `assets/images/item/scroll.png` | 강화 주문서 | 256×256 | 아이템 |

## 배경

| 상태 | 파일 | 이름 | 규격 | 설명 |
|---|---|---|---|---|
| ✅ | `assets/images/bg/ch1_sky.png` | 잠든 숲 하늘 | 2048×1080 | 가장 뒤 하늘 (불투명) |
| ✅ | `assets/images/bg/ch1_far.png` | 잠든 숲 먼 풍경 | 4096×1080 | 시차 0.12 |
| ✅ | `assets/images/bg/ch1_mid.png` | 잠든 숲 중간 숲 | 4096×1080 | 시차 0.3 |
| ✅ | `assets/images/bg/ch1_near.png` | 잠든 숲 가까운 숲 | 4096×1080 | 시차 0.55, 아래쪽은 땅에 가려져요 |
| · | `assets/images/bg/map_ch1.png` | 잠든 숲 지도 | 2560×1080 | 스테이지 지도 배경 |
| · | `assets/images/bg/ch2_sky.png` | 버섯 동굴 하늘 | 2048×1080 | 가장 뒤 하늘 (불투명) |
| · | `assets/images/bg/ch2_far.png` | 버섯 동굴 먼 풍경 | 4096×1080 | 시차 0.12 |
| · | `assets/images/bg/ch2_mid.png` | 버섯 동굴 중간 숲 | 4096×1080 | 시차 0.3 |
| · | `assets/images/bg/ch2_near.png` | 버섯 동굴 가까운 숲 | 4096×1080 | 시차 0.55, 아래쪽은 땅에 가려져요 |
| · | `assets/images/bg/map_ch2.png` | 버섯 동굴 지도 | 2560×1080 | 스테이지 지도 배경 |
| · | `assets/images/bg/ch3_sky.png` | 안개 늪 하늘 | 2048×1080 | 가장 뒤 하늘 (불투명) |
| · | `assets/images/bg/ch3_far.png` | 안개 늪 먼 풍경 | 4096×1080 | 시차 0.12 |
| · | `assets/images/bg/ch3_mid.png` | 안개 늪 중간 숲 | 4096×1080 | 시차 0.3 |
| · | `assets/images/bg/ch3_near.png` | 안개 늪 가까운 숲 | 4096×1080 | 시차 0.55, 아래쪽은 땅에 가려져요 |
| · | `assets/images/bg/map_ch3.png` | 안개 늪 지도 | 2560×1080 | 스테이지 지도 배경 |
| · | `assets/images/bg/ch4_sky.png` | 눈꽃 고원 하늘 | 2048×1080 | 가장 뒤 하늘 (불투명) |
| · | `assets/images/bg/ch4_far.png` | 눈꽃 고원 먼 풍경 | 4096×1080 | 시차 0.12 |
| · | `assets/images/bg/ch4_mid.png` | 눈꽃 고원 중간 숲 | 4096×1080 | 시차 0.3 |
| · | `assets/images/bg/ch4_near.png` | 눈꽃 고원 가까운 숲 | 4096×1080 | 시차 0.55, 아래쪽은 땅에 가려져요 |
| · | `assets/images/bg/map_ch4.png` | 눈꽃 고원 지도 | 2560×1080 | 스테이지 지도 배경 |
| · | `assets/images/bg/ch5_sky.png` | 잿불 화산숲 하늘 | 2048×1080 | 가장 뒤 하늘 (불투명) |
| · | `assets/images/bg/ch5_far.png` | 잿불 화산숲 먼 풍경 | 4096×1080 | 시차 0.12 |
| · | `assets/images/bg/ch5_mid.png` | 잿불 화산숲 중간 숲 | 4096×1080 | 시차 0.3 |
| · | `assets/images/bg/ch5_near.png` | 잿불 화산숲 가까운 숲 | 4096×1080 | 시차 0.55, 아래쪽은 땅에 가려져요 |
| · | `assets/images/bg/map_ch5.png` | 잿불 화산숲 지도 | 2560×1080 | 스테이지 지도 배경 |
| · | `assets/images/bg/ch6_sky.png` | 별빛 하늘섬 하늘 | 2048×1080 | 가장 뒤 하늘 (불투명) |
| · | `assets/images/bg/ch6_far.png` | 별빛 하늘섬 먼 풍경 | 4096×1080 | 시차 0.12 |
| · | `assets/images/bg/ch6_mid.png` | 별빛 하늘섬 중간 숲 | 4096×1080 | 시차 0.3 |
| · | `assets/images/bg/ch6_near.png` | 별빛 하늘섬 가까운 숲 | 4096×1080 | 시차 0.55, 아래쪽은 땅에 가려져요 |
| · | `assets/images/bg/map_ch6.png` | 별빛 하늘섬 지도 | 2560×1080 | 스테이지 지도 배경 |
| ✅ | `assets/images/bg/menu.png` | 메뉴 배경 | 2560×1440 | 타이틀·캠프 화면 |
| · | `assets/images/bg/lobby.png` | 로비(캠프) 배경 | 2560×1440 | 홈 화면: 모닥불과 텐트 |

## 타일

| 상태 | 파일 | 이름 | 규격 | 설명 |
|---|---|---|---|---|
| ✅ | `assets/images/tile/ch1_ground.png` | 잠든 숲 흙 속 | 128×128 | 타일 |
| ✅ | `assets/images/tile/ch1_ground_top.png` | 잠든 숲 윗면(풀) | 128×160 | 타일 |
| ✅ | `assets/images/tile/ch1_plank.png` | 잠든 숲 나무 발판 | 128×48 | 타일 |
| ✅ | `assets/images/tile/ch1_crumble.png` | 잠든 숲 부서지는 발판 | 128×48 | 타일 |
| ✅ | `assets/images/tile/ch1_spring.png` | 잠든 숲 스프링 버섯 | 160×160 | 타일 |
| ✅ | `assets/images/tile/ch1_thorn.png` | 잠든 숲 가시덩굴 | 128×128 | 타일 |
| ✅ | `assets/images/tile/ch1_bridge.png` | 잠든 숲 수정 다리 | 128×48 | 타일 |
| ✅ | `assets/images/tile/ch1_mover.png` | 잠든 숲 움직이는 발판 | 256×64 | 타일 |
| ✅ | `assets/images/tile/ch1_lift.png` | 잠든 숲 승강 발판 | 256×64 | 타일 |
| · | `assets/images/tile/ch2_ground.png` | 버섯 동굴 흙 속 | 128×128 | 타일 |
| · | `assets/images/tile/ch2_ground_top.png` | 버섯 동굴 윗면(풀) | 128×160 | 타일 |
| · | `assets/images/tile/ch2_plank.png` | 버섯 동굴 나무 발판 | 128×48 | 타일 |
| · | `assets/images/tile/ch2_crumble.png` | 버섯 동굴 부서지는 발판 | 128×48 | 타일 |
| · | `assets/images/tile/ch2_spring.png` | 버섯 동굴 스프링 버섯 | 160×160 | 타일 |
| · | `assets/images/tile/ch2_thorn.png` | 버섯 동굴 가시덩굴 | 128×128 | 타일 |
| · | `assets/images/tile/ch2_bridge.png` | 버섯 동굴 수정 다리 | 128×48 | 타일 |
| · | `assets/images/tile/ch2_mover.png` | 버섯 동굴 움직이는 발판 | 256×64 | 타일 |
| · | `assets/images/tile/ch2_lift.png` | 버섯 동굴 승강 발판 | 256×64 | 타일 |
| · | `assets/images/tile/ch3_ground.png` | 안개 늪 흙 속 | 128×128 | 타일 |
| · | `assets/images/tile/ch3_ground_top.png` | 안개 늪 윗면(풀) | 128×160 | 타일 |
| · | `assets/images/tile/ch3_plank.png` | 안개 늪 나무 발판 | 128×48 | 타일 |
| · | `assets/images/tile/ch3_crumble.png` | 안개 늪 부서지는 발판 | 128×48 | 타일 |
| · | `assets/images/tile/ch3_spring.png` | 안개 늪 스프링 버섯 | 160×160 | 타일 |
| · | `assets/images/tile/ch3_thorn.png` | 안개 늪 가시덩굴 | 128×128 | 타일 |
| · | `assets/images/tile/ch3_bridge.png` | 안개 늪 수정 다리 | 128×48 | 타일 |
| · | `assets/images/tile/ch3_mover.png` | 안개 늪 움직이는 발판 | 256×64 | 타일 |
| · | `assets/images/tile/ch3_lift.png` | 안개 늪 승강 발판 | 256×64 | 타일 |
| · | `assets/images/tile/ch4_ground.png` | 눈꽃 고원 흙 속 | 128×128 | 타일 |
| · | `assets/images/tile/ch4_ground_top.png` | 눈꽃 고원 윗면(풀) | 128×160 | 타일 |
| · | `assets/images/tile/ch4_plank.png` | 눈꽃 고원 나무 발판 | 128×48 | 타일 |
| · | `assets/images/tile/ch4_crumble.png` | 눈꽃 고원 부서지는 발판 | 128×48 | 타일 |
| · | `assets/images/tile/ch4_spring.png` | 눈꽃 고원 스프링 버섯 | 160×160 | 타일 |
| · | `assets/images/tile/ch4_thorn.png` | 눈꽃 고원 가시덩굴 | 128×128 | 타일 |
| · | `assets/images/tile/ch4_bridge.png` | 눈꽃 고원 수정 다리 | 128×48 | 타일 |
| · | `assets/images/tile/ch4_mover.png` | 눈꽃 고원 움직이는 발판 | 256×64 | 타일 |
| · | `assets/images/tile/ch4_lift.png` | 눈꽃 고원 승강 발판 | 256×64 | 타일 |
| · | `assets/images/tile/ch5_ground.png` | 잿불 화산숲 흙 속 | 128×128 | 타일 |
| · | `assets/images/tile/ch5_ground_top.png` | 잿불 화산숲 윗면(풀) | 128×160 | 타일 |
| · | `assets/images/tile/ch5_plank.png` | 잿불 화산숲 나무 발판 | 128×48 | 타일 |
| · | `assets/images/tile/ch5_crumble.png` | 잿불 화산숲 부서지는 발판 | 128×48 | 타일 |
| · | `assets/images/tile/ch5_spring.png` | 잿불 화산숲 스프링 버섯 | 160×160 | 타일 |
| · | `assets/images/tile/ch5_thorn.png` | 잿불 화산숲 가시덩굴 | 128×128 | 타일 |
| · | `assets/images/tile/ch5_bridge.png` | 잿불 화산숲 수정 다리 | 128×48 | 타일 |
| · | `assets/images/tile/ch5_mover.png` | 잿불 화산숲 움직이는 발판 | 256×64 | 타일 |
| · | `assets/images/tile/ch5_lift.png` | 잿불 화산숲 승강 발판 | 256×64 | 타일 |
| · | `assets/images/tile/ch6_ground.png` | 별빛 하늘섬 흙 속 | 128×128 | 타일 |
| · | `assets/images/tile/ch6_ground_top.png` | 별빛 하늘섬 윗면(풀) | 128×160 | 타일 |
| · | `assets/images/tile/ch6_plank.png` | 별빛 하늘섬 나무 발판 | 128×48 | 타일 |
| · | `assets/images/tile/ch6_crumble.png` | 별빛 하늘섬 부서지는 발판 | 128×48 | 타일 |
| · | `assets/images/tile/ch6_spring.png` | 별빛 하늘섬 스프링 버섯 | 160×160 | 타일 |
| · | `assets/images/tile/ch6_thorn.png` | 별빛 하늘섬 가시덩굴 | 128×128 | 타일 |
| · | `assets/images/tile/ch6_bridge.png` | 별빛 하늘섬 수정 다리 | 128×48 | 타일 |
| · | `assets/images/tile/ch6_mover.png` | 별빛 하늘섬 움직이는 발판 | 256×64 | 타일 |
| · | `assets/images/tile/ch6_lift.png` | 별빛 하늘섬 승강 발판 | 256×64 | 타일 |
| ✅ | `assets/images/tile/crystal.png` | 수정 스위치 | 192×256 | 쏘면 다리가 생겨요 |

## UI

| 상태 | 파일 | 이름 | 규격 | 설명 |
|---|---|---|---|---|
| · | `assets/images/ui/logo.png` | 게임 로고 (꿈의 숲) | 1600×640 | UI |
| · | `assets/images/ui/app_icon.png` | 앱 아이콘 | 1024×1024 | UI |
| · | `assets/images/ui/splash.png` | 스플래시 | 2560×1440 | UI |
| · | `assets/images/ui/frame_common.png` | 카드 테두리(일반) | 512×768 | UI |
| · | `assets/images/ui/frame_rare.png` | 카드 테두리(희귀) | 512×768 | UI |
| · | `assets/images/ui/frame_epic.png` | 카드 테두리(영웅) | 512×768 | UI |
| · | `assets/images/ui/frame_legend.png` | 카드 테두리(전설) | 512×768 | UI |
| · | `assets/images/ui/btn_primary.png` | 기본 버튼 | 512×160 | UI |
| · | `assets/images/ui/btn_secondary.png` | 보조 버튼 | 512×160 | UI |
| · | `assets/images/ui/panel.png` | 패널 틀 | 1024×640 | UI |
| · | `assets/images/ui/menu_shop.png` | 상점 아이콘 | 256×256 | UI |
| · | `assets/images/ui/menu_attendance.png` | 출석 아이콘 | 256×256 | UI |
| · | `assets/images/ui/menu_mission.png` | 미션 아이콘 | 256×256 | UI |
| · | `assets/images/ui/menu_codex.png` | 도감 아이콘 | 256×256 | UI |
| · | `assets/images/ui/menu_equip.png` | 장비 아이콘 | 256×256 | UI |
| · | `assets/images/ui/menu_ranking.png` | 랭킹 아이콘 | 256×256 | UI |
| · | `assets/images/ui/menu_mail.png` | 우편 아이콘 | 256×256 | UI |
| · | `assets/images/ui/menu_settings.png` | 설정 아이콘 | 256×256 | UI |
| · | `assets/images/ui/stamp.png` | 출석 도장 | 256×256 | UI |
| · | `assets/images/ui/star.png` | 별 | 256×256 | UI |
| · | `assets/images/ui/npc_owl.png` | NPC 부엉이 할아버지 | 768×768 | UI |
| · | `assets/images/ui/npc_merchant.png` | NPC 상인 다람쥐 | 768×768 | UI |

## 도감

| 상태 | 파일 | 이름 | 규격 | 설명 |
|---|---|---|---|---|
| · | `assets/images/codex/frame.png` | 도감 카드 틀 | 768×1024 | 몬스터 카드 배경 |
| · | `assets/images/codex/unknown.png` | 미발견 실루엣 배경 | 512×512 | 아직 못 만난 몬스터 |

## 효과음

| 상태 | 파일 | 이름 | 규격 | 설명 |
|---|---|---|---|---|
| ✅ | `assets/audio/sfx/shoot.ogg` | 활 쏘기 | 0.2초 | 효과음 |
| ✅ | `assets/audio/sfx/hit.ogg` | 명중 | 0.15초 | 효과음 |
| ✅ | `assets/audio/sfx/crit.ogg` | 치명타 | 0.25초 | 효과음 |
| ✅ | `assets/audio/sfx/kill.ogg` | 처치 | 0.3초 | 효과음 |
| ✅ | `assets/audio/sfx/jump.ogg` | 점프 | 0.15초 | 효과음 |
| ✅ | `assets/audio/sfx/land.ogg` | 착지 | 0.12초 | 효과음 |
| ✅ | `assets/audio/sfx/spring.ogg` | 버섯 점프 | 0.35초 | 효과음 |
| ✅ | `assets/audio/sfx/coin.ogg` | 코인 | 0.2초 | 효과음 |
| ✅ | `assets/audio/sfx/xp.ogg` | 경험치 | 0.08초 | 효과음 |
| ✅ | `assets/audio/sfx/levelup.ogg` | 레벨업 | 0.8초 | 효과음 |
| ✅ | `assets/audio/sfx/hurt.ogg` | 피격 | 0.3초 | 효과음 |
| ✅ | `assets/audio/sfx/portal.ogg` | 포털 | 0.7초 | 효과음 |
| ✅ | `assets/audio/sfx/crumble.ogg` | 발판 붕괴 | 0.4초 | 효과음 |
| ✅ | `assets/audio/sfx/bridge.ogg` | 수정 다리 | 0.5초 | 효과음 |
| ✅ | `assets/audio/sfx/tele.ogg` | 공격 예고 | 0.12초 | 효과음 |
| ✅ | `assets/audio/sfx/boom.ogg` | 폭발 | 0.5초 | 효과음 |
| ✅ | `assets/audio/sfx/thud.ogg` | 보스 착지 | 0.5초 | 효과음 |
| ✅ | `assets/audio/sfx/select.ogg` | 선택 | 0.15초 | 효과음 |
| ✅ | `assets/audio/sfx/chest.ogg` | 상자 열기 | 0.7초 | 효과음 |
| ✅ | `assets/audio/sfx/shield.ogg` | 방패 | 0.3초 | 효과음 |
| ✅ | `assets/audio/sfx/freeze.ogg` | 빙결 | 0.25초 | 효과음 |
| ✅ | `assets/audio/sfx/zap.ogg` | 번개 | 0.2초 | 효과음 |
| ✅ | `assets/audio/sfx/focus.ogg` | 집중 | 0.6초 | 효과음 |
| ✅ | `assets/audio/sfx/bounce.ogg` | 화살 튕김 | 0.1초 | 효과음 |
| ✅ | `assets/audio/sfx/splat.ogg` | 벽 꽂기 | 0.25초 | 효과음 |
| ✅ | `assets/audio/sfx/victory.ogg` | 클리어 팡파레 | 2.5초 | 효과음 |
| ✅ | `assets/audio/sfx/defeat.ogg` | 패배 | 2.0초 | 효과음 |
| · | `assets/audio/sfx/ui_open.ogg` | 창 열기 | 0.2초 | 효과음 |
| · | `assets/audio/sfx/ui_close.ogg` | 창 닫기 | 0.15초 | 효과음 |
| · | `assets/audio/sfx/purchase.ogg` | 구매 | 0.6초 | 효과음 |
| · | `assets/audio/sfx/gacha_open.ogg` | 뽑기 | 1.2초 | 효과음 |
| · | `assets/audio/sfx/gacha_legend.ogg` | 전설 등장 | 2.0초 | 효과음 |
| · | `assets/audio/sfx/attendance.ogg` | 출석 도장 | 0.5초 | 효과음 |
| · | `assets/audio/sfx/mission_done.ogg` | 미션 완료 | 0.8초 | 효과음 |
| · | `assets/audio/sfx/equip.ogg` | 장착 | 0.3초 | 효과음 |
| · | `assets/audio/sfx/upgrade.ogg` | 강화 성공 | 0.8초 | 효과음 |
| · | `assets/audio/sfx/boss_roar.ogg` | 보스 등장 | 1.5초 | 효과음 |
| · | `assets/audio/sfx/boss_phase.ogg` | 보스 2페이즈 | 1.0초 | 효과음 |
| · | `assets/audio/sfx/rope.ogg` | 밧줄 오르기 | 0.3초 | 효과음 |
| · | `assets/audio/sfx/water.ogg` | 물 첨벙 | 0.4초 | 효과음 |

## 배경음

| 상태 | 파일 | 이름 | 규격 | 설명 |
|---|---|---|---|---|
| ✅ | `assets/audio/bgm/title.ogg` | 타이틀 | 90초 | 배경음 (끊김 없이 반복되게) |
| ✅ | `assets/audio/bgm/map.ogg` | 스테이지 지도 | 90초 | 배경음 (끊김 없이 반복되게) |
| ✅ | `assets/audio/bgm/camp.ogg` | 캠프·상점 | 90초 | 배경음 (끊김 없이 반복되게) |
| · | `assets/audio/bgm/lobby.ogg` | 로비 | 90초 | 배경음 (끊김 없이 반복되게) |
| ✅ | `assets/audio/bgm/stage_ch1.ogg` | 잠든 숲 스테이지 | 120초 | 배경음 (끊김 없이 반복되게) |
| ✅ | `assets/audio/bgm/boss_ch1.ogg` | 잠든 숲 보스 | 120초 | 배경음 (끊김 없이 반복되게) |
| · | `assets/audio/bgm/stage_ch2.ogg` | 버섯 동굴 스테이지 | 120초 | 배경음 (끊김 없이 반복되게) |
| · | `assets/audio/bgm/boss_ch2.ogg` | 버섯 동굴 보스 | 120초 | 배경음 (끊김 없이 반복되게) |
| · | `assets/audio/bgm/stage_ch3.ogg` | 안개 늪 스테이지 | 120초 | 배경음 (끊김 없이 반복되게) |
| · | `assets/audio/bgm/boss_ch3.ogg` | 안개 늪 보스 | 120초 | 배경음 (끊김 없이 반복되게) |
| · | `assets/audio/bgm/stage_ch4.ogg` | 눈꽃 고원 스테이지 | 120초 | 배경음 (끊김 없이 반복되게) |
| · | `assets/audio/bgm/boss_ch4.ogg` | 눈꽃 고원 보스 | 120초 | 배경음 (끊김 없이 반복되게) |
| · | `assets/audio/bgm/stage_ch5.ogg` | 잿불 화산숲 스테이지 | 120초 | 배경음 (끊김 없이 반복되게) |
| · | `assets/audio/bgm/boss_ch5.ogg` | 잿불 화산숲 보스 | 120초 | 배경음 (끊김 없이 반복되게) |
| · | `assets/audio/bgm/stage_ch6.ogg` | 별빛 하늘섬 스테이지 | 120초 | 배경음 (끊김 없이 반복되게) |
| · | `assets/audio/bgm/boss_ch6.ogg` | 별빛 하늘섬 보스 | 120초 | 배경음 (끊김 없이 반복되게) |
