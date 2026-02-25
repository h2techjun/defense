import os
import sys
import json
import base64
import requests
import time
from io import BytesIO
from PIL import Image
from rembg import remove
from google.oauth2 import service_account
from google.auth.transport.requests import Request

# ── 설정값 ──
KEY_PATH = r"d:\00_Project\05_Defense\autotrade-engine-key.json"
PROJECT_ID = "autotrade-engine"
LOCATION = "us-central1"
MODEL_ID = "imagen-3.0-generate-001"

BASE_DIR = r"d:\00_Project\05_Defense\assets\images"

ASSET_JOBS = []

# ── Backgrounds ──
ASSET_JOBS.extend([
    {"filepath": "bg/bg_main_menu.png", "prompt": "A beautiful, premium 2D mobile game main menu background illustration. Dark fantasy Korean traditional theme, stylized, rich colors, atmospheric, mystical moonlight, foggy distant mountains, glowing shrine, high quality digital art.", "remove_bg": False},
    {"filepath": "bg/bg_stage_1.png", "prompt": "A top-down view of a Korean traditional village at night, 2D game background, dark fantasy, subtle moonlight, stylized environment, tower defense map background, dirt paths and grass.", "remove_bg": False},
    {"filepath": "bg/bg_stage_2.png", "prompt": "A top-down view of a dark spooky Korean bamboo forest at night, 2D game background, dark fantasy, foggy glowing, tower defense map background, dirt paths.", "remove_bg": False},
])

# ── Objects ──
ASSET_JOBS.extend([
    {"filepath": "objects/obj_sacred_tree.png", "prompt": "A majestic Korean sacred tree (Dangsan Namu) with colorful ribbons tied to its branches, mystical glow, 2D game asset, premium mobile game style, chibi/stylized, isolated on white background, high resolution.", "remove_bg": True},
    {"filepath": "objects/obj_shrine.png", "prompt": "A small traditional Korean ancestor shrine (Seonangdang) made of stones and wood, mystical blue glow, 2D game asset, premium mobile game style. Isolated on white background.", "remove_bg": True},
])

# ── FX (Animated Frames) ──
for f in range(1, 6):
    prompts = [
        "Frame 1 of 5: A tiny glowing 2D game particle of a magical fire spark, premium mobile game effect. Isolated on solid black background.",
        "Frame 2 of 5: A growing glowing 2D game particle of a magical fire, premium mobile game effect. Isolated on solid black background.",
        "Frame 3 of 5: A massive vibrant glowing 2D game particle of a magical fire explosion burst, premium mobile game effect. Isolated on solid black background.",
        "Frame 4 of 5: A dissipating 2D game particle of magical fire, premium mobile game effect. Isolated on solid black background.",
        "Frame 5 of 5: Fading glowing embers 2D game particle, premium mobile game effect. Isolated on solid black background."
    ]
    ASSET_JOBS.append({"filepath": f"effects/fx_fire_{f}.png", "prompt": prompts[f-1], "remove_bg": True})

for f in range(1, 6):
    prompts = [
        "Frame 1 of 5: A tiny glowing 2D game particle of magical lightning static, cyan and purple, premium mobile game effect. Isolated on solid black background.",
        "Frame 2 of 5: A small branching 2D game particle of magical lightning, cyan and purple, premium mobile game effect. Isolated on solid black background.",
        "Frame 3 of 5: A sharp massive glowing 2D game particle of a magical lightning strike explosion, cyan and purple, premium mobile game effect. Isolated on solid black background.",
        "Frame 4 of 5: A dissipating 2D game particle of magical lightning, cyan and purple, premium mobile game effect. Isolated on solid black background.",
        "Frame 5 of 5: Fading glowing static sparks 2D game particle, cyan and purple, premium mobile game effect. Isolated on solid black background."
    ]
    ASSET_JOBS.append({"filepath": f"effects/fx_lightning_{f}.png", "prompt": prompts[f-1], "remove_bg": True})

for f in range(1, 5):
    prompts = [
        "Frame 1 of 4: A tiny sharp 2D game particle of a physical hit impact spark, white and yellow, premium mobile game effect. Isolated on solid black background.",
        "Frame 2 of 4: A sharp glowing 2D game particle of a physical hit impact, white and yellow, premium mobile game effect. Isolated on solid black background.",
        "Frame 3 of 4: A massive sharp glowing 2D game particle of a physical slash hit impact explosion, white and yellow, premium mobile game effect. Isolated on solid black background.",
        "Frame 4 of 4: Fading 2D game particle of a physical hit impact, white and yellow, premium mobile game effect. Isolated on solid black background.",
    ]
    ASSET_JOBS.append({"filepath": f"effects/fx_hit_{f}.png", "prompt": prompts[f-1], "remove_bg": True})


