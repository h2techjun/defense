"""
Phase 1: 어제(02/24) 생성된 에셋 삭제
Phase 2: 코드가 참조하는 전체 에셋 목록 확인 → 누락분 재생성
Phase 3: 추가 배경/UI 에셋 생성
"""
import os
import sys
import base64
import requests
import time
from io import BytesIO
from PIL import Image
from rembg import remove
from google.oauth2 import service_account
from google.auth.transport.requests import Request

KEY_PATH = r"d:\00_Project\05_Defense\autotrade-engine-key.json"
PROJECT_ID = "autotrade-engine"
LOCATION = "us-central1"
MODEL_ID = "imagen-3.0-generate-001"
BASE_DIR = r"d:\00_Project\05_Defense\assets\images"

# ==============================
# Phase 1: 어제 파일 삭제
# ==============================
cutoff = time.mktime(time.strptime("2026-02-25 00:00:00", "%Y-%m-%d %H:%M:%S"))
deleted = 0
for root, dirs, files in os.walk(BASE_DIR):
    for f in files:
        if not f.endswith(".png"):
            continue
        full = os.path.join(root, f)
        mt = os.path.getmtime(full)
        if mt < cutoff:
            os.remove(full)
            deleted += 1
            print(f"🗑️ 삭제: {os.path.relpath(full, BASE_DIR)}")

print(f"\n✅ Phase 1 완료: {deleted}개 어제 파일 삭제됨\n")

# ==============================
# Phase 2 + 3: 필요한 전체 에셋 목록
# ==============================
ASSET_JOBS = []

# ── 배경 (메인 + 스테이지 + 추가 배경) ──
backgrounds = [
    ("bg/bg_main_menu.png", "A beautiful, premium 2D mobile game main menu background illustration. Dark fantasy Korean traditional theme, stylized, rich colors, atmospheric, mystical moonlight, foggy distant mountains, glowing shrine, high quality digital art."),
    ("bg/bg_stage_1.png", "A top-down view of a Korean traditional village at night, 2D game background, dark fantasy, subtle moonlight, stylized environment, tower defense map background, dirt paths and grass."),
    ("bg/bg_stage_2.png", "A top-down view of a dark spooky Korean bamboo forest at night, 2D game background, dark fantasy, foggy glowing, tower defense map background, dirt paths."),
    ("bg/bg_stage_3.png", "A top-down view of a haunted mountain pass with abandoned temples, dark fantasy Korean theme, eerie green glow, 2D game background, tower defense map background."),
    ("bg/bg_stage_4.png", "A top-down view of a fiery volcanic wasteland with destroyed Korean fortress ruins, dark red and orange tones, 2D game background, tower defense map."),
    ("bg/bg_stage_5.png", "A top-down view of a dark underworld gate with purple spirit flames and ancient stone pillars, Korean mythology Jeoseung, 2D game background, tower defense map."),
    ("bg/bg_hero_manage.png", "A premium 2D mobile game background for hero management screen. Dark elegant Korean palace interior with golden pillars and mystical blue glow. High quality."),
    ("bg/bg_tower_manage.png", "A premium 2D mobile game background for tower management screen. Workshop interior with weapons and blueprints, warm orange lantern glow, Korean style. High quality."),
    ("bg/bg_shop.png", "A premium 2D mobile game shop background. Mysterious merchant tent interior with potions, scrolls, and glowing artifacts, rich purple and gold tones, Korean fantasy."),
    ("bg/bg_stage_select.png", "A premium 2D mobile game world map background. Ancient Korean map with ink-wash mountains, glowing stage markers, compass rose, aged parchment texture. High quality."),
]
for fp, prompt in backgrounds:
    ASSET_JOBS.append({"filepath": fp, "prompt": prompt, "remove_bg": False})

