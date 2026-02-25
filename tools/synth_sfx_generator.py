import os
import math
import wave
import struct
import random

SFX_DIR = "assets/audio/sfx"

def get_freq(t, freq, form="sine"):
    if form == "sine":
        return math.sin(2.0 * math.pi * freq * t)
    elif form == "square":
        return 1.0 if math.sin(2.0 * math.pi * freq * t) > 0 else -1.0
    elif form == "saw":
        return 2.0 * (t * freq - math.floor(0.5 + t * freq))
    elif form == "noise":
        return random.uniform(-1.0, 1.0)
    return 0.0

def generate_wave(filename, duration=0.5, freq_start=440.0, freq_end=440.0, vol_start=1.0, vol_end=0.0, form="sine", noise_mix=0.0, sample_rate=44100):
    filepath = os.path.join(SFX_DIR, filename)
    num_samples = int(sample_rate * duration)
    
    with wave.open(filepath, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = float(i) / sample_rate
            # Frequency sweep
            freq = freq_start + (freq_end - freq_start) * (t / duration)
            # Volume env (linear)
            vol = vol_start + (vol_end - vol_start) * (t / duration)
            
            # Mix base wave & noise
            base = get_freq(t, freq, form)
            noise = get_freq(t, 0, "noise")
            sample = (base * (1.0 - noise_mix)) + (noise * noise_mix)
            
            # Apply volume scaling to 16bit int
            val = int(sample * vol * 32767.0 * 0.5)
            # Clamp
            val = max(-32768, min(32767, val))
            data = struct.pack('<h', val)
            wav_file.writeframesraw(data)
            
    print(f"✅ 자체 합성 성공: {filepath} ({form}, {duration}s)")

def main():
    print("==================================================")
    print("   🦉 해원의 문 - 100% 로컬 합성 SFX 팩토리 가동  ")
    print("==================================================")
    if not os.path.exists(SFX_DIR):
        os.makedirs(SFX_DIR)

    # 1. 화살 (짧고 날카로운 바람 소리 - Noise/Saw)
    generate_wave("Arrow.wav", duration=0.15, freq_start=800, freq_end=1200, form="noise", noise_mix=0.8, vol_start=0.5, vol_end=0.0)
    # 2. 대포 (낮은 저음 피치드롭 + 노이즈 폭발)
    generate_wave("cannon_fire.wav", duration=0.6, freq_start=200, freq_end=40, form="noise", noise_mix=0.7, vol_start=1.0, vol_end=0.0)
    # 3. 마법 (높고 영롱한 주파수 상승)
    generate_wave("Magical.wav", duration=0.4, freq_start=400, freq_end=1200, form="sine", noise_mix=0.0, vol_start=0.6, vol_end=0.0)
    # 4. 솟대 정화 (청명한 종양 소리 잔향)
    generate_wave("sotdae_purify.wav", duration=0.8, freq_start=880, freq_end=880, form="sine", noise_mix=0.05, vol_start=0.7, vol_end=0.0)
    
    # 5. 적 피격 (둔탁한 타격음)
    generate_wave("enemy_hit.wav", duration=0.1, freq_start=100, freq_end=50, form="saw", noise_mix=0.3, vol_start=0.5, vol_end=0.0)
    # 6. 적 사망 (비명 같은 주파수 하락)
    generate_wave("enemy_death.wav", duration=0.4, freq_start=200, freq_end=50, form="square", noise_mix=0.4, vol_start=0.6, vol_end=0.0)
    # 7. 보스 출현 (거대하고 위협적인 저음 진동)
    generate_wave("boss_appear.wav", duration=1.5, freq_start=80, freq_end=60, form="saw", noise_mix=0.2, vol_start=0.8, vol_end=0.0)
    
    # 8. 영웅 스킬 (역동적인 상승음)
    generate_wave("hero_skill.wav", duration=0.5, freq_start=300, freq_end=900, form="saw", noise_mix=0.1, vol_start=0.7, vol_end=0.0)
    # 9. 영웅 사망 (절망적인 하락음)
    generate_wave("hero_death.wav", duration=0.8, freq_start=400, freq_end=100, form="sine", noise_mix=0.2, vol_start=0.8, vol_end=0.0)
    # 10. 영웅 부활 (성스러운 상승 잔향)
    generate_wave("hero_revive.wav", duration=1.2, freq_start=500, freq_end=1200, form="sine", noise_mix=0.0, vol_start=0.0, vol_end=0.8)
    
    # 11. 웨이브 시작 (웅장한 피루트각 뿔고동)
    generate_wave("wave_start.wav", duration=1.5, freq_start=200, freq_end=220, form="square", noise_mix=0.1, vol_start=0.8, vol_end=0.0)
    
    # 12. 분기 선택 (쾌속 팡파르)
    generate_wave("branch_select.wav", duration=0.6, freq_start=600, freq_end=1200, form="square", noise_mix=0.0, vol_start=0.5, vol_end=0.0)
    # 13. 천벌뢰 (날카롭고 강렬한 노이즈 폭발)
    generate_wave("branch_thunder.wav", duration=0.5, freq_start=1500, freq_end=100, form="noise", noise_mix=0.9, vol_start=1.0, vol_end=0.0)
    # 14. 화차 (타오르는 긴 지속 소음)
    generate_wave("branch_fire.wav", duration=0.8, freq_start=400, freq_end=200, form="noise", noise_mix=0.8, vol_start=0.8, vol_end=0.0)
    # 15. 도깨비 제압 (가장 둔탁한 파열음)
    generate_wave("branch_grapple.wav", duration=0.3, freq_start=100, freq_end=20, form="saw", noise_mix=0.5, vol_start=0.9, vol_end=0.0)

    print("==================================================")
    print("🎉 생성 및 적용 완료! 이제 게임에서 소리를 테스트해보세요!")

if __name__ == '__main__':
    main()
