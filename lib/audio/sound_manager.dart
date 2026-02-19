// 해원의 문 - 사운드 매니저
// mp3 파일 효과음 + Web Audio 합성 하이브리드
// FlameAudio로 mp3 재생, Web Audio로 폴백 합성

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flame_audio/flame_audio.dart';
import 'audio_synth_stub.dart'
    if (dart.library.js_interop) 'web_audio_synth.dart';

/// 사운드 이벤트 종류
enum SfxType {
  // 전투
  towerShoot,      // 화살/투사체 발사
  towerArtillery,  // 화포 발사
  towerMagic,      // 마법 공격
  towerSotdae,     // 솟대 정화
  
  // 적
  enemyHit,        // 적 피격
  enemyDeath,      // 적 처치
  enemyBoss,       // 보스 등장
  
  // 영웅
  heroSkill,       // 영웅 스킬 발동
  heroDeath,       // 영웅 사망
  heroRevive,      // 영웅 부활
  
  // UI
  uiClick,         // 버튼 클릭
  uiPlace,         // 타워 배치
  uiUpgrade,       // 업그레이드
  uiError,         // 오류/불가
  
  // 게임
  waveStart,       // 웨이브 시작
  victory,         // 승리
  defeat,          // 패배
  gatewayHit,      // 해원문 피격
  
  // 분기
  branchSelect,    // 분기 선택 팡파르
  branchThunder,   // 천벌뢰 낙뢰음
  branchFire,      // 화차 화염음
  branchGrapple,   // 도깨비 제압음
}

/// BGM 종류
enum BgmType {
  menu,    // 메인 메뉴
  dayBgm,  // 낮 전투
  nightBgm, // 밤 전투
  boss,    // 보스전
}

/// 사운드 매니저 — 싱글턴
class SoundManager {
  SoundManager._();
  static final SoundManager instance = SoundManager._();

  WebAudioSynth? _synth;
  bool _sfxEnabled = true;
  bool _bgmEnabled = true;
  double _sfxVolume = 0.7;
  double _bgmVolume = 0.4;
  bool _initialized = false;
  BgmType? _currentBgm;
  Timer? _bgmLoopTimer;
  bool _useFileBgm = false;  // mp3 BGM 사용 여부

  /// BGM 파일 매핑 — BgmType → mp3 파일명
  static const Map<BgmType, String> _bgmFileMap = {
    BgmType.menu: 'bgm/joseon_trap_uprising.mp3',
    BgmType.dayBgm: 'bgm/Joseon Trap Uprising-1.mp3',
    BgmType.nightBgm: 'bgm/검은 깃발.mp3',
    BgmType.boss: 'bgm/검은 깃발.mp3',
  };

  /// SFX 파일 매핑 — SfxType → mp3 파일명
  static const Map<SfxType, String> _sfxFileMap = {
    // 전투
    SfxType.towerShoot: 'sfx/Arrow.mp3',
    SfxType.towerArtillery: 'sfx/cannon_fire.mp3',
    SfxType.towerMagic: 'sfx/Magical.mp3',
    SfxType.towerSotdae: 'sfx/sotdae_purify.mp3',
    // 적
    SfxType.enemyHit: 'sfx/enemy_hit.mp3',
    SfxType.enemyDeath: 'sfx/enemy_death.mp3',
    SfxType.enemyBoss: 'sfx/boss_appear.mp3',
    // 영웅
    SfxType.heroSkill: 'sfx/hero_skill.mp3',
    SfxType.heroDeath: 'sfx/hero_death.mp3',
    SfxType.heroRevive: 'sfx/hero_revive.mp3',
    // UI
    SfxType.uiClick: 'sfx/Uiclick.mp3',
    SfxType.uiPlace: 'sfx/ui_place.mp3',
    SfxType.uiUpgrade: 'sfx/ui_upgrade.mp3',
    SfxType.uiError: 'sfx/ui_error.mp3',
    // 게임 이벤트 (waveStart는 파일 없음 → 합성 폴백)
    SfxType.victory: 'sfx/victory.mp3',
    SfxType.defeat: 'sfx/defeat.mp3',
    SfxType.gatewayHit: 'sfx/gateway_hit.mp3',
    // 분기
    SfxType.branchSelect: 'sfx/branch_select.mp3',
    SfxType.branchThunder: 'sfx/branch_thunder.mp3',
    SfxType.branchFire: 'sfx/branch_fire.mp3',
    SfxType.branchGrapple: 'sfx/branch_grapple.mp3',
  };

