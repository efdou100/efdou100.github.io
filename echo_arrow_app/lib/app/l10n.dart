import 'dart:ui' as ui;

import 'profile.dart';

/// 다국어. 지금은 한국어/영어. 새 언어는 [_strings] 에 같은 키로 추가하면 된다.
/// 사용: tr('level_start', {'n': 5}) → "5단계 시작" / "Play Level 5"
class L10n {
  static const supported = ['ko', 'en'];
  static const names = {'ko': '한국어', 'en': 'English'};

  /// 설정에서 고른 언어, 없으면 기기 언어(한국어가 아니면 영어)
  static String get lang {
    final pick = Profile.instance.lang;
    if (supported.contains(pick)) return pick;
    final device = ui.PlatformDispatcher.instance.locale.languageCode;
    return device == 'ko' ? 'ko' : 'en';
  }

  static bool get isKo => lang == 'ko';
}

String tr(String key, [Map<String, Object?> args = const {}]) {
  final table = _strings[L10n.lang] ?? _strings['en']!;
  var s = table[key] ?? _strings['en']![key] ?? _strings['ko']![key] ?? key;
  args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
  return s;
}

/// 레벨 이름 (데이터는 한국어 원문)
String levelName(String ko) => L10n.isKo ? ko : (_levelNames[ko] ?? ko);

/// 레벨 안내 문구
String levelHint(String ko) => L10n.isKo ? ko : (_hints[ko] ?? ko);

String worldName(int w) => tr('w$w');