# ── 오브젝트 (6종) ──
objects = [
    ("objects/obj_sacred_tree.png", "A majestic Korean sacred tree (Dangsan Namu) with colorful ribbons tied to its branches, mystical glow, 2D game asset, premium mobile game style, chibi/stylized, isolated on white background."),
    ("objects/obj_shrine.png", "A small traditional Korean ancestor shrine (Seonangdang) made of stones and wood, mystical blue glow, 2D game asset, premium mobile game style. Isolated on white background."),
    ("objects/obj_torch.png", "A traditional Korean stone torch pillar with mystical orange flames, 2D game asset, chibi style, premium mobile game. Isolated on white background."),
    ("objects/obj_old_well.png", "An old Korean stone well with eerie green glow coming from within, moss-covered, 2D game asset, chibi style, premium mobile game. Isolated on white background."),
    ("objects/obj_sotdae.png", "A traditional Korean wooden pole with carved bird totem on top (Sotdae), holy golden glow, 2D game asset, chibi style, premium mobile game. Isolated on white background."),
    ("objects/obj_grave_mound.png", "An ancient Korean burial mound (Bongbun) with ghostly purple spirit aura, overgrown with grass, 2D game asset, chibi style, premium mobile game. Isolated on white background."),
]
for fp, prompt in objects:
    ASSET_JOBS.append({"filepath": fp, "prompt": prompt, "remove_bg": True})

# ── 영웅 (5캐릭 x 3티어 = 15장) ──
heroes = [
    ("kkaebi", "small Korean Dokkaebi (Goblin) holding a tiny wooden club"),
    ("hongGildong", "Korean righteous outlaw hero Hong Gil-dong with a staff and blue traditional robes"),
    ("guMiho", "beautiful Korean nine-tailed fox spirit (Gumiho) in white and pink robes with mystical tails"),
    ("tigerHunter", "Korean traditional tiger hunter (Chakhogapsa) with a matchlock rifle and tiger pelt"),
    ("darkYeomra", "dark king of the underworld (Yeomra) with a judge hat and dark aura"),
]
tier_desc = ["basic form", "upgraded form with more details and glowing aura", "fully evolved form, majestic, ultimate power, massive glow"]
for hero_id, desc in heroes:
    for tier in [1, 2, 3]:
        ASSET_JOBS.append({
            "filepath": f"heroes/hero_{hero_id}_{tier}.png",
            "prompt": f"A 2D game asset of {desc}, {tier_desc[tier-1]}, chibi style, premium mobile tower defense game character. Isolated on white background.",
            "remove_bg": True
        })

# ── 타워 기본 (5타입 x 3티어 = 15장) ──
towers = [
    ("archer", "wooden archer tower, traditional Korean architecture style (Giwa roof)"),
    ("barracks", "traditional Korean military outpost tent, weapon racks outside"),
    ("shaman", "mystical Korean shaman (Mudang) shrine, floating talismans, spiritual aura"),
    ("artillery", "traditional Korean cannon (Singijeon) installation, wooden and brass details"),
    ("sotdae", "Korean traditional wooden pole with a carved bird on top (Sotdae), glowing holy light, magical ward tower"),
]
tower_tier_desc = ["basic wooden structure", "fortified structure with stone and metal elements", "ultimate legendary glowing structure, massive details"]
for tower_id, desc in towers:
    for tier in [1, 2, 3]:
        ASSET_JOBS.append({
            "filepath": f"towers/tower_{tower_id}_{tier}.png",
            "prompt": f"A 2D game asset of {desc}, {tower_tier_desc[tier-1]}, chibi style, dynamic angle, premium mobile tower defense game. Isolated on white background.",
            "remove_bg": True
        })

# ── 타워 분기점 (10종) ──
branches = [
    ("rocket_battery", "hwacha multiple rocket launcher battery burning with fire"),
    ("spirit_hunter", "elite tiger hunter watchtower with heavy rifles and spotlights"),
    ("general_totem", "massive stone guardian general statue (Jangseung) with a spear"),
    ("goblin_ring", "Dokkaebi magical stone ring portal glowing green"),
    ("shaman_temple", "grand majestic shaman blessing temple with massive golden statues"),
    ("grim_reaper", "dark grim reaper (Jeoseung Saja) spooky underworld portal pavilion"),
    ("fire_dragon", "massive mythical fire dragon cannon shaped like a dragon head breathing flames"),
    ("heavenly_thunder", "divine heavenly thunder drum (Bugo) on a cloud pagoda calling lightning"),
    ("phoenix_totem", "legendary ancient Korean phoenix (Bonghwang) nest glowing with holy light"),
    ("earth_spirit", "giant earth spirit golem altar made of glowing jade and mossy boulders"),
]
for bid, desc in branches:
    ASSET_JOBS.append({
        "filepath": f"towers/tower_{bid}.png",
        "prompt": f"A 2D game asset of {desc}, ultimate top tier tower, massive details, chibi style, dynamic angle, premium mobile tower defense game. Isolated on white background.",
        "remove_bg": True
    })