# ── Heroes (Tiers 1, 2, 3) ──
heroes = [
    ("kkaebi", "small Korean Dokkaebi (Goblin) holding a tiny wooden club"),
    ("hongGildong", "Korean righteous outlaw hero Hong Gil-dong with a staff and blue traditional robes"),
    ("guMiho", "beautiful Korean nine-tailed fox spirit (Gumiho) in white robes with mystical tails"),
    ("tigerHunter", "Korean traditional tiger hunter (Chakhogapsa) with a matchlock rifle and tiger pelt"),
    ("darkYeomra", "dark king of the underworld (Yeomra) with a judge's hat and dark aura")
]
for hero_id, desc in heroes:
    for tier in [1, 2, 3]:
        evolution_prompt = ["basic form", "upgraded form with more details and glowing aura", "fully evolved form, majestic, ultimate power, massive glow"][tier-1]
        ASSET_JOBS.append({
            "filepath": f"heroes/hero_{hero_id}_{tier}.png",
            "prompt": f"A 2D game asset of {desc}, {evolution_prompt}, chibi style, premium mobile tower defense game character. Isolated on white background.",
            "remove_bg": True
        })

# ── Towers (Tiers 1, 2, 3) ──
towers = [
    ("archer", "wooden archer tower, traditional Korean architecture style (Giwa roof)"),
    ("barracks", "traditional Korean military outpost tent, weapon racks outside"),
    ("shaman", "mystical Korean shaman (Mudang) shrine, floating talismans, spiritual aura"),
    ("artillery", "traditional Korean cannon (Singijeon) installation, wooden and brass details"),
    ("sotdae", "Korean traditional wooden pole with a carved bird on top (Sotdae), glowing holy light")
]
for tower_id, desc in towers:
    for tier in [1, 2, 3]:
        upgrade_prompt = ["basic wooden structure", "fortified structure with stone and metal elements", "ultimate legendary glowing structure, massive details"][tier-1]
        ASSET_JOBS.append({
            "filepath": f"towers/tower_{tower_id}_{tier}.png",
            "prompt": f"A 2D game asset of {desc}, {upgrade_prompt}, chibi style, dynamic angle, premium mobile tower defense game. Isolated on white background.",
            "remove_bg": True
        })

# ── Tower Branches ──
branches = [
    ("rocket_battery", "hwacha multiple rocket launcher battery burning with fire"),
    ("spirit_hunter", "elite tiger hunter watchtower with heavy rifles"),
    ("general_totem", "massive stone guardian general statue (Jangseung) with a spear"),
    ("goblin_ring", "Dokkaebi magical stone ring portal glowing green"),
    ("shaman_temple", "grand majestic shaman blessing temple with massive golden statues"),
    ("grim_reaper", "dark grim reaper (Jeoseung Saja) spooky underworld portal"),
    ("fire_dragon", "massive mythical fire dragon cannon shaped like a dragon head breathing flames"),
    ("heavenly_thunder", "divine heavenly thunder drum (Bugo) on a cloud pagoda calling lightning"),
    ("phoenix_totem", "legendary ancient Korean phoenix (Bonghwang) nest glowing with holy light"),
    ("earth_spirit", "giant earth spirit golem altar made of glowing jade and mossy boulders")
]
for bid, desc in branches:
    ASSET_JOBS.append({
        "filepath": f"towers/tower_{bid}.png",
        "prompt": f"A 2D game asset of {desc}, ultimate top tier tower, massive details, chibi style, dynamic angle, premium mobile tower defense game. Isolated on white background.",
        "remove_bg": True
    })