const _strings = <String, Map<String, String>>{
  'ko': {
    'app_title': '메아리 화살',
    'tagline': '과거의 화살과 함께 쏘는 한 발 퍼즐',
    'w1': '달빛 숲', 'w2': '은빛 거울', 'w3': '수정 동굴', 'w4': '메아리 계곡', 'w5': '별의 끝',
    'world_n': '월드 {n}',
    'level_n': '{n}단계',
    'level_start': '{n}단계 시작',
    'play': '플레이',
    'start': '시작',
    'all_cleared': '모든 단계를 깼어요',
    'shop': '상점', 'pass': '패스', 'settings': '설정', 'checkin': '출석', 'daily': '오늘의 한 발', 'streak_n': '연승 {n}', 'starter_short': '스타터',
    'world_stars': '별 {a} / {b}',
    'tier_hard': '어려움', 'tier_superhard': '아주 어려움', 'tier_boss': '보스', 'coins_mult': '코인 {n}배',
    'shots_info': '화살 {s}발 · {p}발 안에 깨면 별 3개',
    'boosters': '부스터', 'own_n': '보유 {n}', 'free': '무료',
    'b_aim': '긴 조준선', 'b_extra': '화살 +1', 'b_split': '분열 화살',
    'b_aim_d': '반사 3번까지 조준선이 보여요', 'b_extra_d': '이번 판 화살이 하나 늘어나요', 'b_split_d': '처음 튕길 때 세 갈래로 갈라지는 화살 1개',
    'streak_free': '메아리 연승 {n} · 무료 부스터가 켜졌어요',
    'no_hearts': '하트가 없어요', 'hearts_note': '클리어하면 하트는 줄지 않아요',
    'hearts_title': '하트 {n} / {m}', 'infinite_on': '무한 하트 사용 중', 'hearts_full': '하트가 가득 찼어요', 'next_heart': '다음 하트까지 {t}',
    'refill': '하트 가득 채우기', 'ad_heart': '광고 보고 하트 +1', 'full': '가득',
    'no_coins': '코인이 모자라요',
    'checkin_title': '출석 선물', 'checkin_desc': '하루에 한 번 받아요. 빠진 날이 있어도 이어서 받을 수 있어요.', 'day_n': '{n}일', 'chest': '상자',
    'claim_day': '{n}일차 받기', 'see_tomorrow': '내일 또 만나요', 'claim_double': '광고 보고 2배로 받기',
    'starter': '스타터 팩', 'once_left': '처음 한 번만 · {t} 남음', 'buy_for': '{p}에 받기', 'later': '다음에',
    'ok_great': '좋아요', 'booster_unlock_t': '부스터가 열렸어요', 'booster_unlock_b': '판을 시작하기 전에 고를 수 있어요. 선물로 하나씩 드릴게요.',
    'daily_desc': '전 세계가 같은 판을 풀어요. 한 발에 깨고 결과를 공유해 보세요.', 'daily_today': '오늘의 판: {name}', 'daily_go': '도전하기 (보상 코인 {n})', 'daily_done': '오늘은 완료했어요 · 다시 풀기',
    'streak_title': '메아리 연승 {n}', 'streak_desc': '처음 시도에 깨면 연승이 올라가요. 연승이 높을수록 판을 시작할 때 무료 부스터가 켜져요. 실패하거나 이어하기를 쓰면 처음부터예요.',
    'streak_row': '{n}연승', 'streak_row_plus': '{n}연승 이상', 'streak_best': '최고 기록 {n}연승',
    'sound': '효과음', 'music': '배경음악', 'haptics': '진동', 'reduce_motion': '화면 흔들림 줄이기', 'language': '언어', 'auto': '자동',
    'clear': '클리어!', 'perfect': '완벽해요!', 'trick_clear': '트릭샷 클리어!',
    'r_used': '{n}발', 'r_bounce': '최대 {n}번 튕김', 'r_tricks': '트릭샷 {n}', 'r_echo': '메아리 {n}',
    'par_hint': '{n}발 이하로 깨면 별 3개', 'piggy_line': '별빛 저금통 {a} / {b}',
    'replay': '다시보기', 'share': '공유하기', 'next': '다음 단계', 'back_map': '지도로 돌아가기', 'retry_stars': '다시 도전해서 별 더 받기', 'copied': '공유 문구를 복사했어요',
    'share_text': '🏹 메아리 화살 {n}단계 {stars}\n{used}발{extra}\n너는 몇 발에 깰 수 있어?', 'share_bounce': ' · {n}번 튕김', 'share_trick': ' · 트릭샷!',
    'almost': '거의 다 됐어요!', 'out': '화살을 다 썼어요',
    'close_desc': '정령 {n}마리 중 {h}마리를 깨웠어요. 메아리는 그대로 남아요.', 'out_desc': '화살을 더 받으면 지금까지의 메아리를 그대로 이어서 쏠 수 있어요.',
    'plus_arrows': '화살 +{n}', 'ad_arrow': '광고 보고 화살 +1 (오늘 {n}회)', 'restart': '처음부터', 'give_up': '포기하기', 'heart_cost': '처음부터 / 포기하면 하트 1개가 줄어요',
    'hint': '힌트', 'hint_n': '힌트 ×{n}', 'hint_desc': '첫 화살이 날아갈 방향을 유령 화살로 보여 줘요.\n거울이 있으면 정답 방향으로 돌려 놓아요.', 'hint_show': '힌트 보기', 'hint_ad': '광고 보고 힌트',
    'resume': '계속하기', 'quit_map': '지도로 나가기', 'quit_note': '도중에 나가면 하트 1개가 줄어요',
    't_echo_wait': '메아리 {n}개 대기 중 · 누르는 순간 지난 화살이 같은 타이밍에 다시 날아가요',
    't_plus': '+{n}발! 메아리는 그대로 남아 있어요', 't_mirror': '거울이 돌면 메아리의 길도 바뀌어요', 't_pull': '조금 더 길게 당겼다 놓아야 쏴져요',
    't_basic': '기본 화살', 't_split': '분열 화살: 처음 튕길 때 세 갈래로 갈라져요', 't_pierce': '관통 화살: 이끼를 뚫고 지나가요',
    't_baby_echo': '지난 화살이 아기 정령을 맞혀요. 거울을 돌리거나 처음부터 다시 하세요',
    'missions': '오늘의 미션', 'r_medal': '트릭 메달 획득!', 'bonus_trick': '보너스: 2번 이상 튕긴 화살로 깨우기 (+{n} 코인)', 'bonus_done': '트릭 메달 획득 완료', 'dock_missions': '미션 {n}/3', 'm_reset_in': '{t} 후 새 미션', 'm_chest': '미션 상자', 'm_chest_body': '오늘 미션을 모두 끝냈어요! 내일 또 만나요.', 'm_done': '미션 완료 · {x}', 'claim': '받기', 'claimed': '받음', 'open': '열기', 'prev': '이전', 'next_w': '다음', 'm_clear': '아무 판이나 {n}개 깨기', 'm_stars': '별 {n}개 모으기', 'm_trick': '트릭샷 {n}번 성공', 'm_echo': '메아리로 정령 {n}마리 깨우기', 'm_oneshot': '화살 한 발로 {n}판 깨기', 'm_first': '첫 시도에 {n}판 깨기', 'm_near': '"아깝다!" {n}번 듣기', 'm_perfect': '별 3개로 {n}판 깨기', 'sc_title': '별 상자', 'sc_body': '별 {n}개 달성! 상자가 열렸어요.', 'sc_desc': '이 월드에서 모은 별로 상자를 열어요', 'sc_tip': '별이 모자라면? 깬 판을 별 3개로 다시 깨 보세요', 'stars_n': '★{n}', 'f_blast': '펑! 깨웠다', 'f_boom': '펑!', 'f_crack': '쨍그랑!', 'f_oops_boom': '아기가 놀랐어요!', 't_baby_boom': '등불 폭발이 아기 정령까지 닿았어요. 폭발 반경을 조심!', 'f_double': '더블!', 'f_triple': '트리플!', 'f_combo': '{n}연속!', 'f_trick': '트릭샷!', 'f_trick_x': '트릭샷 {x}', 'f_echo': '메아리 명중', 'f_near': '아깝다!',
    'f_oops_me': '앗! 아기 정령이 깼어요', 'f_oops_echo': '메아리가 아기 정령을 깨웠어요', 'f_ice': '쨍!', 'f_prism': '분광!', 'f_split': '분열!', 'f_shield': '팅!',
    'tut_press': '누르고', 'tut_pull': '당기고…', 'tut_release': '놓기!',
    'sk_split': '분열', 'sk_pierce': '관통',
    'piggy': '별빛 저금통', 'piggy_sub': '깰 때마다 코인이 쌓여요 ({a} / {b})', 'piggy_now': '지금 깨면 코인 {n}', 'piggy_min': '코인 1000개부터 깰 수 있어요',
    'noads': '광고 제거', 'noads_sub': '판 사이 광고가 사라져요. 원할 때 보는 보상형 광고는 그대로예요.', 'coins': '코인', 'trails': '화살 궤적', 'trails_sub': '다시보기와 공유 영상에 그대로 보여요',
    'in_use': '사용 중', 'equip': '선택', 'pass_reward': '패스 보상',
    'p_starter': '스타터 팩', 'p_noads': '광고 제거', 'p_piggy': '별빛 저금통 깨기', 'p_pass': '화살 패스 프리미엄',
    'p_coins_s': '코인 한 줌', 'p_coins_m': '코인 주머니', 'p_coins_l': '코인 상자', 'p_coins_xl': '코인 궤짝', 'p_coins_xxl': '코인 보물고',
    'badge_once': '한 번만', 'badge_rewarded': '보상형 광고는 유지', 'badge_popular': '인기',
    'rw_coins': '코인 {n}', 'rw_hints': '힌트 ×{n}', 'rw_hearts': '하트 ×{n}', 'rw_inf_m': '무한 하트 {n}분', 'rw_inf_h': '무한 하트 {n}시간', 'rw_trail': '궤적 「{x}」', 'rw_booster': '{x} ×{n}',
    'trail_moon': '달빛', 'trail_ember': '불씨', 'trail_aurora': '오로라',
    'pass_title': '화살 패스', 'pass_desc': '별 {n}개마다 한 칸씩 열려요 · {a} / {b}칸', 'premium_open': '프리미엄 열기 {p}', 'premium': '프리미엄',
    'ad_rewarded': '보상형 광고', 'ad_inter': '전면 광고', 'ad_fake': '개발용 가짜 광고예요. 출시 빌드에서는 실제 광고가 나와요.', 'close': '닫기',
    'iap_test': '개발용 테스트 결제예요. 실제로 돈이 나가지 않아요.\n{p}', 'cancel': '취소', 'pay': '{p} 결제', 'restore': '구매 복원',
    'version': '메아리 화살 · {v}',
    'world_clear': '월드 {n} 완료!', 'new_world': '새로운 월드',
    'home': '홈', 'collection': '도감', 'unlock_at': '{n}단계를 깨면 열려요', 'tab_unlocked': '{x} 탭이 열렸어요!',
    'col_spirits': '정령', 'col_devices': '장치', 'col_found': '{a} / {b} 발견', 'col_locked': '아직 만나지 못했어요',
    'spirit_sleep': '잠든 정령', 'spirit_sleep_d': '화살로 맞히면 깨어나요. 모두 깨우면 클리어!',
    'spirit_baby': '아기 정령', 'spirit_baby_d': '절대 맞히면 안 돼요. 맞히면 그 판은 실패예요.',
    'spirit_shield': '방패 정령', 'spirit_shield_d': '방패 쪽은 화살을 튕겨내요. 뒤에서 맞혀야 해요.',
    'spirit_moving': '흔들리는 정령', 'spirit_moving_d': '좌우로 움직여요. 타이밍을 노리세요.',
    'dev_wood': '나무 벽', 'dev_wood_d': '화살이 튕겨 나가요.', 'dev_moss': '이끼', 'dev_moss_d': '화살을 붙잡아요. 관통 화살은 뚫고 지나가요.',
    'dev_lantern': '등불', 'dev_lantern_d': '맞히면 펑! 주변 정령을 한꺼번에 깨우고 옆 등불로 번져요. 방패도 소용없지만, 아기 정령도 깨워요.', 'dev_spinner': '째깍 거울', 'dev_spinner_d': '저절로 째깍째깍 45°씩 돌아요. 언제 쏘느냐에 따라 튕기는 방향이 달라져요.', 'dev_relay': '되쏘기 고리', 'dev_relay_d': '화살을 잠깐 붙잡았다가 화살표 방향으로 다시 쏴요. 톡 누르면 방향이 바뀌어요.', 'dev_crystal': '유리 마개', 'dev_crystal_d': '분홍 금이 간 면으로 맞혀야만 깨져요. 다른 면은 튕겨내요. 깬 화살은 멈추니, 다음 화살로 지나가세요.', 'new_device': '새 친구 등장!', 'got_it': '알겠어요', 'dev_split': '분열 화살', 'dev_split_d': '첫 번째로 튕길 때 세 갈래로 갈라져요. 판마다 정해진 개수만 쓸 수 있어요.', 'dev_pierce': '관통 화살', 'dev_pierce_d': '이끼를 뚫고 지나가요. 막힌 길도 곧장!', 'dev_mirror': '회전 거울', 'dev_mirror_d': '톡 누르면 45°씩 돌아가요. 메아리의 길도 바뀌어요.', 'dev_bumper': '버섯 범퍼', 'dev_bumper_d': '둥근 면이라 맞는 자리마다 각도가 달라요.',
    'dev_ice': '얼음', 'dev_ice_d': '한 번 튕겨내고 깨져요.', 'dev_portal': '포털', 'dev_portal_d': '주황으로 들어가 파랑으로 같은 방향 그대로 나와요.',
    'dev_prism': '프리즘', 'dev_prism_d': '화살을 세 갈래로 나눠요.', 'dev_gate': '스위치와 문', 'dev_gate_d': '스위치를 맞히면 문이 잠깐 열려요. 메아리와 함께 쓰세요.',
    'dev_echo': '메아리', 'dev_echo_d': '실패한 화살은 다음 발에 같은 각도·같은 타이밍으로 다시 날아가요.',
    'met_at': '{n}단계에서 만나요',
  },
  'en': {
    'app_title': 'Echo Arrow',
    'tagline': 'A one-shot puzzle where your past arrows fly again',
    'w1': 'Moonlit Forest', 'w2': 'Silver Mirrors', 'w3': 'Crystal Caves', 'w4': 'Echo Valley', 'w5': "Star's End",
    'world_n': 'World {n}',
    'level_n': 'Level {n}',
    'level_start': 'Play Level {n}',
    'play': 'Play',
    'start': 'Play',
    'all_cleared': 'All levels cleared',
    'shop': 'Shop', 'pass': 'Pass', 'settings': 'Settings', 'checkin': 'Check-in', 'daily': 'Daily Shot', 'streak_n': 'Streak {n}', 'starter_short': 'Starter',
    'world_stars': '{a} / {b} stars',
    'tier_hard': 'Hard', 'tier_superhard': 'Super Hard', 'tier_boss': 'Boss', 'coins_mult': '{n}× coins',
    'shots_info': '{s} arrows · clear with {p} for 3 stars',
    'boosters': 'Boosters', 'own_n': 'Own {n}', 'free': 'Free',
    'b_aim': 'Long Aim', 'b_extra': '+1 Arrow', 'b_split': 'Split Arrow',
    'b_aim_d': 'Shows the aim line for 3 bounces', 'b_extra_d': 'One more arrow this level', 'b_split_d': 'An arrow that splits in three on its first bounce',
    'streak_free': 'Echo streak {n} · free boosters on',
    'no_hearts': 'Out of lives', 'hearts_note': 'Clearing a level never costs a life',
    'hearts_title': 'Lives {n} / {m}', 'infinite_on': 'Unlimited lives active', 'hearts_full': 'Your lives are full', 'next_heart': 'Next life in {t}',
    'refill': 'Refill lives', 'ad_heart': 'Watch an ad: +1 life', 'full': 'Full',
    'no_coins': 'Not enough coins',
    'checkin_title': 'Daily Gift', 'checkin_desc': 'Claim once a day. Missing a day never resets your progress.', 'day_n': 'Day {n}', 'chest': 'Chest',
    'claim_day': 'Claim day {n}', 'see_tomorrow': 'Come back tomorrow', 'claim_double': 'Watch an ad: claim 2×',
    'starter': 'Starter Pack', 'once_left': 'One time only · {t} left', 'buy_for': 'Get it for {p}', 'later': 'Not now',
    'ok_great': 'Great!', 'booster_unlock_t': 'Boosters unlocked', 'booster_unlock_b': 'Pick them before a level starts. Here is one of each on us.',
    'daily_desc': 'Everyone in the world plays the same level today. Clear it in one shot and share your result.', 'daily_today': "Today's level: {name}", 'daily_go': 'Play ({n} coin reward)', 'daily_done': 'Done for today · play again',
    'streak_title': 'Echo Streak {n}', 'streak_desc': 'Clear a level on your first try to grow your streak. Higher streaks start levels with free boosters. Failing or continuing resets it.',
    'streak_row': '{n} wins', 'streak_row_plus': '{n}+ wins', 'streak_best': 'Best streak: {n}',
    'sound': 'Sound effects', 'music': 'Music', 'haptics': 'Vibration', 'reduce_motion': 'Reduce screen shake', 'language': 'Language', 'auto': 'Auto',
    'clear': 'Cleared!', 'perfect': 'Perfect!', 'trick_clear': 'Trick Shot Clear!',
    'r_used': '{n} arrows', 'r_bounce': '{n} bounces', 'r_tricks': '{n} trick shots', 'r_echo': '{n} echoes',
    'par_hint': 'Clear with {n} or fewer for 3 stars', 'piggy_line': 'Starlight Piggy {a} / {b}',
    'replay': 'Replay', 'share': 'Share', 'next': 'Next level', 'back_map': 'Back to map', 'retry_stars': 'Retry for more stars', 'copied': 'Copied to clipboard',
    'share_text': '🏹 Echo Arrow · Level {n} {stars}\n{used} arrows{extra}\nCan you beat it?', 'share_bounce': ' · {n} bounces', 'share_trick': ' · trick shot!',
    'almost': 'So close!', 'out': 'Out of arrows',
    'close_desc': 'You woke {h} of {n} spirits. Your echoes stay as they are.', 'out_desc': 'Get more arrows and keep shooting with all your echoes intact.',
    'plus_arrows': '+{n} Arrows', 'ad_arrow': 'Watch an ad: +1 arrow ({n} left today)', 'restart': 'Restart', 'give_up': 'Give up', 'heart_cost': 'Restarting or giving up costs 1 life',
    'hint': 'Hint', 'hint_n': 'Hint ×{n}', 'hint_desc': 'A ghost arrow shows where your first shot should go.\nMirrors are turned to the right angle.', 'hint_show': 'Show hint', 'hint_ad': 'Watch an ad for a hint',
    'resume': 'Resume', 'quit_map': 'Quit to map', 'quit_note': 'Quitting mid-level costs 1 life',
    't_echo_wait': '{n} echoes ready · the moment you press, your past arrows fly again on cue',
    't_plus': '+{n} arrows! Your echoes are still here', 't_mirror': 'Turning a mirror changes your echoes’ paths too', 't_pull': 'Pull back a little further to shoot',
    't_basic': 'Normal arrow', 't_split': 'Split arrow: splits in three on its first bounce', 't_pierce': 'Pierce arrow: goes straight through moss',
    't_baby_echo': 'A past arrow hits the baby spirit. Turn a mirror or restart',
    'missions': 'Daily Missions', 'r_medal': 'Trick Medal earned!', 'bonus_trick': 'Bonus: wake a spirit with a 2+ bounce arrow (+{n} coins)', 'bonus_done': 'Trick Medal earned', 'dock_missions': 'Missions {n}/3', 'm_reset_in': 'New missions in {t}', 'm_chest': 'Mission Chest', 'm_chest_body': 'All of today’s missions done! See you tomorrow.', 'm_done': 'Mission done · {x}', 'claim': 'Claim', 'claimed': 'Claimed', 'open': 'Open', 'prev': 'Previous', 'next_w': 'Next', 'm_clear': 'Clear any {n} levels', 'm_stars': 'Collect {n} stars', 'm_trick': 'Land {n} trick shots', 'm_echo': 'Wake {n} spirits with echoes', 'm_oneshot': 'Clear {n} levels with one arrow', 'm_first': 'Clear {n} levels on the first try', 'm_near': 'Hear "So close!" {n} times', 'm_perfect': 'Clear {n} levels with 3 stars', 'sc_title': 'Star Chests', 'sc_body': '{n} stars reached! A chest opened.', 'sc_desc': 'Open chests with the stars you earn in this world', 'sc_tip': 'Short on stars? Replay cleared levels for 3 stars', 'stars_n': '★{n}', 'f_blast': 'Boom! Awake', 'f_boom': 'BOOM!', 'f_crack': 'Crash!', 'f_oops_boom': 'The baby got scared!', 't_baby_boom': 'The lantern blast reached a baby spirit. Mind the blast radius!', 'f_double': 'Double!', 'f_triple': 'Triple!', 'f_combo': '{n}× Combo!', 'f_trick': 'Trick Shot!', 'f_trick_x': 'Trick {x}', 'f_echo': 'Echo hit', 'f_near': 'So close!',
    'f_oops_me': 'Oops! Baby woke up', 'f_oops_echo': 'An echo woke the baby', 'f_ice': 'Crack!', 'f_prism': 'Prism!', 'f_split': 'Split!', 'f_shield': 'Ting!',
    'tut_press': 'Press', 'tut_pull': 'Pull…', 'tut_release': 'Release!',
    'sk_split': 'Split', 'sk_pierce': 'Pierce',
    'piggy': 'Starlight Piggy', 'piggy_sub': 'Coins pile up as you clear ({a} / {b})', 'piggy_now': 'Break it now for {n} coins', 'piggy_min': 'Can be broken from 1,000 coins',
    'noads': 'Remove Ads', 'noads_sub': 'No more ads between levels. Optional rewarded ads stay.', 'coins': 'Coins', 'trails': 'Arrow Trails', 'trails_sub': 'Shown in replays and shared clips',
    'in_use': 'Equipped', 'equip': 'Equip', 'pass_reward': 'Pass reward',
    'p_starter': 'Starter Pack', 'p_noads': 'Remove Ads', 'p_piggy': 'Break the Starlight Piggy', 'p_pass': 'Arrow Pass Premium',
    'p_coins_s': 'Handful of Coins', 'p_coins_m': 'Pouch of Coins', 'p_coins_l': 'Box of Coins', 'p_coins_xl': 'Chest of Coins', 'p_coins_xxl': 'Treasure Vault',
    'badge_once': 'One time', 'badge_rewarded': 'Rewarded ads stay', 'badge_popular': 'Popular',
    'rw_coins': '{n} coins', 'rw_hints': 'Hint ×{n}', 'rw_hearts': 'Life ×{n}', 'rw_inf_m': 'Unlimited lives {n}m', 'rw_inf_h': 'Unlimited lives {n}h', 'rw_trail': 'Trail “{x}”', 'rw_booster': '{x} ×{n}',
    'trail_moon': 'Moonlight', 'trail_ember': 'Ember', 'trail_aurora': 'Aurora',
    'pass_title': 'Arrow Pass', 'pass_desc': 'A new tier every {n} stars · {a} / {b}', 'premium_open': 'Unlock Premium {p}', 'premium': 'Premium',
    'ad_rewarded': 'Rewarded ad', 'ad_inter': 'Interstitial ad', 'ad_fake': 'This is a placeholder ad for development. Release builds show real ads.', 'close': 'Close',
    'iap_test': 'Development test purchase. No real money is charged.\n{p}', 'cancel': 'Cancel', 'pay': 'Pay {p}', 'restore': 'Restore purchases',
    'version': 'Echo Arrow · {v}',
    'world_clear': 'World {n} complete!', 'new_world': 'New world',
    'home': 'Home', 'collection': 'Collection', 'unlock_at': 'Unlocks after level {n}', 'tab_unlocked': '{x} unlocked!',
    'col_spirits': 'Spirits', 'col_devices': 'Devices', 'col_found': '{a} / {b} found', 'col_locked': 'Not discovered yet',
    'spirit_sleep': 'Sleepy Spirit', 'spirit_sleep_d': 'Hit it with an arrow to wake it. Wake them all to clear!',
    'spirit_baby': 'Baby Spirit', 'spirit_baby_d': 'Never hit it. Hitting one fails the round.',
    'spirit_shield': 'Shield Spirit', 'spirit_shield_d': 'Its shield deflects arrows. Hit it from behind.',
    'spirit_moving': 'Swaying Spirit', 'spirit_moving_d': 'Moves side to side. Time your shot.',
    'dev_wood': 'Wooden Wall', 'dev_wood_d': 'Arrows bounce off it.', 'dev_moss': 'Moss', 'dev_moss_d': 'Stops arrows. Pierce arrows go through.',
    'dev_lantern': 'Lantern', 'dev_lantern_d': 'Hit it and BOOM! Wakes nearby spirits at once and spreads to other lanterns. Shields don’t help — but babies wake up too.', 'dev_spinner': 'Ticking Mirror', 'dev_spinner_d': 'Ticks 45° on its own. When you shoot decides where it bounces.', 'dev_relay': 'Relay Ring', 'dev_relay_d': 'Catches an arrow for a moment, then fires it along the arrow. Tap to change direction.', 'dev_crystal': 'Glass Plug', 'dev_crystal_d': 'Breaks only from the side with the pink crack. Other sides bounce. The breaking arrow stops — send the next one through.', 'new_device': 'Something new!', 'got_it': 'Got it', 'dev_split': 'Split Arrow', 'dev_split_d': 'Splits into three on its first bounce. Limited per level.', 'dev_pierce': 'Piercing Arrow', 'dev_pierce_d': 'Flies right through moss. Blocked paths, no problem!', 'dev_mirror': 'Turning Mirror', 'dev_mirror_d': 'Tap to turn 45°. It changes your echoes’ paths too.', 'dev_bumper': 'Mushroom Bumper', 'dev_bumper_d': 'Round, so every spot bounces at a different angle.',
    'dev_ice': 'Ice', 'dev_ice_d': 'Bounces an arrow once, then shatters.', 'dev_portal': 'Portal', 'dev_portal_d': 'In through orange, out of blue in the same direction.',
    'dev_prism': 'Prism', 'dev_prism_d': 'Splits an arrow into three.', 'dev_gate': 'Switch & Gate', 'dev_gate_d': 'Hit the switch to open the gate for a moment. Team up with your echoes.',
    'dev_echo': 'Echo', 'dev_echo_d': 'A missed arrow flies again on your next shot, same angle, same timing.',
    'met_at': 'Meet it at level {n}',
  },
};

