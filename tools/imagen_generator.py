import os
import sys
import json
import base64
import requests
import time
from google.oauth2 import service_account
from google.auth.transport.requests import Request

# ── 설정값 ──
KEY_PATH = r"d:\00_Project\05_Defense\autotrade-engine-key.json"
PROJECT_ID = "autotrade-engine"
LOCATION = "us-central1"
MODEL_ID = "imagen-3.0-generate-001"

OUTPUT_DIR = r"d:\00_Project\05_Defense\assets\images"

def get_access_token():
    try:
        credentials = service_account.Credentials.from_service_account_file(
            KEY_PATH, scopes=["https://www.googleapis.com/auth/cloud-platform"]
        )
        request = Request()
        credentials.refresh(request)
        return credentials.token
    except Exception as e:
        print(f"❌ 토큰 발급 오류 (JSON 키 확인 필요): {e}")
        return None

def generate_image(prompt, output_filename):
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        
    print(f"🎨 이미지 생성 요청 중: {output_filename} ...")
    print(f"프롬프트: {prompt}")
    
    token = get_access_token()
    if not token:
        return False

    url = f"https://{LOCATION}-aiplatform.googleapis.com/v1/projects/{PROJECT_ID}/locations/{LOCATION}/publishers/google/models/{MODEL_ID}:predict"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "instances": [
            {
                "prompt": prompt
            }
        ],
        "parameters": {
            "sampleCount": 1,
            "aspectRatio": "1:1",
            "outputOptions": {
                "mimeType": "image/png"
            }
        }
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload)
        
        if response.status_code == 200:
            data = response.json()
            if "predictions" in data and len(data["predictions"]) > 0:
                b64_img = data["predictions"][0].get("bytesBase64Encoded")
                if b64_img:
                    img_data = base64.b64decode(b64_img)
                    
                    filepath = os.path.join(OUTPUT_DIR, output_filename)
                    with open(filepath, "wb") as f:
                        f.write(img_data)
                    print(f"✅ 에셋 저장 완료: {filepath}")
                    return True
                else:
                    print(f"❌ Base64 파싱 오류: {data}")
            else:
                print(f"❌ 예측 결과 없음: {data}")
        else:
            print(f"❌ API 오류 ({response.status_code}): {response.text}")
            
    except Exception as e:
        print(f"🚨 네트워크 예외 발생: {e}")

    return False

def main():
    print("==================================================")
    print("   🦉 해원의 문 - Vertex AI Imagen 팩토리 가동    ")
    print("==================================================")
    
    prompt = "A very cute, polished 2D game asset of a Korean traditional Dokkaebi (Goblin) holding a small wooden club. Chibi style, clean flat vector-like coloring, smooth shading, suitable for a premium mobile tower defense game. The Dokkaebi has little horns, a cheeky smile, and wears traditional Korean pants (Baji). Isolated on a solid transparent or clean white background, high resolution, soft dynamic lighting."
    output_name = "hero_kkaebi_premium.png"
    
    generate_image(prompt, output_name)
    print("==================================================")

if __name__ == "__main__":
    main()
