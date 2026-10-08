# 메아리 화살 (ECHO ARROW)

과거의 화살과 함께 쏘는 한 발 조준 퍼즐. 세로 화면, 한 손가락.
기획 전체는 [docs/GDD.md](docs/GDD.md) 참고.

## 실행

```bash
flutter pub get
flutter run            # 휴대폰/에뮬레이터
flutter run -d chrome  # 웹으로 빠르게 확인
flutter test           # 시뮬레이션 패리티 테스트 (레벨 100개 정답 검증)
```

## 폴더 구조

| 경로 | 내용 |
|---|---|
| `lib/game/sim.dart` | 결정론적 시뮬레이션(1/240초 고정 스텝). `../echo-arrow/sim.js`와 계산 순서가 같아야 함 |
| `lib/game/controller.dart` | 한 판의 흐름(조준→비행→메아리→클리어/실패)과 연출 상태 |
| `lib/game/painter.dart` | 게임 화면 그리기(CustomPainter) |
| `lib/game/level.dart` | 레벨 데이터 모델, `assets/levels/levels.json` 로딩 |
| `lib/app/profile.dart` | 저장 데이터(진행, 코인, 하트, 부스터, 출석, 패스, 설정) |
| `lib/app/economy.dart` | 모든 경제 수치와 해금 시점 |
| `lib/services/services.dart` | 광고·결제·분석 인터페이스와 개발용 가짜 구현 |
| `lib/screens/` | 메인 틀(shell: 탭·재화 바), 홈 지도, 게임, 팝업(판 시작/이어하기/힌트/하트/출석…), 클리어 화면, 상점, 패스, 도감 |
| `lib/app/art.dart` | 이미지 교체 시스템 (assets/images 에 파일이 있으면 이미지, 없으면 코드 그림) |
| `lib/app/l10n.dart` | 한국어/영어 문구 |
| `lib/services/ads_admob.dart`, `iap_store.dart` | 애드몹·인앱결제 실연동 (지금은 구글 테스트 ID) |
| `docs/ART_DIRECTION.md`, `docs/ASSETS.md` | 아트 기준과 Gemini 프롬프트 68종 |
| `docs/RELEASE_CHECKLIST.md` | 집에서 이어서 할 일 (에뮬레이터 → 이미지 → 광고/결제 → 서명 → 스토어) |
| `tool/gen_levels.js` | 레벨 생성·솔버 검증·월드 배치 → `assets/levels/levels.json` |
| `tool/gen_sfx.py`, `tool/gen_bgm.py` | 효과음·배경음 합성 → `assets/audio/*.wav` |
| `tool/process_assets.py`, `check_assets.py` | Gemini 이미지 배경 제거·크기 맞춤·배치, 누락 점검 |

## 레벨 추가하기

1. 손으로 만들 판은 `../echo-arrow/sim.js`의 `LEVELS`에 추가(웹 프로토타입에서 바로 플레이해 볼 수 있음).
2. `node tool/gen_levels.js` 실행 → 솔버가 풀이 가능 여부·난이도(성공 각도 폭)·정답을 계산해 월드별 20판으로 배치.
3. `flutter test`로 Flutter 쪽에서도 정답이 통하는지 확인.

## 출시까지 남은 일

[docs/RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) 순서대로: 에뮬레이터 확인 → Gemini 이미지 → 애드몹/스토어 ID 교체 → 서명 → 스토어 등록.