const _levelNames = {
  '늙은 참나무': 'Old Oak', '도토리 언덕': 'Acorn Hill', '새벽 거울': 'Dawn Mirror', '꺾인 빛': 'Bent Light', '메아리 탑': 'Echo Tower', '시간의 틈': 'Crack in Time', '기억의 화살': 'Arrow of Memory', '과거의 화살': 'Arrow of the Past',
  '첫 발': 'First Shot', '고요한 숲': 'Quiet Woods', '벽 튕기기': 'Bank Shot', '반딧불 길': 'Firefly Trail', '꿰뚫기': 'Pierce Through', '별빛 숲길': 'Starlit Path',
  '바람결': 'Breeze', '두 번 튕기기': 'Double Bounce', '이끼 계단': 'Mossy Steps', '나무뿌리 미로': 'Root Maze', '버섯 범퍼': 'Mushroom Bumper', '달빛 오솔길': 'Moonlit Lane',
  '이슬 웅덩이': 'Dew Pond', '흔들리는 정령': 'Swaying Spirit', '안개 낀 숲': 'Foggy Woods', '조용한 개울': 'Silent Brook', '세 정령': 'Three Spirits', '부엉이 둥지': "Owl's Nest",
  '잠든 언덕': 'Sleeping Hill', '버섯 마을': 'Mushroom Village', '은빛 거울': 'Silver Mirror', '반사의 방': 'Hall of Reflection', '잠망경': 'Periscope', '거울 너머': 'Through the Glass',
  '거울과 버섯': 'Mirror & Mushroom', '두 개의 달': 'Twin Moons', '거울 계단': 'Mirror Stairs', '방패 정령': 'Shield Spirit', '반짝이는 길': 'Glittering Road', '은빛 미로': 'Silver Maze',
  '아기 정령': 'Baby Spirits', '빛의 각도': 'Angle of Light', '거울 숲': 'Mirror Grove', '갈라지는 화살': 'Splitting Arrow', '비친 그림자': 'Reflected Shadow', '거울 정원': 'Mirror Garden',
  '거울 미로': 'Mirror Maze', '은빛 회랑': 'Silver Gallery', '빛 조각': 'Light Shards', '은빛 호수': 'Silver Lake', '얼음문': 'Ice Door', '서리 숲': 'Frost Woods',
  '반짝 동굴': 'Sparkle Cave', '포털': 'Portal', '포털 숲': 'Portal Woods', '얼음 다리': 'Ice Bridge', '프리즘': 'Prism', '무지개 샘': 'Rainbow Spring',
  '깨진 얼음': 'Broken Ice', '관통 화살': 'Pierce Arrow', '수정 동굴': 'Crystal Cave', '수정 계단': 'Crystal Stairs', '수정 정원': 'Crystal Garden', '수정 탑': 'Crystal Tower',
  '푸른 동굴': 'Blue Grotto', '차원의 문': 'Dimension Gate', '프리즘 언덕': 'Prism Hill', '얼음 정원': 'Ice Garden', '빛의 샘': 'Fountain of Light', '빛의 갈래': 'Rays of Light',
  '메아리': 'Echo', '쉿!': 'Shh!', '시간의 문': 'Gate of Time', '한 문, 두 정령': 'One Gate, Two Spirits', '닫히는 문': 'Closing Gate', '짧은 문': 'Brief Gate',
  '메아리 계곡': 'Echo Valley', '방패의 방': 'Shield Room', '메아리 숲': 'Echo Woods', '거울의 역설': 'Mirror Paradox', '되울림': 'Resonance', '이중 문': 'Double Gate',
  '울림 동굴': 'Ringing Cave', '빛의 갈림길': 'Fork of Light', '울리는 숲': 'Humming Woods', '잠긴 방': 'Locked Room', '피날레': 'Finale', '두 번의 기회': 'Second Chance',
  '열려라 문': 'Open Sesame', '되돌아오는 길': 'Way Back', '별똥별 언덕': 'Shooting Star Hill', '새벽 직전': 'Before Dawn', '마지막 숲': 'Last Forest', '마지막 화살': 'Last Arrow',
  '은하수 다리': 'Milky Way Bridge', '꿈의 끝자락': 'Edge of a Dream', '모든 길': 'All Paths', '유성의 길': 'Meteor Road', '정령의 시험': 'Spirit Trial', '정령의 왕관': 'Spirit Crown',
  '달의 정원': 'Moon Garden', '별빛 성채': 'Starlight Keep', '별의 끝': "Star's End", '혼돈의 숲': 'Chaos Woods', '여명': 'Daybreak', '빛과 메아리': 'Light and Echo',
  '끝없는 밤': 'Endless Night', '하늘섬': 'Sky Island', '별의 노래': 'Song of Stars', '별자리 숲': 'Constellation Woods',
};

