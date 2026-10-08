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
| `lib/screens/` | 홈(지도), 게임, 시트(클리어/이어하기/힌트/판 시작/하트/출석…), 상점, 패스 |
| `tool/gen_levels.js` | 레벨 생성·솔버 검증·월드 배치 → `assets/levels/levels.json` |
| `tool/gen_sfx.py` | 효과음 합성 → `assets/audio/*.wav` |

## 레벨 추가하기

1. 손으로 만들 판은 `../echo-arrow/sim.js`의 `LEVELS`에 추가(웹 프로토타입에서 바로 플레이해 볼 수 있음).
2. `node tool/gen_levels.js` 실행 → 솔버가 풀이 가능 여부·난이도(성공 각도 폭)·정답을 계산해 월드별 20판으로 배치.
3. `flutter test`로 Flutter 쪽에서도 정답이 통하는지 확인.

## 출시 전에 바꿀 것

- `AdService.instance`를 google_mobile_ads 구현으로 교체(광고 단위 ID 필요).
- `StoreService.instance`를 in_app_purchase 구현으로 교체(스토어 상품 ID는 `Economy.products`의 id 사용).
- `Analytics.log`를 Firebase Analytics 등에 연결.
- 효과음은 `assets/audio/<이름>.wav`를 같은 이름의 파일로 바꾸면 교체됨.