# ── Enemies (General & Bosses) ──
enemies = {
    "enemy_hungry_ghost": "small Korean zombie (Gangshi) jumping",
    "enemy_straw_shoe": "animated possessed straw shoe monster (Jipsin)",
    "enemy_burdened": "undead burdened laborer ghost carrying a heavy cursed sack",
    "enemy_maiden": "creepy floating Korean maiden ghost (Gwisin) in white funeral dress",
    "enemy_egg_ghost": "faceless egg ghost (Dalgyal Gwisin) floating in dark rags",
    "enemy_tiger_slave": "possessed tiger-slave ghost crawling",
    "enemy_fire_dog": "fiery hellhound dog spirit (Bulgae)",
    "enemy_shadow_golem": "big scary shadow mud golem",
    "enemy_old_fox": "evil old fox spirit holding a skull",
    "enemy_failed_dragon": "corrupted Imugi (failed dragon serpent) with dark scales",
    "enemy_evolved_tiger": "huge spectral demon tiger (Chang-gwi)",
    "enemy_saetani": "creepy cursed child doll spirit",
    "enemy_shadow_child": "dark shadowy floating shadow wraith",
    "enemy_malicious_bird": "corrupted evil crow spirit",
    "enemy_face_stealer": "creepy ghost wearing multiple stolen masks",
    # Bosses
    "boss_ogre_lord": "massive terrifying red Ogre Lord (Dokkaebi King)",
    "boss_mountain_lord": "giant legendary mountain deity tiger boss",
    "boss_great_egg": "gigantic mutated blob egg ghost boss",
    "boss_tyrant_king": "undead skeletal tyrant king on a dark throne",
    "boss_gatekeeper": "imposing underworld portal gatekeeper demon boss"
}
for enum_name, desc in enemies.items():
    ASSET_JOBS.append({
        "filepath": f"enemies/{enum_name}.png",
        "prompt": f"A cute but scary 2D game asset of {desc}, creepy chibi style, dynamic pose, premium mobile tower defense game enemy. Isolated on white background.",
        "remove_bg": True
    })


def get_access_token():
    try:
        credentials = service_account.Credentials.from_service_account_file(
            KEY_PATH, scopes=["https://www.googleapis.com/auth/cloud-platform"]
        )
        request = Request()
        credentials.refresh(request)
        return credentials.token
    except Exception as e:
        print(f"❌ 토큰 발급 오류: {e}")
        return None

def generate_image(prompt, output_filepath, remove_bg):
    full_path = os.path.join(BASE_DIR, output_filepath)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
        
    print(f"🎨 이미지 생성 요청 중: {output_filepath}")
    
    token = get_access_token()
    if not token:
        return False

    url = f"https://{LOCATION}-aiplatform.googleapis.com/v1/projects/{PROJECT_ID}/locations/{LOCATION}/publishers/google/models/{MODEL_ID}:predict"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    payload = {
        "instances": [{"prompt": prompt}],
        "parameters": {"sampleCount": 1, "aspectRatio": "1:1", "outputOptions": {"mimeType": "image/png"}}
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        if response.status_code == 200:
            data = response.json()
            predictions = data.get("predictions", [])
            if not predictions:
                 print(f"❌ 생성 결과 없음")
                 return False
                 
            b64_img = predictions[0].get("bytesBase64Encoded")
            if b64_img:
                img_data = base64.b64decode(b64_img)
                if remove_bg:
                    print(f"✂️ 배경 투명화(rembg) 처리 중...")
                    input_img = Image.open(BytesIO(img_data))
                    output_img = remove(input_img)
                    output_img.save(full_path, "PNG")
                else:
                    with open(full_path, "wb") as f:
                        f.write(img_data)
                print(f"✅ 에셋 저장 완료: {full_path}")
                return True
        else:
            print(f"❌ API 오류 ({response.status_code}): {response.text}")
    except Exception as e:
        print(f"🚨 예외 발생: {e}")
    return False

def main():
    print("==================================================")
    print(f"   🦉 해원의 문 - Vertex AI 대량 에셋 팩토리 가동 ")
    print(f"   총 조달 예정 에셋 개수: {len(ASSET_JOBS)}개")
    print("==================================================")
    
    success = 0
    for i, job in enumerate(ASSET_JOBS, 1):
        # 이미지가 존재하면 (재시작 시 앞부분 스킵)
        full_path = os.path.join(BASE_DIR, job["filepath"])
        if os.path.exists(full_path):
            print(f"⏭️ {job['filepath']} 이미 존재. 패스합니다.")
            continue
            
        print(f"\n[{i}/{len(ASSET_JOBS)}]")
        if generate_image(job["prompt"], job["filepath"], job["remove_bg"]):
            success += 1
            print("⏳ 1분 대기 중 (Vertex AI Quota 보호)...")
            time.sleep(60)
        else:
            print("⏳ 에러 발생.. 60초 대기 후 다음 항목으로 넘어갑니다.")
            time.sleep(60)
        
    print("\n==================================================")
    print(f"🎉 대량 생성 및 배경 투명화 완료! ({success}/{len(ASSET_JOBS)})")

if __name__ == "__main__":
    main()
