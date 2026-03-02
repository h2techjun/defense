"""
🦉 해원의 문 — 에셋 생성 파이프라인 v7 (최종)

원칙:
  ① AI: 크로마키 초록(#00FF00) 배경 위에 그림
  ② Python: 초록 배경만 flood fill 투명화 (리사이즈 없음)
  ③ Flutter: 단일 이미지 + 코드 애니메이션

사용법:
  python tools/bulk_imagen_v2.py              → 누락된 에셋만 생성
  python tools/bulk_imagen_v2.py --only bg    → bg 폴더만 생성
  python tools/bulk_imagen_v2.py --only heroes → heroes 폴더만 생성
"""
import os, sys, base64, time, argparse
import requests as http_requests
from io import BytesIO
from PIL import Image
import numpy as np
from collections import deque
from google.oauth2 import service_account
from google.auth.transport.requests import Request

# ━━ 설정 ━━
KEY_PATH   = r"e:\defense\autotrade-engine-key.json"
PROJECT_ID = "autotrade-engine"
LOCATION   = "us-central1"
MODEL_ID   = "imagen-3.0-generate-001"
BASE_DIR   = r"e:\defense\assets\images"
WAIT_SEC   = 15
MAX_RETRY  = 3

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 크로마키 초록 배경 → 투명화 (외곽 flood fill)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def make_transparent(img):
    """투명화 v9: rembg AI 기반 배경 제거 (캐릭터용)"""
    from rembg import remove
    img = img.convert("RGBA")
    result = remove(img)
    return result

def make_transparent_fx(img):
    """투명화 v9-FX: 검정 배경 제거 (이펙트 전용)
    이펙트는 발광체이므로 어두운 부분 = 배경. rembg 사용 안 함."""
    img = img.convert("RGBA")
    d = np.array(img)
    r, g, b = d[:,:,0].astype(int), d[:,:,1].astype(int), d[:,:,2].astype(int)
    brightness = (r + g + b) / 3
    # 어두운 픽셀(밝기 < 40) = 검정 배경 → 투명
    dark = brightness < 40
    d[:,:,3][dark] = 0
    # 약간 어두운 경계(40~80) → 반투명 (부드러운 전환)
    semi = (brightness >= 40) & (brightness < 80)
    alpha_ratio = (brightness[semi] - 40) / 40  # 0~1
    d[:,:,3][semi] = (alpha_ratio * 255).astype(np.uint8)
    return Image.fromarray(d)

# ━━ API ━━
def get_token():
    c = service_account.Credentials.from_service_account_file(
        KEY_PATH, scopes=["https://www.googleapis.com/auth/cloud-platform"])
    c.refresh(Request())
    return c.token

def gen_image(prompt, aspect):
    url = (f"https://{LOCATION}-aiplatform.googleapis.com/v1/projects/"
           f"{PROJECT_ID}/locations/{LOCATION}/publishers/google/"
           f"models/{MODEL_ID}:predict")
    payload = {
        "instances": [{"prompt": prompt}],
        "parameters": {"sampleCount": 1, "aspectRatio": aspect,
                       "outputOptions": {"mimeType": "image/png"}}
    }
    for attempt in range(MAX_RETRY):
        try:
            r = http_requests.post(url,
                headers={"Authorization": f"Bearer {get_token()}",
                         "Content-Type": "application/json"},
                json=payload, timeout=120)
            if r.status_code == 200:
                preds = r.json().get("predictions", [])
                if preds and preds[0].get("bytesBase64Encoded"):
                    return Image.open(BytesIO(base64.b64decode(preds[0]["bytesBase64Encoded"])))
                print("  ❌ 결과 없음"); return None
            elif r.status_code == 429:
                wait = WAIT_SEC * (attempt + 2)
                print(f"  ⚠️ 429 ({attempt+1}/{MAX_RETRY}), {wait}초 대기...")
                time.sleep(wait)
            else:
                print(f"  ❌ {r.status_code}: {r.text[:120]}")
                return None
        except Exception as e:
            print(f"  🚨 {e}")
            if attempt < MAX_RETRY - 1: time.sleep(10)
    return None