const _hints = {
  '화면 아무 곳이나 누르고 뒤로 당겨 조준, 놓으면 발사!': 'Press anywhere, pull back to aim, release to shoot!',
  '초록 이끼는 화살을 붙잡아요. 나무 벽에 튕겨서 맞혀 보세요.': 'Green moss stops arrows. Bounce off the wooden walls instead.',
  '화살은 정령을 꿰뚫고 계속 날아가요. 한 발로 둘 다!': 'Arrows fly right through spirits. Get both with one shot!',
  '둥근 버섯은 맞는 자리에 따라 튕기는 각도가 달라져요.': 'Round mushrooms bounce at different angles depending on where you hit.',
  '누르고 있는 동안 시간이 느려져요. 타이밍을 노려 놓으세요.': 'Time slows while you hold. Release at the right moment.',
  '한 발로 셋 다 맞히면 별 3개. 여러 발로 나눠 쏴도 깰 수는 있어요.': 'Hit all three in one shot for 3 stars. Several shots still clear it.',
  '은빛 거울을 톡 누르면 45°씩 돌아가요. 사방이 이끼라 거울만이 길이에요.': 'Tap a silver mirror to turn it 45°. Moss is everywhere, so the mirror is the only way.',
  '거울 두 개를 이어서 꺾어 보세요.': 'Chain two mirrors together.',
  '방패 쪽은 화살을 튕겨내요. 등 뒤로 돌아가 맞히세요.': 'Shields deflect arrows. Hit the spirit from behind.',
  '분홍 아기 정령은 절대 맞히면 안 돼요! 맞히면 그 판은 실패예요.': 'Never hit the pink baby spirits! Hitting one fails the round.',
  '아래 [분열] 화살을 고르면 첫 번째로 튕길 때 세 갈래로 갈라져요.': 'Pick the [Split] arrow below. It splits in three on its first bounce.',
  '얼음은 한 번 튕겨내고 깨져요. 깨진 자리로 다시 들어가게 해 보세요.': 'Ice bounces an arrow once, then shatters. Send the arrow back through the gap.',
  '주황 포털로 들어가면 파란 포털로 같은 방향 그대로 나와요.': 'Enter the orange portal and exit the blue one in the same direction.',
  '프리즘에 맞으면 화살이 세 갈래로 갈라져요.': 'A prism splits your arrow into three.',
  '[관통] 화살은 이끼를 뚫고 지나가요.': 'The [Pierce] arrow goes straight through moss.',
  '1발: 스위치를 맞혀 문을 열어요. 2발: 지난 화살(메아리)이 다시 스위치를 맞히는 동안 문으로 쏘세요!': 'Shot 1: hit the switch to open the gate. Shot 2: while your echo hits the switch again, shoot through the gate!',
  '메아리는 매번 똑같이 날아가요. 아기 정령을 맞히는 메아리를 남기면 계속 실패해요. 그럴 땐 ↻ 다시 시작!': 'Echoes fly the same way every time. An echo that hits a baby spirit keeps failing — restart with ↻!',
  '문이 금방 닫혀요. 메아리가 스위치를 맞히는 순간을 노리세요.': 'The gate closes quickly. Time your shot to the moment your echo hits the switch.',
  '방패가 문 쪽을 보고 있어요. 방 안에서 한 번 더 튕겨야 해요.': 'The shield faces the gate. Bounce once more inside the room.',
  '거울을 돌리면 메아리의 길도 바뀌어요. 두 화살 모두에게 맞는 각도를 찾으세요.': "Turning the mirror changes your echo's path too. Find an angle that works for both arrows.",
  '한 발로? 프리즘이 나눈 화살 하나가 문을 열고, 다른 하나가 들어간다면…': 'One shot? What if one prism arrow opens the gate and another flies in…',
};
