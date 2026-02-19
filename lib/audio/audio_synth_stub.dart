// 해원의 문 - Web Audio Synth Stub (Non-Web 플랫폼용)
// Windows, Android, iOS 등에서는 Web Audio API를 사용할 수 없으므로
// 모든 메서드가 no-op으로 동작

/// Web Audio API 합성기 — Non-Web 플랫폼용 Stub
class WebAudioSynth {
  /// 초기화 (no-op)
  void init() {}

  /// 단순 톤 재생 (no-op)
  void playTone({
    required double frequency,
    required double duration,
    required double volume,
    String waveType = 'square',
    double attack = 0.01,
    double decay = 0.1,
  }) {}

  /// 노이즈 재생 (no-op)
  void playNoise({
    required double duration,
    required double volume,
  }) {}

  /// 주파수 스윕 (no-op)
  void playSweep({
    required double startFreq,
    required double endFreq,
    required double duration,
    required double volume,
    String waveType = 'sine',
  }) {}

  /// 아르페지오 (no-op)
  void playArpeggio({
    required List<double> frequencies,
    required double noteDuration,
    required double volume,
    String waveType = 'square',
  }) {}

  /// 리소스 해제 (no-op)
  void dispose() {}
}