# ━━ 스타일 ━━
HERO  = "Adorable chibi 2D game character, big sparkling eyes, cel-shaded, thick clean outlines, vibrant colors, glossy highlights, no shadow, MapleStory/Cookie Run Kingdom style"
TOWER = "Cute miniature chibi 2D tower, bold outlines, vibrant colors, no shadow, Cookie Run Kingdom style"
ENEMY = "Cute adorable chibi 2D monster, big round eyes, thick outlines, colorful vibrant candy-like colors, not scary, no shadow"
BG    = "Premium quality mobile game background art, highly detailed digital painting, vibrant rich colors, soft volumetric lighting, AFK Arena / Cookie Run Kingdom quality, polished professional"
FX    = "Abstract stylized 2D game VFX effect, clean vector shapes, vibrant glowing neon, soft bloom, premium. ONLY the effect itself, absolutely NO character, NO person, NO creature, NO animal, NO figure. Pure abstract energy/particle effect"
UI    = "Polished glossy 2D game UI icon, candy-like colors, thick outline, cute rounded"
PORT  = "Stunning anime RPG portrait, beautiful big eyes, glossy highlights, Blue Archive quality"

BG_GREEN = "On clean solid white background, NO shadow, NO drop shadow, NO ground, character floating in pure white space"
BG_BLACK = "On solid pure black (#000000) background, pitch black void, nothing else"
BG_NONE  = ""  # 배경 에셋은 투명화 안 함

