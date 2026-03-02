import os
import math
import wave
import struct
import random

SFX_DIR = "assets/audio/sfx"

# ── 1. 향상된 파형(Waveform) 생성기 ──
def get_freq(t, freq, form="sine"):
    if form == "sine":
        return math.sin(2.0 * math.pi * freq * t)
    elif form == "square":
        # 약간의 하모닉을 추가하여 너무 거칠지 않은 사각파
        base = 1.0 if math.sin(2.0 * math.pi * freq * t) > 0 else -1.0
        return base * 0.8 + 0.2 * math.sin(6.0 * math.pi * freq * t)
    elif form == "saw":
        # 톱니파도 고주파수 앨리어싱을 줄이기 위해 부드럽게 조절
        s = 2.0 * (t * freq - math.floor(0.5 + t * freq))
        return s * 0.9 + 0.1 * math.sin(2.0 * math.pi * freq * t)
    elif form == "noise":
        return random.uniform(-1.0, 1.0)
    elif form == "magic":
        # 마법처럼 영롱한 코러스 효과 (복합 사인파)
        return (math.sin(2.0 * math.pi * freq * t) * 0.6 + 
                math.sin(2.0 * math.pi * freq * 1.5 * t) * 0.3 + 
                math.sin(2.0 * math.pi * freq * 2.0 * t) * 0.1)
    return 0.0

# ── 2. 향상된 ADSR 엔벨로프 및 다중 파형 믹서 ──
def generate_advanced_wave(filename, duration=0.5, 
                           freq_start=440.0, freq_end=440.0, 
                           vol_start=1.0, vol_end=0.0, 
                           form="sine", noise_mix=0.0, 
                           attack=0.05, decay=0.1, sustain=0.7, release=0.2,
                           sample_rate=44100):
    filepath = os.path.join(SFX_DIR, filename)
    num_samples = int(sample_rate * duration)
    
    # 공격, 릴리스 시간을 샘플 수로 변환
    attack_samples = int(sample_rate * attack)
    release_samples = int(sample_rate * release)
    
    with wave.open(filepath, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = float(i) / sample_rate
            
            # 주파수 슬라이드 (지수적 하락/상승 방식 도입으로 타격감 증대)
            progress = t / duration
            freq = freq_start * ((freq_end / freq_start) ** progress) if freq_start > 0 else 0
            
            # ADSR 엔벨로프 볼륨 적용 (Pop 노이즈 방지 및 자연스러운 여운)
            if i < attack_samples:
                env = (i / attack_samples)
            elif i > num_samples - release_samples:
                env = sustain * ((num_samples - i) / release_samples)
            else:
                env = sustain # 단순화를 위해 Decay 단계 생략하고 sustain으로 통일

            # 기본 볼륨 곡선 (선형)
            base_vol = vol_start + (vol_end - vol_start) * progress
            final_vol = base_vol * env
            
            # 파형 믹싱
            base_sig = get_freq(t, freq, form)
            noise_sig = get_freq(t, 0, "noise")
            sample = (base_sig * (1.0 - noise_mix)) + (noise_sig * noise_mix)
            
            # 클리핑 방지 및 16비트 변환
            val = int(sample * final_vol * 32767.0 * 0.7) # 마진 0.7 
            val = max(-32768, min(32767, val))
            
            data = struct.pack('<h', val)
            wav_file.writeframesraw(data)
            
    print(f"🎵 프리미엄 SFX 생성 완료: {filepath} ({form}, {duration}s)")

def main():
    print("==========================================================")
    print(" 🦉 해원의 문 - 프리미엄 하이퀄리티 합성 SFX 팩토리 가동 ")
    print("==========================================================")
    
    if not os.path.exists(SFX_DIR):
        os.makedirs(SFX_DIR)

    # 1. UI & 공통 시스템 (더 영롱하고 명확하게)
    generate_advanced_wave("wave_start.wav", duration=2.0, freq_start=150, freq_end=300, form="square", noise_mix=0.05, vol_start=0.9, vol_end=0.0, attack=0.3, release=0.8)
    generate_advanced_wave("branch_select.wav", duration=0.8, freq_start=440, freq_end=880, form="magic", noise_mix=0.0, vol_start=0.8, vol_end=0.0, attack=0.05, release=0.3)
    
    # 2. 타워 공격 (묵직하고 날카로운 임팩트)
    generate_advanced_wave("Arrow.wav", duration=0.2, freq_start=1500, freq_end=800, form="noise", noise_mix=0.9, vol_start=0.7, vol_end=0.0, attack=0.01, release=0.05)
    generate_advanced_wave("cannon_fire.wav", duration=0.8, freq_start=250, freq_end=30, form="noise", noise_mix=0.8, vol_start=1.0, vol_end=0.0, attack=0.01, release=0.4)
    generate_advanced_wave("Magical.wav", duration=0.5, freq_start=600, freq_end=1500, form="magic", noise_mix=0.1, vol_start=0.7, vol_end=0.0, attack=0.05, release=0.2)
    generate_advanced_wave("sotdae_purify.wav", duration=1.5, freq_start=1200, freq_end=600, form="magic", noise_mix=0.05, vol_start=0.8, vol_end=0.0, attack=0.1, release=1.0)
    
    # 3. 영웅 스킬 & 액션 (역동성과 여운 강조)
    generate_advanced_wave("hero_skill.wav", duration=1.0, freq_start=400, freq_end=1200, form="saw", noise_mix=0.15, vol_start=0.9, vol_end=0.0, attack=0.1, release=0.5)
    generate_advanced_wave("hero_death.wav", duration=1.0, freq_start=300, freq_end=50, form="sine", noise_mix=0.3, vol_start=0.8, vol_end=0.0, attack=0.05, release=0.5)
    generate_advanced_wave("hero_revive.wav", duration=2.0, freq_start=400, freq_end=1600, form="magic", noise_mix=0.0, vol_start=0.0, vol_end=1.0, attack=1.0, release=0.5)
    
    # 4. 적 생태계 (더 기괴하고 소름돋게)
    generate_advanced_wave("enemy_hit.wav", duration=0.15, freq_start=150, freq_end=80, form="saw", noise_mix=0.5, vol_start=0.6, vol_end=0.0, attack=0.01, release=0.1)
    generate_advanced_wave("enemy_death.wav", duration=0.6, freq_start=300, freq_end=80, form="square", noise_mix=0.6, vol_start=0.7, vol_end=0.0, attack=0.02, release=0.3)
    generate_advanced_wave("boss_appear.wav", duration=2.5, freq_start=100, freq_end=40, form="saw", noise_mix=0.4, vol_start=1.0, vol_end=0.0, attack=0.5, release=1.0)
    
    # 5. 분기 타워 최종 공격음 (압도적인 파괴력)
    generate_advanced_wave("branch_thunder.wav", duration=0.7, freq_start=2000, freq_end=50, form="noise", noise_mix=0.95, vol_start=1.0, vol_end=0.0, attack=0.01, release=0.4)
    generate_advanced_wave("branch_fire.wav", duration=1.2, freq_start=600, freq_end=100, form="noise", noise_mix=0.85, vol_start=0.9, vol_end=0.0, attack=0.2, release=0.6)
    generate_advanced_wave("branch_grapple.wav", duration=0.4, freq_start=120, freq_end=20, form="saw", noise_mix=0.6, vol_start=1.0, vol_end=0.0, attack=0.02, release=0.2)

    print("==========================================================")
    print("🎉 고품질 SFX 14종 생성 및 덮어쓰기 로직 준비 완료!")

if __name__ == '__main__':
    main()