  /// SFX 쿨다운 — 동일 SFX 중복 재생 방지 (Web Audio 노드 폭주 방지)
  final Map<SfxType, int> _sfxLastPlayedMs = {};

  /// SFX 타입별 최소 재생 간격 (밀리초)
  static const Map<SfxType, int> _sfxMinIntervals = {
    SfxType.enemyHit: 80,       // 매 적중마다 호출 → 80ms 쿨다운
    SfxType.towerShoot: 60,     // 다수 타워 동시 발사 → 60ms
    SfxType.towerArtillery: 100,
    SfxType.towerMagic: 80,
    SfxType.towerSotdae: 200,
    SfxType.enemyDeath: 50,     // 다수 적 동시 사망
    SfxType.branchThunder: 150,
    SfxType.branchFire: 120,
    SfxType.branchGrapple: 120,
  };

  bool get sfxEnabled => _sfxEnabled;
  bool get bgmEnabled => _bgmEnabled;
  double get sfxVolume => _sfxVolume;
  double get bgmVolume => _bgmVolume;

  /// 초기화 (사용자 인터랙션 후 호출 필요)
  Future<void> init() async {
    if (_initialized) return;
    
    try {
      _synth = WebAudioSynth();
      _synth!.init();

      // mp3 파일 프리로드 (실패해도 합성 폴백으로 동작)
      try {
        await FlameAudio.audioCache.loadAll([
          // 전투
          'sfx/Arrow.mp3',
          'sfx/cannon_fire.mp3',
          'sfx/Magical.mp3',
          'sfx/sotdae_purify.mp3',
          // 적
          'sfx/enemy_hit.mp3',
          'sfx/enemy_death.mp3',
          'sfx/boss_appear.mp3',
          'sfx/ghost.mp3',
          // 영웅
          'sfx/hero_skill.mp3',
          'sfx/hero_death.mp3',
          'sfx/hero_revive.mp3',
          // UI
          'sfx/Uiclick.mp3',
          'sfx/ui_place.mp3',
          'sfx/ui_upgrade.mp3',
          'sfx/ui_error.mp3',
          'sfx/traditional.mp3',
          // 게임 이벤트
          'sfx/victory.mp3',
          'sfx/defeat.mp3',
          'sfx/gateway_hit.mp3',
          // 분기
          'sfx/branch_select.mp3',
          'sfx/branch_thunder.mp3',
          'sfx/branch_fire.mp3',
          'sfx/branch_grapple.mp3',
          // BGM
          'bgm/joseon_trap_uprising.mp3',
          'bgm/Joseon Trap Uprising-1.mp3',
          'bgm/검은 깃발.mp3',
        ]);
        _useFileBgm = true;
        if (kDebugMode) debugPrint('🎵 mp3 에셋 로드 완료');
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ mp3 로드 실패 (합성 폴백 사용): $e');
      }

      _initialized = true;
      if (kDebugMode) debugPrint('🔊 SoundManager 초기화 완료');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ SoundManager 초기화 실패: $e');
    }
  }

  /// SFX 켜기/끄기
  void toggleSfx() {
    _sfxEnabled = !_sfxEnabled;
  }

  /// BGM 켜기/끄기
  void toggleBgm() {
    _bgmEnabled = !_bgmEnabled;
    if (!_bgmEnabled) {
      stopBgm();
    } else if (_currentBgm != null) {
      playBgm(_currentBgm!);
    }
  }