# 캐릭터 기본 형태 (스킨 간 공유)
HERO_BASE = {
    "kkaebi":  "a red-skinned Dokkaebi goblin boy, stubby horns, big round eyes, stocky build, holding oversized wooden bangmangi club",
    "guMiho":  "a nine-tailed fox spirit girl, fluffy fox ears, slender cute build, wearing traditional hanbok",
    "gangrim": "a Korean grim reaper (Jeoseung Chasa), tall slim build, wearing dopo robe and gat hat, pale face, holding chain",
    "sua":     "a Korean water ghost girl (Mul-Gwishin), flowing wet black hair, pale porcelain skin, wearing hanbok, floating water droplets",
    "bari":    "a Korean shaman princess (Bari Gongju), small cute build, wearing ceremonial robes with ribbons, holding painted fan and golden bell",
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 에셋 목록 생성 함수들
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
def build_bg_jobs():
    return [
        {"p":"bg/bg_main_menu.png","a":"16:9","t":False,"q":f"{BG}. A beautiful bright Korean fantasy village scene. At the bottom center, a cute chibi warrior boy with a wooden club and a cute mystic girl with a fan stand together, small enough not to block the upper area. Behind them: colorful hanok houses with warm orange lanterns, cherry blossom trees in full bloom, soft pink petals drifting, gentle golden sunset sky with fluffy clouds. The top half is clean sky (for menu UI). Warm, cheerful, inviting mobile game title screen."},
        {"p":"bg/bg_stage_1.png","a":"16:9","t":False,"q":f"{BG}. Top-down view bright colorful tower defense map: a cheerful Korean traditional marketplace with cute food stalls, colorful fabric awnings, cute round lanterns, cobblestone path winding through. Warm golden afternoon sunlight, cherry blossom petals, bright and inviting atmosphere. Mobile game map."},
        {"p":"bg/bg_stage_2.png","a":"16:9","t":False,"q":f"{BG}. Top-down view colorful tower defense map: a magical Korean forest with bright autumn-colored trees (orange, yellow, red), cute stone lanterns along the path, sparkling fireflies, gentle morning fog with golden sunbeams. Enchanted but cheerful and warm atmosphere, not scary. Mobile game map."},
    ]

def build_hero_jobs():
    jobs = []
    skins = {
        "kkaebi": [
            ("tier1", "basic red skin, simple tiger-skin vest, plain wooden club"),
            ("tier2", "jade-green tinted skin, polished jade horns, silver-buckled tiger armor, jade-colored club"),
            ("tier3", "deep red skin with orange flame tattoos, burning horn tips, golden flame armor, weapon engulfed in fire, fire aura"),
            ("tier4", "brilliant golden skin, magnificent golden horns with divine light, ornate gold armor with amber gems, golden energy weapon, radiant golden halo"),
        ],
        "guMiho": [
            ("tier1", "pink color theme, single fluffy tail, white-pink hanbok, amber eyes, mischievous smile"),
            ("tier2", "lavender-purple theme, three purple-glowing tails, light purple hanbok with moonlight patterns, soft purple aura"),
            ("tier3", "crimson-gold theme, six burning dark-red tails, deep red hanbok with gold edges, fierce blood-red eyes"),
            ("tier4", "divine white-lavender theme, nine magnificent luminous tails, flowing celestial white robes, divine halo, floating sparkle particles"),
        ],
        "gangrim": [
            ("tier1", "all-black theme, simple black dopo robe, black gat hat, dark eyes, iron chain"),
            ("tier2", "silver-grey theme, silvery dopo with crescent moon embroidery, gunmetal gat, silver chain"),
            ("tier3", "crimson-black theme, blood-stained dopo, glowing crimson eyes, red energy chain"),
            ("tier4", "navy-gold divine theme, magnificent navy dopo with golden seal embroidery, ornate golden gat, golden halo, floating golden particles"),
        ],
        "sua": [
            ("tier1", "blue theme, wet black hair, translucent white-blue hanbok, cyan glowing eyes, water droplets"),
            ("tier2", "coral-orange theme, hair with coral highlights, orange-tinted hanbok, warm orange eyes"),
            ("tier3", "icy teal-cyan theme, crystallized frozen hair, ice-blue hanbok with frost patterns, floating ice crystals"),
            ("tier4", "deep ocean navy and neon cyan theme, hair flowing like ocean waves, navy hanbok with bioluminescent patterns, massive water vortex aura"),
        ],
        "bari": [
            ("tier1", "golden-yellow theme, colorful robes with yellow accents, rainbow ribbons, flower crown, warm smile"),
            ("tier2", "cherry blossom pink theme, sakura-petal patterned robes, cherry blossom crown, falling petals"),
            ("tier3", "warm orange dawn theme, sunrise-patterned robes, amber gemstone accessories, warm radiant glow"),
            ("tier4", "pure white and gold divine theme, magnificent white robes with golden divine symbols, golden halo, floating prayer beads, holy light particles"),
        ],
    }
    for hid, skin_list in skins.items():
        base = HERO_BASE[hid]
        for tier_name, skin_desc in skin_list:
            jobs.append({
                "p": f"heroes/{hid}_{tier_name}_sprites.png", "a": "1:1", "t": True,
                "q": f"{HERO}. A single cute chibi {base}, {skin_desc}. Standing idle pose, facing slightly right, centered in frame. {BG_GREEN}."
            })
    return jobs

def build_effect_jobs():
    jobs = []
    # 영웅별 공격 이펙트 — 캐릭터 없이 이펙트만!
    atk = {"kkaebi":"green energy smash impact shockwave, rock debris and dust, wooden club impact crack",
           "guMiho":"pink-magenta glowing fox claw slash marks with sparkle trails, three parallel slash arcs",
           "gangrim":"dark crimson scythe slash arc with ghostly soul wisps trailing behind",
           "sua":"cyan water whip lash with splashing water droplets and water rings",
           "bari":"golden crescent fan slash wave with holy light particles and golden sparkles"}
    for hid, desc in atk.items():
        jobs.append({"p":f"effects/fx_attack_{hid}.png","a":"1:1","t":True,"fx":True,
            "q":f"{FX}. {desc}. Isolated glowing effect. {BG_BLACK}."})
    
    # 영웅별 스킬 이펙트 — 캐릭터 없이 이펙트만!
    skill = {"kkaebi":"massive green swirling energy shockwave ring expanding outward, ground crack explosion",
             "guMiho":"swirling vortex of blue and pink fox-fire orbs, mesmerizing enchantment magic circle",
             "gangrim":"dark crimson soul chain eruption from ground with ghostly purple scythe slash arc",
             "sua":"massive cyan water pillar geyser eruption with concentric water splash rings",
             "bari":"golden radiant summoning magic circle with holy prayer symbols, divine light beam"}
    for hid, desc in skill.items():
        jobs.append({"p":f"effects/fx_skill_{hid}.png","a":"1:1","t":True,"fx":True,
            "q":f"{FX}. {desc}. Isolated glowing radial energy wave. {BG_BLACK}."})
    
    # 범용 이펙트 프레임 (순차 애니메이션)
    for i,d in enumerate(["tiny fire spark igniting, single small flame",
                          "growing swirling fireball with orange sparks",
                          "massive fire explosion burst with ember particles",
                          "dissipating fire embers and fading smoke wisps"],1):
        jobs.append({"p":f"effects/fx_fire_{i}.png","a":"1:1","t":True,"fx":True,
            "q":f"{FX}. {d}, warm orange-yellow flame. Isolated glowing effect. {BG_BLACK}."})
    for i,d in enumerate(["tiny lightning static spark, small electric dot",
                          "branching lightning bolts spreading outward",
                          "massive lightning strike explosion with electric arcs",
                          "fading dissipating electric sparks and afterglow"],1):
        jobs.append({"p":f"effects/fx_lightning_{i}.png","a":"1:1","t":True,"fx":True,
            "q":f"{FX}. {d}, cyan-purple electric. Isolated glowing effect. {BG_BLACK}."})
    for i,d in enumerate(["tiny impact spark, small white flash",
                          "glowing slash impact with light streaks",
                          "massive hit explosion burst with debris",
                          "fading impact afterglow dissipating"],1):
        jobs.append({"p":f"effects/fx_hit_{i}.png","a":"1:1","t":True,"fx":True,
            "q":f"{FX}. {d}, white-yellow impact. Isolated glowing effect. {BG_BLACK}."})
    return jobs

def build_enemy_jobs():
    jobs = []
    ch1 = [("hungryGhost","a hopping Korean zombie (Gangshi), tattered hanbok, arms stretched forward, bouncing"),
           ("strawShoeSpirit","a possessed straw sandal spirit, tiny angry eyes, bouncing around"),
           ("burdenedLaborer","a burdened ghost laborer carrying cursed glowing sack on back, blue ghost flames"),
           ("maidenGhost","a Korean maiden ghost, long flowing white funeral hanbok, very long black hair, eerie blue glow"),
           ("eggGhost","a faceless egg ghost, smooth oval featureless head, dark tattered robes, floating"),
           ("bossOgreLord","LARGE imposing red Dokkaebi King boss, golden spiked kanabo club, crown, blazing fire aura, fierce")]
    ch2 = [("tigerSlave","a possessed tiger spirit, glowing red stripe markings, blue flame paws, fierce"),
           ("fireDog","a fiery hellhound Bulgae, entire body made of flames, orange-red eyes"),
           ("shadowGolem","a shadow mud golem, dark body with purple crack lines, stubby heavy arms"),
           ("oldFoxWoman","an elderly nine-tailed fox hag, tattered scholar robe, green ghostly skull hovering"),
           ("failedDragon","a corrupted Imugi serpent, dark scales, stubby unfinished horn, purple venom fangs"),
           ("bossMountainLord","LARGE imposing divine white mountain tiger boss, golden pattern markings, divine roar, majestic")]
    ch3 = [("changGwiEvolved","an evolved spectral ghost tiger, translucent cyan body, ghostly stripes"),
           ("saetani","a cursed porcelain doll spirit (Saetani), cracked white face, single glowing red eye"),
           ("shadowChild","a shadow wraith child, pure dark silhouette, two white dot eyes, floating"),
           ("maliciousBird","an evil three-eyed crow spirit, dark purple-black feathers, three glowing red eyes"),
           ("faceStealerGhost","a ghost wearing multiple stolen masks on body, dark flowing robes"),
           ("bossGreatEggGhost","HUGE mutated giant egg ghost boss, dark vein cracks all over, pulsing purple core, terrifying")]
    ch4 = [("courtAssassin","a palace shadow assassin, black stealth outfit, dual daggers, shadow wisps"),
           ("corruptOfficial","a corrupt court official ghost, red official robes, bribe pouch, dark aura"),
           ("royalGuardGhost","a royal guard ghost, golden armor, spectral spear, purple ghostly afterimage"),
           ("curseScribe","a curse writer ghost, ink-dripping brush, cursed scrolls floating around"),
           ("puppetDancer","a marionette puppet dancer, strings attached from above, jerky unnatural pose"),
           ("bossTyrantKing","LARGE imposing undead skeletal tyrant king boss, dark golden armor, cursed throne floating, dual swords")]
    ch5 = [("underworldMessenger","an underworld messenger ghost, black dopo, netherworld scroll, spectral"),
           ("wailingBanshee","a wailing banshee ghost, screaming mouth wide open, sonic blue waves"),
           ("boneGolem","a massive bone golem, body made of skulls and bones, glowing red eyes"),
           ("soulChainGhost","a soul chain ghost, bound in purple spectral chains, tormented expression"),
           ("infernoSpirit","an inferno spirit, body of hellfire, dark crimson and black flames"),
           ("bossGatekeeper","HUGE imposing gatekeeper demon boss, four muscular arms, red-black armor, swirling portal vortex behind")]
    
    for ch_enemies in [ch1, ch2, ch3, ch4, ch5]:
        for eid, desc in ch_enemies:
            size = "Large imposing" if "boss" in eid.lower() else "Small cute"
            jobs.append({"p":f"enemies/{eid}.png","a":"1:1","t":True,
                "q":f"{ENEMY}. {size} {desc}. Dynamic pose, facing left. {BG_GREEN}."})
    return jobs

def build_tower_jobs():
    jobs = []
    towers = [("archer","Korean archer watchtower with Giwa tiled roof, bow slots"),
              ("barracks","Korean military outpost with fabric banners, weapon racks"),
              ("shaman","Korean shaman shrine with floating paper talismans, spiritual mist"),
              ("artillery","Korean Singijeon cannon installation, wooden frame, brass barrel"),
              ("sotdae","Korean wooden Sotdae pole, carved bird on top, holy glow")]
    tiers = ["basic wooden, simple, small","reinforced stone and metal, glowing runes, medium","ultimate golden ornate, crystalline magical energy, large magnificent"]
    for tid, tdesc in towers:
        for t, tt in enumerate(tiers, 1):
            jobs.append({"p":f"towers/tower_{tid}_{t}.png","a":"1:1","t":True,
                "q":f"{TOWER}. {tdesc}, {tt}. 3/4 isometric angle. {BG_GREEN}."})
    
    branches = [("rocketBattery","Hwacha rocket launcher tower, rows of rockets, fiery smoke"),
                ("spiritHunter","elite sniper watchtower, scope crossbow, cyan spirit bullet"),
                ("generalTotem","stone guardian Jangseung totem with spear, earth shockwave base"),
                ("goblinRing","Dokkaebi stone sumo wrestling ring, green spirit energy orbs"),
                ("shamanTemple","grand shaman temple, golden talisman statues, holy light beams"),
                ("grimReaperOffice","dark underworld portal office, purple vortex, wraith spirits"),
                ("fireDragon","dragon head fire cannon, red-gold dragon sculpture, fire breath"),
                ("heavenlyThunder","Bigyeokjincheonloe thunder bomb tower, lightning rod, electric arcs"),
                ("phoenixTotem","phoenix nest guardian totem, golden egg, fire feather rain effect"),
                ("earthSpiritAltar","jade earth spirit altar, moss covered boulders, green rune glow")]
    for bid, bdesc in branches:
        jobs.append({"p":f"towers/tower_{bid}.png","a":"1:1","t":True,
            "q":f"{TOWER}. Ultimate tier 4 branch: {bdesc}. Magnificent glowing. 3/4 angle. {BG_GREEN}."})
    return jobs

def build_misc_jobs():
    jobs = []
    jobs += [
        {"p":"objects/obj_sacred_tree.png","a":"1:1","t":True,"q":f"{TOWER}. Korean sacred Dangsan tree, gnarled ancient trunk, cherry blossoms, colored prayer ribbons, golden glow. {BG_GREEN}."},
        {"p":"objects/obj_shrine.png","a":"1:1","t":True,"q":f"{TOWER}. Korean stone cairn shrine (Seonghwangdang), stacked prayer stones, small wooden gate, blue-purple spiritual aura. {BG_GREEN}."},
        {"p":"soldiers/soldier_normal.png","a":"1:1","t":True,"q":f"{HERO}. A Korean militia soldier (Uibyeong), blue hanbok, wooden spear, straw hat, brave face. {BG_GREEN}."},
        {"p":"soldiers/soldier_grappler.png","a":"1:1","t":True,"q":f"{HERO}. A heavy Korean Ssireum wrestler, big muscular body, padded vest, bandaged fists, headband. {BG_GREEN}."},
    ]
    for pid, pdesc in {
        "bari":"shaman princess Bari, warm brown eyes, colorful ceremonial robes, magnolia flower crown",
        "gangnim":"grim reaper Gangrim, sharp crimson eyes, pale face, black dopo robe, black gat hat",
        "kkaebi":"red Dokkaebi goblin, golden sparkly eyes, stubby horns, fang grin, tiger-skin vest",
        "miho":"nine-tailed fox girl, amber-gold eyes, silver-white hair, fluffy fox ears, pink hanbok",
        "sua":"water ghost Sua, cyan-glowing eyes, long wet black hair, pale porcelain face, white hanbok",
    }.items():
        jobs.append({"p":f"portraits/portrait_{pid}.png","a":"1:1","t":True,
            "q":f"{PORT}. Close-up bust portrait of {pdesc}. Beautiful detailed anime eyes, glossy hair highlights. {BG_GREEN}."})
    
    jobs += [
        {"p":"ui/icon_coin.png","a":"1:1","t":True,"q":f"{UI}. Golden Korean brass coin (Yeopjeon), square hole center, embossed characters, golden glow. {BG_GREEN}."},
        {"p":"ui/icon_gem.png","a":"1:1","t":True,"q":f"{UI}. Jade gemstone (Gogok), comma-shaped, emerald green, inner mystical glow. {BG_GREEN}."},
        {"p":"ui/icon_sinmyeong.png","a":"1:1","t":True,"q":f"{UI}. Divine spirit energy symbol (Sinmyeong), swirling blue-gold sacred flame. {BG_GREEN}."},
        {"p":"ui/shop_starter_pack.png","a":"1:1","t":True,"q":f"{UI}. Starter treasure chest overflowing with gold coins, jade gems, magical scroll, wooden chest with golden clasps. {BG_GREEN}."},
        {"p":"ui/shop_gems_pack.png","a":"1:1","t":True,"q":f"{UI}. Golden ornate bowl overflowing with jade gemstones of various sizes, emerald glow. {BG_GREEN}."},
    ]
    return jobs

# ━━ 실행 ━━
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--only", type=str, default=None,
                       help="특정 카테고리만 생성: bg/heroes/effects/enemies/towers/misc")
    args = parser.parse_args()
    
    all_jobs = {
        "bg": build_bg_jobs(),
        "heroes": build_hero_jobs(),
        "effects": build_effect_jobs(),
        "enemies": build_enemy_jobs(),
        "towers": build_tower_jobs(),
        "misc": build_misc_jobs(),
    }
    
    if args.only:
        if args.only not in all_jobs:
            print(f"❌ 잘못된 카테고리: {args.only}")
            print(f"  사용 가능: {', '.join(all_jobs.keys())}")
            return
        jobs = all_jobs[args.only]
        print(f"📂 [{args.only}] 카테고리만 생성합니다")
    else:
        jobs = []
        for category_jobs in all_jobs.values():
            jobs.extend(category_jobs)
    
    total = len(jobs)
    print("=" * 60)
    print(f"  🦉 해원의 문 — 에셋 팩토리 v7 (크로마키 초록)")
    print(f"  총: {total}개 | 대기: {WAIT_SEC}초 | 재시도: {MAX_RETRY}회")
    print(f"  배경: 크로마키 초록(#00FF00) | 투명화: 외곽 flood fill")
    print("=" * 60)
    
    ok = skip = fail = 0
    for i, j in enumerate(jobs, 1):
        fp = os.path.join(BASE_DIR, j["p"])
        if os.path.exists(fp):
            print(f"⏭️ [{i}/{total}] {j['p']} — 스킵")
            skip += 1
            continue
        
        os.makedirs(os.path.dirname(fp), exist_ok=True)
        print(f"\n[{i}/{total}] 🎨 {j['p']}")
        
        img = gen_image(j["q"], j["a"])
        if not img:
            print("  ❌ 실패")
            fail += 1
            time.sleep(WAIT_SEC)
            continue
        
        if j["t"]:
            if j.get("fx"):
                print("  ✂️ 검정 배경 → 투명 (FX)...")
                img = make_transparent_fx(img)
            else:
                print("  ✂️ 배경 → 투명 (rembg)...")
                img = make_transparent(img)
        
        img.save(fp, "PNG")
        print(f"  ✅ {fp}")
        ok += 1
        print(f"  ⏳ {WAIT_SEC}초...")
        time.sleep(WAIT_SEC)
    
    print(f"\n{'='*60}")
    print(f"🎉 성공: {ok} | 스킵: {skip} | 실패: {fail} | 전체: {total}")

if __name__ == "__main__":
    main()
