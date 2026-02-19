// 해원의 문 - Web Audio API 합성기
// 코드 기반 사운드 생성 (저작권 무결)
// Flutter Web에서 dart:js_interop으로 Web Audio API 직접 호출

import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

// ── Web Audio API JS Interop 바인딩 (최소한의 안전한 정의) ──

@JS('AudioContext')
extension type JSAudioContext._(JSObject _) implements JSObject {
  external factory JSAudioContext();
  external JSAudioDestinationNode get destination;
  external double get currentTime;
  external num get sampleRate;
  external String get state;
  external JSPromise resume();
  external JSOscillatorNode createOscillator();
  external JSGainNode createGain();
}

@JS()
extension type JSAudioNode._(JSObject _) implements JSObject {
  external JSAudioNode connect(JSAudioNode destination);
  external void disconnect();
}

@JS()
extension type JSAudioDestinationNode._(JSObject _) implements JSAudioNode {}

@JS()
extension type JSAudioParam._(JSObject _) implements JSObject {
  external set value(num val);
  external num get value;
  external JSAudioParam linearRampToValueAtTime(num value, num endTime);
  external JSAudioParam setValueAtTime(num value, num startTime);
}

@JS()
extension type JSOscillatorNode._(JSObject _) implements JSAudioNode {
  external set type(String type);
  external JSAudioParam get frequency;
  external void start([num when]);
  external void stop([num when]);
}

@JS()
extension type JSGainNode._(JSObject _) implements JSAudioNode {
  external JSAudioParam get gain;
}

// ── 합성기 클래스 ──

/// Web Audio API 합성기 — 실제 소리 생성
class WebAudioSynth {
  JSAudioContext? _audioCtx;
  bool _initialized = false;

  /// 동시 활성 오디오 노드 수 제한 (웹 성능 보호)
  int _activeNodeCount = 0;
  static const int _maxActiveNodes = 30;

  /// 초기화 (사용자 제스처 후 호출 권장)
  void init() {
    if (_initialized) return;
    try {
      _audioCtx = JSAudioContext();
      _initialized = true;
      if (kDebugMode) debugPrint('🎵 WebAudioSynth 초기화 완료 (Web Audio API)');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ WebAudioSynth 초기화 실패: $e');
    }
  }

  /// AudioContext 활성 상태 확인
  void _ensureResumed() {
    if (_audioCtx == null) return;
    if (_audioCtx!.state == 'suspended') {
      _audioCtx!.resume();
    }
  }

  /// 노드 정리 예약 — stop 후 disconnect + 카운터 감소
  void _scheduleNodeCleanup(JSOscillatorNode osc, JSGainNode gain, double durationSec) {
    _activeNodeCount++;
    final cleanupMs = ((durationSec + 0.1) * 1000).toInt();
    Future.delayed(Duration(milliseconds: cleanupMs), () {
      try {
        osc.disconnect();
        gain.disconnect();
      } catch (_) {}
      _activeNodeCount--;
    });
  }

  /// 단순 톤 재생 (OscillatorNode + GainNode ADSR 엔벨로프)
  void playTone({
    required double frequency,
    required double duration,
    required double volume,
    String waveType = 'square',
    double attack = 0.01,
    double decay = 0.1,
  }) {
    if (!_initialized || _audioCtx == null) return;
    if (_activeNodeCount >= _maxActiveNodes) return; // 노드 제한
    _ensureResumed();

    try {
      final ctx = _audioCtx!;
      final now = ctx.currentTime;

      final osc = ctx.createOscillator();
      osc.type = waveType;
      osc.frequency.value = frequency;

      final gain = ctx.createGain();
      gain.gain.setValueAtTime(0, now);
      gain.gain.linearRampToValueAtTime(volume, now + attack);
      gain.gain.linearRampToValueAtTime(0, now + attack + decay);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + duration + 0.05);

      _scheduleNodeCleanup(osc, gain, duration);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ playTone 오류: $e');
    }
  }

  /// 노이즈 재생 — 3개 디튠된 오실레이터로 노이즈 근사 (6→3으로 최적화)
  void playNoise({
    required double duration,
    required double volume,
  }) {
    if (!_initialized || _audioCtx == null) return;
    if (_activeNodeCount >= _maxActiveNodes) return;
    _ensureResumed();

    try {
      final ctx = _audioCtx!;
      final now = ctx.currentTime;

      // 3개 주파수로 축소 (6→3, 노드 생성 50% 감소)
      final frequencies = [200.0, 800.0, 2500.0];
      for (final freq in frequencies) {
        final osc = ctx.createOscillator();
        osc.type = 'sawtooth';
        osc.frequency.value = freq;

        final gain = ctx.createGain();
        gain.gain.setValueAtTime(volume * 0.25, now);
        gain.gain.linearRampToValueAtTime(0, now + duration);

        osc.connect(gain);
        gain.connect(ctx.destination);

        osc.start(now);
        osc.stop(now + duration + 0.05);

        _scheduleNodeCleanup(osc, gain, duration);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ playNoise 오류: $e');
    }
  }

  /// 주파수 스윕 (오실레이터 주파수 시간에 따라 변경)
  void playSweep({
    required double startFreq,
    required double endFreq,
    required double duration,
    required double volume,
    String waveType = 'sine',
  }) {
    if (!_initialized || _audioCtx == null) return;
    if (_activeNodeCount >= _maxActiveNodes) return;
    _ensureResumed();

    try {
      final ctx = _audioCtx!;
      final now = ctx.currentTime;

      final osc = ctx.createOscillator();
      osc.type = waveType;
      osc.frequency.setValueAtTime(startFreq, now);
      osc.frequency.linearRampToValueAtTime(endFreq, now + duration);

      final gain = ctx.createGain();
      gain.gain.setValueAtTime(volume, now);
      gain.gain.linearRampToValueAtTime(0, now + duration);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + duration + 0.05);

      _scheduleNodeCleanup(osc, gain, duration);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ playSweep 오류: $e');
    }
  }

  /// 아르페지오 (음계 연속 재생)
  void playArpeggio({
    required List<double> frequencies,
    required double noteDuration,
    required double volume,
    String waveType = 'square',
  }) {
    if (!_initialized) return;
    for (int i = 0; i < frequencies.length; i++) {
      Future.delayed(Duration(milliseconds: (i * noteDuration * 1000).toInt()), () {
        playTone(
          frequency: frequencies[i],
          duration: noteDuration * 0.9,
          volume: volume,
          waveType: waveType,
        );
      });
    }
  }

  /// 리소스 해제
  void dispose() {
    _audioCtx = null;
    _initialized = false;
    _activeNodeCount = 0;
  }
}
