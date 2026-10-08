# 출시 체크리스트 — 집 컴퓨터에서 이어서 할 일

이 저장소는 **코드·레벨·효과음·광고/결제 연동·다국어까지 끝난 상태**다.
이 문서는 집에서 이어서 진행할 순서를 정리한 것이다.

> 이 개발 환경에는 Android SDK를 설치할 수 없어서(네트워크 차단), **APK 빌드는 아직 한 번도 돌려 보지 않았다.**
> Dart 정적 분석, 단위·위젯 테스트 107개, 웹 빌드, 브라우저 실행은 모두 통과했다.
> 안드로이드 쪽에서 처음 빌드할 때 Gradle 설정 문제가 나오면 아래 「자주 나는 문제」를 먼저 본다.

---

## 0. 준비 (한 번만)
```bash
flutter doctor            # Android toolchain, Xcode(맥) 체크
cd echo_arrow_app
flutter pub get
flutter analyze           # No issues found! 가 나와야 함
flutter test              # 107개 통과해야 함 (레벨 100개 정답 검증 포함)
```

## 1. 에뮬레이터 / 실기기 확인
```bash
flutter emulators --launch <이름>      # 또는 USB 로 휴대폰 연결
flutter run                          # 디버그
flutter run --release                # 성능 확인 (애니메이션 끊김 여부)
```
확인할 것:
- [ ] 첫 실행 → 메뉴 없이 1단계, 손가락 시범 → 쏘면 클리어 연출 → 2단계로 바로 이동
- [ ] 3단계 클리어 후 메인 화면(하단 탭) 등장, 출석 팝업
- [ ] 판 시작 팝업 → 부스터 선택 → 플레이
- [ ] 화살 다 쓰기 → 이어하기 팝업 → **애드몹 테스트 광고**가 실제로 뜨는지 (보상형)
- [ ] 15단계 이후 3판마다 전면 테스트 광고
- [ ] 상점에서 결제 버튼 → 스토어 상품 등록 전에는 디버그 빌드에서 "개발용 테스트 결제" 창
- [ ] 소리·진동·화면 흔들림 끄기, 언어(자동/한국어/English) 전환
- [ ] 뒤로 가기 버튼: 게임 중이면 일시정지 팝업

## 2. 이미지 넣기 (Gemini)
1. `docs/ASSETS.md` 의 프롬프트로 생성 (68장, 기준은 `docs/ART_DIRECTION.md`)
2. `raw/` 에 `<id 의 / 를 __ 로>.png` 이름으로 저장
3. `python3 tool/process_assets.py raw/` → `python3 tool/check_assets.py`
4. `flutter run` → 이미지가 있는 것부터 바로 바뀜 (없는 것은 코드 그림 유지)
5. 앱 아이콘: `assets/images/icon/app_icon.png`, `app_icon_fg.png` 가 생기면 `pubspec.yaml` 의 `flutter_launcher_icons` 경로를 바꾸고 `dart run flutter_launcher_icons`

## 3. 광고 (애드몹)
- [ ] 애드몹 콘솔에서 앱 2개(Android/iOS) 등록 → 앱 ID 발급
- [ ] `android/app/src/main/AndroidManifest.xml` 의 `com.google.android.gms.ads.APPLICATION_ID` 값 교체
- [ ] `ios/Runner/Info.plist` 의 `GADApplicationIdentifier` 교체
- [ ] 광고 단위(보상형 1, 전면 1) 만들고 `lib/services/ads_admob.dart` 의 `AdIds` 에 입력, `testMode = false`
- [ ] 애드몹 콘솔 → 개인정보 및 메시지 → GDPR 동의 메시지 게시 (코드는 UMP 동의창을 이미 띄움)
- [ ] `app-ads.txt` 를 개발자 웹사이트 루트에 게시 (이 저장소 루트에 이미 파일이 있음, 내용을 애드몹 값으로)

## 4. 인앱결제
스토어 상품 ID = `echoarrow_` + 아래 id