  /// SFX 볼륨 설정 (0.0 ~ 1.0)
  void setSfxVolume(double vol) {
    _sfxVolume = vol.clamp(0.0, 1.0);
  }

  /// BGM 볼륨 설정 (0.0 ~ 1.0)
  void setBgmVolume(double vol) {
    _bgmVolume = vol.clamp(0.0, 1.0);
  }

  /// SFX 재생 (쿨다운 적용)
  void playSfx(SfxType type) {
    if (!_initialized || !_sfxEnabled) return;

    // 쿨다운 체크 — 동일 SFX 최소 간격 미만이면 무시
    final minInterval = _sfxMinIntervals[type];
    if (minInterval != null) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final lastPlayed = _sfxLastPlayedMs[type] ?? 0;
      if (nowMs - lastPlayed < minInterval) return;
      _sfxLastPlayedMs[type] = nowMs;
    }

    // mp3 파일이 있으면 파일 재생 우선
    final sfxFile = _sfxFileMap[type];
    if (sfxFile != null) {
      try {
        FlameAudio.play(sfxFile, volume: _sfxVolume);
        return;
      } catch (_) {
        // 파일 재생 실패 시 합성 폴백
      }
    }

    if (_synth == null) return;


    switch (type) {
      // 전투 SFX
      case SfxType.towerShoot:
        _synth!.playTone(
          frequency: 880, duration: 0.08, volume: _sfxVolume * 0.5,
          waveType: 'square', attack: 0.01, decay: 0.07,
        );
        break;

      case SfxType.towerArtillery:
        _synth!.playNoise(duration: 0.2, volume: _sfxVolume * 0.6);
        Future.delayed(const Duration(milliseconds: 50), () {
          _synth!.playTone(
            frequency: 120, duration: 0.3, volume: _sfxVolume * 0.7,
            waveType: 'sine', attack: 0.01, decay: 0.29,
          );
        });
        break;

      case SfxType.towerMagic:
        _synth!.playSweep(
          startFreq: 400, endFreq: 1200, duration: 0.15,
          volume: _sfxVolume * 0.4, waveType: 'sine',
        );
        break;

      case SfxType.towerSotdae:
        _synth!.playTone(
          frequency: 523, duration: 0.3, volume: _sfxVolume * 0.3,
          waveType: 'sine', attack: 0.05, decay: 0.25,
        );
        _synth!.playTone(
          frequency: 659, duration: 0.3, volume: _sfxVolume * 0.2,
          waveType: 'sine', attack: 0.1, decay: 0.2,
        );
        break;

      // 적 SFX
      case SfxType.enemyHit:
        _synth!.playNoise(duration: 0.05, volume: _sfxVolume * 0.3);
        break;

      case SfxType.enemyDeath:
        _synth!.playSweep(
          startFreq: 600, endFreq: 100, duration: 0.2,
          volume: _sfxVolume * 0.5, waveType: 'sawtooth',
        );
        break;

      case SfxType.enemyBoss:
        _synth!.playTone(
          frequency: 80, duration: 0.5, volume: _sfxVolume * 0.8,
          waveType: 'sawtooth', attack: 0.1, decay: 0.4,
        );
        Future.delayed(const Duration(milliseconds: 200), () {
          _synth!.playTone(
            frequency: 60, duration: 0.5, volume: _sfxVolume * 0.7,
            waveType: 'sawtooth', attack: 0.05, decay: 0.45,
          );
        });
        break;

      // 영웅 SFX
      case SfxType.heroSkill:
        _synth!.playSweep(
          startFreq: 300, endFreq: 900, duration: 0.2,
          volume: _sfxVolume * 0.6, waveType: 'square',
        );
        Future.delayed(const Duration(milliseconds: 100), () {
          _synth!.playTone(
            frequency: 1047, duration: 0.15, volume: _sfxVolume * 0.5,
            waveType: 'square', attack: 0.01, decay: 0.14,
          );
        });
        break;

      case SfxType.heroDeath:
        _synth!.playSweep(
          startFreq: 400, endFreq: 80, duration: 0.4,
          volume: _sfxVolume * 0.6, waveType: 'triangle',
        );
        break;

      case SfxType.heroRevive:
        _synth!.playArpeggio(
          frequencies: [523, 659, 784, 1047],
          noteDuration: 0.1,
          volume: _sfxVolume * 0.5,
          waveType: 'sine',
        );
        break;

      // UI SFX
      case SfxType.uiClick:
        _synth!.playTone(
          frequency: 1200, duration: 0.05, volume: _sfxVolume * 0.3,
          waveType: 'square', attack: 0.005, decay: 0.045,
        );
        break;

      case SfxType.uiPlace:
        _synth!.playTone(
          frequency: 440, duration: 0.1, volume: _sfxVolume * 0.4,
          waveType: 'triangle', attack: 0.01, decay: 0.09,
        );
        Future.delayed(const Duration(milliseconds: 60), () {
          _synth!.playTone(
            frequency: 660, duration: 0.1, volume: _sfxVolume * 0.4,
            waveType: 'triangle', attack: 0.01, decay: 0.09,
          );
        });
        break;

      case SfxType.uiUpgrade:
        _synth!.playArpeggio(
          frequencies: [440, 554, 660, 880],
          noteDuration: 0.08,
          volume: _sfxVolume * 0.5,
          waveType: 'triangle',
        );
        break;

      case SfxType.uiError:
        _synth!.playTone(
          frequency: 200, duration: 0.15, volume: _sfxVolume * 0.5,
          waveType: 'square', attack: 0.01, decay: 0.14,
        );
        Future.delayed(const Duration(milliseconds: 100), () {
          _synth!.playTone(
            frequency: 150, duration: 0.15, volume: _sfxVolume * 0.5,
            waveType: 'square', attack: 0.01, decay: 0.14,
          );
        });
        break;

      // 게임 SFX
      case SfxType.waveStart:
        _synth!.playArpeggio(
          frequencies: [262, 330, 392, 523],
          noteDuration: 0.12,
          volume: _sfxVolume * 0.6,
          waveType: 'square',
        );
        break;

      case SfxType.victory:
        _synth!.playArpeggio(
          frequencies: [523, 659, 784, 1047, 1319, 1568],
          noteDuration: 0.15,
          volume: _sfxVolume * 0.7,
          waveType: 'triangle',
        );
        break;

      case SfxType.defeat:
        _synth!.playArpeggio(
          frequencies: [392, 349, 330, 262, 196],
          noteDuration: 0.2,
          volume: _sfxVolume * 0.6,
          waveType: 'sawtooth',
        );
        break;

      case SfxType.gatewayHit:
        _synth!.playNoise(duration: 0.1, volume: _sfxVolume * 0.4);
        _synth!.playTone(
          frequency: 150, duration: 0.2, volume: _sfxVolume * 0.5,
          waveType: 'sine', attack: 0.01, decay: 0.19,
        );
        break;

      // ── 분기 SFX ──
      case SfxType.branchSelect:
        // 장엄한 아르페지오 (분기 선택 팡파르)
        _synth!.playArpeggio(
          frequencies: [523, 659, 784, 1047, 1319],
          noteDuration: 0.1,
          volume: _sfxVolume * 0.6,
          waveType: 'triangle',
        );
        Future.delayed(const Duration(milliseconds: 300), () {
          _synth!.playNoise(duration: 0.15, volume: _sfxVolume * 0.3);
        });
        break;

      case SfxType.branchThunder:
        // 번개 낙뢰: 날카로운 노이즈 → 저음 울림
        _synth!.playNoise(duration: 0.15, volume: _sfxVolume * 0.8);
        Future.delayed(const Duration(milliseconds: 50), () {
          _synth!.playSweep(
            startFreq: 2000, endFreq: 80, duration: 0.3,
            volume: _sfxVolume * 0.7, waveType: 'sawtooth',
          );
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          _synth!.playTone(
            frequency: 60, duration: 0.5, volume: _sfxVolume * 0.5,
            waveType: 'sine', attack: 0.05, decay: 0.45,
          );
        });
        break;

      case SfxType.branchFire:
        // 화염 폭발: 커지는 노이즈 + 저음
        _synth!.playSweep(
          startFreq: 100, endFreq: 400, duration: 0.2,
          volume: _sfxVolume * 0.5, waveType: 'sawtooth',
        );
        _synth!.playNoise(duration: 0.3, volume: _sfxVolume * 0.6);
        break;

      case SfxType.branchGrapple:
        // 도깨비 제압: 짧은 충격음 + 둔탁한 타격
        _synth!.playTone(
          frequency: 180, duration: 0.15, volume: _sfxVolume * 0.7,
          waveType: 'square', attack: 0.01, decay: 0.14,
        );
        Future.delayed(const Duration(milliseconds: 80), () {
          _synth!.playNoise(duration: 0.08, volume: _sfxVolume * 0.5);
        });
        break;
    }
  }

  /// BGM 재생
  void playBgm(BgmType type) {
    if (!_initialized || !_bgmEnabled) return;
    _currentBgm = type;
    _stopBgmLoop();

    // mp3 BGM 파일이 있으면 파일 재생
    if (_useFileBgm) {
      _playFileBgm();
      return;
    }

    // 폴백: 코드 합성 BGM
    if (_synth != null) {
      _startBgmLoop(type);
    }
  }

  /// mp3 파일 BGM 재생 (루프)
  void _playFileBgm() {
    final bgmFile = _bgmFileMap[_currentBgm] ?? 'bgm/joseon_trap_uprising.mp3';
    try {
      FlameAudio.bgm.play(bgmFile, volume: _bgmVolume);
      if (kDebugMode) debugPrint('🎵 BGM 재생: $bgmFile');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ BGM 파일 재생 실패: $e');
      // 폴백: 합성 BGM
      if (_synth != null && _currentBgm != null) {
        _startBgmLoop(_currentBgm!);
      }
    }
  }

  /// BGM 정지
  void stopBgm() {
    _stopBgmLoop();
    try {
      FlameAudio.bgm.stop();
    } catch (_) {}
  }

  void _stopBgmLoop() {
    _bgmLoopTimer?.cancel();
    _bgmLoopTimer = null;
  }

  /// BGM 루프 — 짧은 패턴을 반복 재생 (합성 폴백)
  void _startBgmLoop(BgmType type) {
    // 즉시 1회 재생
    _playBgmPattern(type);

    // 패턴 길이에 따라 반복
    final loopDuration = _getBgmLoopDuration(type);
    _bgmLoopTimer = Timer.periodic(loopDuration, (_) {
      if (_bgmEnabled && _initialized) {
        _playBgmPattern(type);
      }
    });
  }

  Duration _getBgmLoopDuration(BgmType type) {
    switch (type) {
      case BgmType.menu:
        return const Duration(seconds: 8);
      case BgmType.dayBgm:
        return const Duration(seconds: 4);
      case BgmType.nightBgm:
        return const Duration(seconds: 6);
      case BgmType.boss:
        return const Duration(seconds: 3);
    }
  }

  void _playBgmPattern(BgmType type) {
    if (!_initialized || _synth == null) return;

    switch (type) {
      case BgmType.menu:
        _playMenuBgm();
        break;
      case BgmType.dayBgm:
        _playDayBgm();
        break;
      case BgmType.nightBgm:
        _playNightBgm();
        break;
      case BgmType.boss:
        _playBossBgm();
        break;
    }
  }

  /// 메뉴 BGM — 한국 전통 느낌의 펜타토닉 멜로디 (차분)
  void _playMenuBgm() {
    // 한국 전통 펜타토닉 (궁상각치우)
    final notes = [262, 294, 330, 392, 440, 392, 330, 294]; // C D E G A G E D
    final vol = _bgmVolume * 0.25;

    for (int i = 0; i < notes.length; i++) {
      Future.delayed(Duration(milliseconds: i * 900), () {
        if (!_bgmEnabled || _synth == null) return;
        _synth!.playTone(
          frequency: notes[i].toDouble(),
          duration: 0.7,
          volume: vol,
          waveType: 'sine',
          attack: 0.1,
          decay: 0.6,
        );
        // 하모니 (5도 위)
        _synth!.playTone(
          frequency: notes[i] * 1.5,
          duration: 0.5,
          volume: vol * 0.3,
          waveType: 'sine',
          attack: 0.15,
          decay: 0.35,
        );
      });
    }
  }

  /// 낮 전투 BGM — 경쾌한 8비트 마치
  void _playDayBgm() {
    // 밝은 행진곡풍
    final melody = [523, 659, 784, 659, 523, 784, 659, 523]; // C5 E5 G5 ...
    final bass = [262, 262, 330, 330, 262, 262, 196, 196]; // C4 C4 E4 E4 ...
    final vol = _bgmVolume * 0.2;

    for (int i = 0; i < melody.length; i++) {
      Future.delayed(Duration(milliseconds: i * 450), () {
        if (!_bgmEnabled || _synth == null) return;
        // 멜로디
        _synth!.playTone(
          frequency: melody[i].toDouble(),
          duration: 0.35,
          volume: vol,
          waveType: 'square',
          attack: 0.02,
          decay: 0.33,
        );
        // 베이스
        _synth!.playTone(
          frequency: bass[i].toDouble(),
          duration: 0.4,
          volume: vol * 0.6,
          waveType: 'triangle',
          attack: 0.01,
          decay: 0.39,
        );
      });
    }
  }

  /// 밤 전투 BGM — 긴장감 있는 어두운 톤
  void _playNightBgm() {
    // 어두운 마이너 키 A minor
    final melody = [220, 262, 247, 220, 196, 220, 262, 247, 220, 165]; // Am 스케일
    final vol = _bgmVolume * 0.18;

    for (int i = 0; i < melody.length; i++) {
      Future.delayed(Duration(milliseconds: i * 550), () {
        if (!_bgmEnabled || _synth == null) return;
        _synth!.playTone(
          frequency: melody[i].toDouble(),
          duration: 0.45,
          volume: vol,
          waveType: 'sawtooth',
          attack: 0.05,
          decay: 0.4,
        );
        // 불안한 떨림 효과
        if (i % 3 == 0) {
          _synth!.playTone(
            frequency: melody[i] * 1.01, // 미세 디튠
            duration: 0.45,
            volume: vol * 0.4,
            waveType: 'sawtooth',
            attack: 0.05,
            decay: 0.4,
          );
        }
      });
    }
  }

  /// 보스 BGM — 물리적이고 강렬한 8비트
  void _playBossBgm() {
    final bass = [110, 110, 131, 131, 147, 147, 131, 131]; // 낮은 톤 반복
    final vol = _bgmVolume * 0.25;

    for (int i = 0; i < bass.length; i++) {
      Future.delayed(Duration(milliseconds: i * 350), () {
        if (!_bgmEnabled || _synth == null) return;
        // 강한 베이스
        _synth!.playTone(
          frequency: bass[i].toDouble(),
          duration: 0.3,
          volume: vol,
          waveType: 'sawtooth',
          attack: 0.01,
          decay: 0.29,
        );
        // 드럼비트 (노이즈)
        _synth!.playNoise(
          duration: 0.06,
          volume: vol * 0.8,
        );
      });
    }
  }

  /// 리소스 해제
  void dispose() {
    _stopBgmLoop();
    try {
      FlameAudio.bgm.stop();
    } catch (_) {}
    _synth?.dispose();
    _initialized = false;
  }
}
