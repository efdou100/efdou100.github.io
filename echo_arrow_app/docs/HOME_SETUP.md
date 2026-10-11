# 집 PC에서 실행하기 (Flutter + 안드로이드 에뮬레이터)

## 1. 설치 (처음 한 번)
1. **Git**: https://git-scm.com
2. **Flutter SDK (stable, 3.47 이상)**: https://docs.flutter.dev/get-started/install
   - 이미 깔려 있으면 `flutter upgrade` (이 프로젝트는 Dart 3.13.5 이상 필요)
3. **Android Studio**: https://developer.android.com/studio
   - 처음 실행 마법사에서 Android SDK, SDK Platform, Android Emulator 기본값 그대로 설치
4. 터미널에서 확인
   ```bash
   flutter doctor                    # 빨간 X 없이 Android toolchain, Android Studio 체크
   flutter doctor --android-licenses # 전부 y
   ```

## 2. 코드 받기
```bash
git clone -b claude/keen-lamport-x1c7to https://github.com/efdou100/efdou100.github.io.git
cd efdou100.github.io/echo_arrow_app
flutter pub get
flutter test        # "All tests passed!" 가 나오면 정상 (100판 정답 + 새 장치 패리티)
```
이미 받아 둔 적 있으면: `git pull origin claude/keen-lamport-x1c7to`

## 3. 에뮬레이터 만들고 켜기
- Android Studio → **Device Manager** → **+** → Pixel 7 (또는 아무 폰) → 시스템 이미지 API 34/35 → Finish → ▶
- 또는 터미널:
  ```bash
  flutter emulators                 # 목록
  flutter emulators --launch <이름>
  ```
- Windows에서 에뮬레이터가 매우 느리면: BIOS 가상화(VT-x/AMD-V) 켜기, Windows 기능에서 "Windows 하이퍼바이저 플랫폼" 켜기

## 4. 실행
```bash
flutter run          # 기기를 고르라고 하면 에뮬레이터 번호 선택
```
- 첫 실행은 Gradle 다운로드 때문에 5~10분 걸릴 수 있음
- 실행 중 터미널에서 `r` = 핫 리로드(코드 고친 것 바로 반영), `R` = 처음부터 다시, `q` = 종료
- VS Code를 쓰면 Flutter 확장 설치 → 오른쪽 아래에서 에뮬레이터 선택 → F5

## 5. 테스트할 때 편한 것
- **개발용 메뉴**: 홈 오른쪽 위 ⚙ 설정 → 맨 아래 빨간 상자 (디버그 실행에서만 보임, 출시 빌드엔 없음)
  - `15 등불`, `35 째깍`, `55 고리`, `71 유리` … : 그 판 직전까지 깬 상태로 바로 이동 (소개 팝업 확인용)
  - `코인 +10000`, `처음부터`(완전 초기화 → 1판 온보딩부터)
- 광고는 구글 **테스트 광고**가 뜸 (정상). 결제는 디버그에서 가짜 결제로 바로 지급됨
- 실제 폰으로 보려면: 폰 설정 → 휴대전화 정보 → 빌드 번호 7번 탭 → 개발자 옵션 → USB 디버깅 켜기 → USB 연결 → `flutter run`
- 설치 파일만 만들려면: `flutter build apk --debug` → `build/app/outputs/flutter-apk/app-debug.apk`

## 6. 꼭 봐야 할 것 (체크리스트)
- [ ] 1~3판 온보딩: 손가락 안내 → 바로 다음 판으로 넘어가는지
- [ ] 조준 손맛: 길게 당겼을 때 미세 조준(각도 숫자가 0.1°씩 움직이는지), 진동
- [ ] 15판 등불 / 35판 째깍 거울 / 55판 되쏘기 고리(톡 눌러 방향 바꾸기) / 71판 유리 마개(2발 시간차)
- [ ] 각 소개 판에서 "새 친구 등장!" 팝업이 한 번만 뜨는지
- [ ] 홈 → 상점·패스·도감 탭 이동, 팝업 열고 닫기, 뒤로 가기 버튼 동작
- [ ] 소리·배경음 켜고 끄기, 앱을 내렸다 올렸을 때 음악 멈춤/재개
- [ ] 이상한 점은 판 번호 + 화면 캡처와 함께 클라우드 세션에 알려 주면 거기서 고쳐서 올림 → `git pull` 후 `R`

## 문제가 생기면
| 증상 | 해결 |
|---|---|
| `flutter doctor`에 Android licenses 경고 | `flutter doctor --android-licenses` |
| `No devices found` | 에뮬레이터를 먼저 켜고 `flutter devices`로 보이는지 확인 |
| Gradle/Kotlin 버전 오류 | `flutter upgrade` 후 `flutter clean` → `flutter pub get` → `flutter run` |
| 소리가 안 남 | 에뮬레이터 볼륨, 앱 설정의 소리/배경음 토글 확인 |