| id | 종류 | 가격(기준) |
|---|---|---|
| starter | 비소모성(1회) | $1.99 |
| noads | 비소모성 | $3.99 |
| pass | 비소모성(시즌) | $4.99 |
| piggy | 소모성 | $2.99 |
| coins_s / coins_m / coins_l / coins_xl / coins_xxl | 소모성 | $0.99 / 4.99 / 9.99 / 19.99 / 49.99 |

- [ ] Play Console → 수익 창출 → 인앱 상품에 위 ID 로 등록 (가격은 국가별 자동 환산)
- [ ] App Store Connect → 앱 내 구입 등록
- [ ] 내부 테스트 트랙에 올린 뒤 라이선스 테스터 계정으로 실제 결제 흐름 확인
- [ ] (권장) 영수증 서버 검증: `lib/services/iap_store.dart` 의 `_onPurchases` 주석 위치

## 5. 서명 · 빌드
```bash
# 업로드 키 만들기 (한 번만, 키 파일은 절대 저장소에 올리지 말 것 — .gitignore 처리됨)
keytool -genkey -v -keystore ~/echo-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
`android/key.properties` 작성:
```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/절대/경로/echo-upload.jks
```
```bash
flutter build apk --release          # 설치 테스트용
flutter build appbundle --release    # Play Console 업로드용 (.aab)
flutter build ipa --release          # iOS (맥)
```
- 버전은 `pubspec.yaml` 의 `version: 1.0.0+1` (+ 뒤 숫자가 빌드 번호, 올릴 때마다 +1)

## 6. 스토어 등록
- [ ] 앱 이름: Echo Arrow / 메아리 화살 (안드로이드는 언어별 자동, iOS 는 Echo Arrow)
- [ ] 짧은 설명(80자): "Your missed arrows fly again. A one-finger puzzle of bounces, mirrors and echoes."
- [ ] 스크린샷 5장(세로): 1단계 손가락 시범 / 거울 판 / 메아리 판(지난 화살이 같이 날아가는 장면) / 클리어 연출 / 홈 지도
- [ ] 홍보 영상 15~30초: 다시보기(REPLAY) 화면을 녹화하면 그대로 쓸 수 있음
- [ ] 개인정보처리방침 URL (광고 SDK 때문에 필수) — 이 저장소의 GitHub Pages 에 올려도 됨
- [ ] 콘텐츠 등급 설문, 데이터 보안 양식(광고 ID 수집 = 예)
- [ ] 타깃 연령: 13세 이상 권장 (13세 미만 포함 시 광고 정책이 달라짐)

## 7. 소프트런칭 지표 (docs/GDD.md 5-5)
- D1 40%+, D7 15%+, 세션 8분+ → 미달 시 1~20단계 난이도·온보딩부터 조정
- `lib/services/services.dart` 의 `Analytics.log` 를 Firebase Analytics 에 연결하면 아래 이벤트가 바로 쌓인다:
  `app_open, level_start, level_win, level_fail, level_out_of_arrows, continue_coins, ad_rewarded_*, ad_interstitial, iap_*, booster_use, booster_buy, checkin, daily_start, pass_claim, share, shop_open/shop_tap`

---

## 자주 나는 문제
| 증상 | 해결 |
|---|---|
| `minSdkVersion 21 cannot be smaller than 24` | 이미 `minSdk = maxOf(24, ...)` 로 설정됨. 그래도 나면 `android/app/build.gradle.kts` 확인 |
| 앱 시작 직후 꺼짐 + 로그에 `Missing application ID` | 매니페스트의 애드몹 APPLICATION_ID 누락 |
| 릴리스 빌드에서 광고/결제 클래스 오류 | `android/app/proguard-rules.pro` 에 해당 패키지 `-keep` 추가 |
| iOS `pod install` 실패 | `cd ios && pod repo update && pod install`, 최소 버전 iOS 15 |
| 결제 버튼을 눌러도 아무 일 없음(릴리스) | 스토어 상품 ID 미등록 또는 테스트 계정이 아님 (`iap_not_found` 이벤트 확인) |