# ── 적군 일반 (15종) ──
enemies = {
    "enemy_hungry_ghost": "small Korean zombie (Gangshi) jumping with outstretched arms",
    "enemy_straw_shoe": "animated possessed straw shoe monster (Jipsin) running",
    "enemy_burdened": "undead burdened laborer ghost carrying a heavy cursed sack",
    "enemy_maiden": "creepy floating Korean maiden ghost (Gwisin) in white funeral dress",
    "enemy_egg_ghost": "faceless egg ghost (Dalgyal Gwisin) floating in dark rags",
    "enemy_tiger_slave": "possessed tiger-slave ghost crawling on all fours",
    "enemy_fire_dog": "fiery hellhound dog spirit (Bulgae) with flames on body",
    "enemy_shadow_golem": "big scary shadow mud golem made of dark earth",
    "enemy_old_fox": "evil old fox spirit woman holding a skull lantern",
    "enemy_failed_dragon": "corrupted Imugi (failed dragon serpent) with dark scales",
    "enemy_evolved_tiger": "huge spectral demon tiger (Chang-gwi) with blue flames",
    "enemy_saetani": "creepy cursed child doll spirit floating",
    "enemy_shadow_child": "dark shadowy floating shadow wraith child",
    "enemy_malicious_bird": "corrupted evil crow spirit with red glowing eyes",
    "enemy_face_stealer": "creepy ghost wearing multiple stolen face masks",
}
for ename, desc in enemies.items():
    ASSET_JOBS.append({
        "filepath": f"enemies/{ename}.png",
        "prompt": f"A cute but scary 2D game asset of {desc}, creepy chibi style, dynamic pose, premium mobile tower defense game enemy. Isolated on white background.",
        "remove_bg": True
    })

# ── 보스 (5종) ──
bosses = {
    "boss_ogre_lord": "massive terrifying red Ogre Lord (Dokkaebi King) wielding a huge iron club",
    "boss_mountain_lord": "giant legendary mountain deity tiger boss with golden armor",
    "boss_great_egg": "gigantic mutated blob egg ghost boss with many tentacles",
    "boss_tyrant_king": "undead skeletal tyrant king sitting on a dark throne with a crown",
    "boss_gatekeeper": "imposing underworld portal gatekeeper demon boss with chains",
}
for bname, desc in bosses.items():
    ASSET_JOBS.append({
        "filepath": f"enemies/{bname}.png",
        "prompt": f"A massive intimidating but slightly cute 2D game asset of {desc}, creepy chibi style, premium mobile tower defense boss. Isolated on white background.",
        "remove_bg": True
    })

# ── 이펙트 프레임 (14장) ──
fire_prompts = [
    "Frame 1 of 5: tiny glowing magical fire spark, stylized 2D game particle. On solid black.",
    "Frame 2 of 5: growing magical fire, stylized 2D game particle. On solid black.",
    "Frame 3 of 5: massive vibrant fire explosion burst, stylized 2D game particle. On solid black.",
    "Frame 4 of 5: dissipating magical fire, stylized 2D game particle. On solid black.",
    "Frame 5 of 5: fading glowing embers, stylized 2D game particle. On solid black.",
]
for i, p in enumerate(fire_prompts, 1):
    ASSET_JOBS.append({"filepath": f"effects/fx_fire_{i}.png", "prompt": p, "remove_bg": True})

lightning_prompts = [
    "Frame 1 of 5: tiny lightning static, cyan purple, stylized 2D game particle. On solid black.",
    "Frame 2 of 5: branching lightning, cyan purple, stylized 2D game particle. On solid black.",
    "Frame 3 of 5: massive lightning strike explosion, cyan purple, stylized 2D game particle. On solid black.",
    "Frame 4 of 5: dissipating lightning, cyan purple, stylized 2D game particle. On solid black.",
    "Frame 5 of 5: fading static sparks, cyan purple, stylized 2D game particle. On solid black.",
]
for i, p in enumerate(lightning_prompts, 1):
    ASSET_JOBS.append({"filepath": f"effects/fx_lightning_{i}.png", "prompt": p, "remove_bg": True})

hit_prompts = [
    "Frame 1 of 4: tiny sharp physical hit impact spark, white yellow, stylized 2D game particle. On solid black.",
    "Frame 2 of 4: sharp glowing hit impact, white yellow, stylized 2D game particle. On solid black.",
    "Frame 3 of 4: massive slash hit impact explosion, white yellow, stylized 2D game particle. On solid black.",
    "Frame 4 of 4: fading hit impact, white yellow, stylized 2D game particle. On solid black.",
]
for i, p in enumerate(hit_prompts, 1):
    ASSET_JOBS.append({"filepath": f"effects/fx_hit_{i}.png", "prompt": p, "remove_bg": True})

# ── UI 아이콘 에셋 ──
ui_assets = [
    ("ui/icon_sinmyeong.png", "A glowing golden spiral energy icon, Korean shamanistic style, premium 2D mobile game UI icon. On white background.", True),
    ("ui/icon_coin.png", "A shiny golden coin with Korean traditional pattern, premium 2D mobile game UI currency icon. On white background.", True),
    ("ui/icon_gem.png", "A glowing purple crystal gemstone, premium 2D mobile game UI premium currency icon. On white background.", True),
]
for fp, prompt, rb in ui_assets:
    ASSET_JOBS.append({"filepath": fp, "prompt": prompt, "remove_bg": rb})

print(f"📋 총 {len(ASSET_JOBS)}개 에셋 생성 대기열")

# ==============================
# 생성 함수
# ==============================
def get_access_token():
    try:
        credentials = service_account.Credentials.from_service_account_file(
            KEY_PATH, scopes=["https://www.googleapis.com/auth/cloud-platform"]
        )
        request = Request()
        credentials.refresh(request)
        return credentials.token
    except Exception as e:
        print(f"토큰 오류: {e}")
        return None

def generate_image(prompt, output_filepath, remove_bg):
    full_path = os.path.join(BASE_DIR, output_filepath)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)

    print(f"🎨 생성 중: {output_filepath}")
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
                print(f"  결과 없음")
                return False
            b64_img = predictions[0].get("bytesBase64Encoded")
            if b64_img:
                img_data = base64.b64decode(b64_img)
                if remove_bg:
                    print(f"  ✂️ 배경 투명화...")
                    input_img = Image.open(BytesIO(img_data))
                    output_img = remove(input_img)
                    output_img.save(full_path, "PNG")
                else:
                    with open(full_path, "wb") as f:
                        f.write(img_data)
                print(f"  ✅ 저장: {full_path}")
                return True
        else:
            print(f"  ❌ API 오류 ({response.status_code})")
    except Exception as e:
        print(f"  🚨 예외: {e}")
    return False

# ==============================
# 메인 루프
# ==============================
print("\n" + "=" * 50)
print("🦉 해원의 문 — 전체 그래픽 리빌드 팩토리 가동!")
print("=" * 50)

success = 0
skipped = 0
for i, job in enumerate(ASSET_JOBS, 1):
    full_path = os.path.join(BASE_DIR, job["filepath"])
    if os.path.exists(full_path):
        print(f"⏭️ [{i}/{len(ASSET_JOBS)}] {job['filepath']} 이미 존재")
        skipped += 1
        continue

    print(f"\n[{i}/{len(ASSET_JOBS)}]")
    if generate_image(job["prompt"], job["filepath"], job["remove_bg"]):
        success += 1
    print("⏳ 60초 대기...")
    time.sleep(60)

print("\n" + "=" * 50)
print(f"🎉 완료! 성공: {success}, 스킵: {skipped}, 총: {len(ASSET_JOBS)}")
