"""
deploy_patch.py — Defense 웹 빌드 후처리 스크립트
======================================================
flutter build web --release 후 실행.

패치 내용:
  1. base href → "./" (상대경로, CrazyGames 호환)
  2. AssetManifest.bin.json / .bin / FontManifest.json 인라인 임베딩
  3. flutter_bootstrap.js 서비스워커 제거
  4. canvaskit 로컬 폴더 제거 (CDN 사용)
  5. .js.symbols 디버그 파일 제거

사용법:
  python tool/deploy_patch.py
"""

import os, re, json, base64, shutil

BUILD_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "build", "web")
INDEX_HTML = os.path.join(BUILD_DIR, "index.html")
BOOTSTRAP_JS = os.path.join(BUILD_DIR, "flutter_bootstrap.js")
ASSET_MANIFEST_JSON = os.path.join(BUILD_DIR, "assets", "AssetManifest.bin.json")
ASSET_MANIFEST_BIN  = os.path.join(BUILD_DIR, "assets", "AssetManifest.bin")
FONT_MANIFEST_JSON  = os.path.join(BUILD_DIR, "assets", "FontManifest.json")


def patch_base_href(html: str) -> str:
    """<base href="..."> → <base href="./"> """
    patched = re.sub(r'<base\s+href="[^"]*"', '<base href="./"', html)
    if '<base href="./"' in patched:
        print("  [OK] base href -> ./")
    else:
        print("  [!!] base href patch failed -- check manually")
    return patched


def build_inline_script() -> str:
    """AssetManifest / FontManifest 인라인 fetch 인터셉트 스크립트 생성"""
    with open(ASSET_MANIFEST_JSON, "r", encoding="utf-8") as f:
        manifest_json_content = f.read()

    with open(ASSET_MANIFEST_BIN, "rb") as f:
        manifest_bin_b64 = base64.b64encode(f.read()).decode("ascii")

    with open(FONT_MANIFEST_JSON, "r", encoding="utf-8") as f:
        font_manifest_content = f.read()

    manifest_json_safe = manifest_json_content.replace("</", "<\\/")
    font_manifest_safe = font_manifest_content.replace("</", "<\\/")

    script = f"""<script>
(function() {{
  var _mJson = {manifest_json_safe};
  var _mBinB64 = "{manifest_bin_b64}";
  var _fJson = {font_manifest_safe};
  function b64ToBytes(b64) {{
    var bin = atob(b64), len = bin.length, arr = new Uint8Array(len);
    for (var i = 0; i < len; i++) arr[i] = bin.charCodeAt(i);
    return arr.buffer;
  }}
  var _origFetch = window.fetch;
  window.fetch = function(url, opts) {{
    var u = typeof url === "string" ? url : (url && url.url ? url.url : "");
    if (u.indexOf("AssetManifest.bin.json") !== -1) {{
      return Promise.resolve(new Response(JSON.stringify(_mJson), {{status:200, headers:{{'Content-Type':'application/json'}}}}));
    }}
    if (u.indexOf("AssetManifest.bin") !== -1 && u.indexOf(".json") === -1) {{
      return Promise.resolve(new Response(b64ToBytes(_mBinB64), {{status:200, headers:{{'Content-Type':'application/octet-stream'}}}}));
    }}
    if (u.indexOf("FontManifest.json") !== -1) {{
      return Promise.resolve(new Response(JSON.stringify(_fJson), {{status:200, headers:{{'Content-Type':'application/json'}}}}));
    }}
    return _origFetch.call(this, url, opts);
  }};
}})();
</script>"""
    return script


def patch_index_html():
    with open(INDEX_HTML, "r", encoding="utf-8") as f:
        html = f.read()

    html = patch_base_href(html)

    # 기존 인라인 스크립트 제거 (재실행 시 중복 방지)
    html = re.sub(
        r'<!-- MANIFEST_INLINE_START -->.*?<!-- MANIFEST_INLINE_END -->',
        '', html, flags=re.DOTALL
    )

    # 새 인라인 스크립트 삽입 (<body> 바로 뒤)
    inline_script = build_inline_script()
    marked = f'<!-- MANIFEST_INLINE_START -->\n{inline_script}\n<!-- MANIFEST_INLINE_END -->'
    html = html.replace('<body>', f'<body>\n{marked}', 1)

    with open(INDEX_HTML, "w", encoding="utf-8") as f:
        f.write(html)
    print("  [OK] AssetManifest / FontManifest inline embedded")


def remove_canvaskit_local():
    """canvaskit 폴더 전체 제거 — CDN에서 자동 로드 (~32MB 절감)"""
    canvaskit_dir = os.path.join(BUILD_DIR, "canvaskit")
    if os.path.exists(canvaskit_dir):
        size = sum(
            os.path.getsize(os.path.join(r, f))
            for r, _, files in os.walk(canvaskit_dir) for f in files
        )
        shutil.rmtree(canvaskit_dir)
        print(f"  [OK] canvaskit/ removed (CDN 사용, {size/1024/1024:.1f} MB saved)")
    else:
        print("  [OK] canvaskit/: already removed")


def remove_symbols():
    """디버그용 .js.symbols 파일 제거"""
    removed = 0
    for root, _, files in os.walk(BUILD_DIR):
        for f in files:
            if f.endswith('.js.symbols'):
                os.remove(os.path.join(root, f))
                removed += 1
    print(f"  [OK] {removed} .js.symbols files removed")


def patch_service_worker():
    with open(BOOTSTRAP_JS, "r", encoding="utf-8") as f:
        js = f.read()

    patched = re.sub(
        r'_flutter\.loader\.load\(\s*\{[\s\S]*?serviceWorkerVersion[\s\S]*?\}\s*\}\s*\)',
        '_flutter.loader.load({})', js
    )
    if patched == js and '_flutter.loader.load({})' in js:
        print("  [OK] service worker: already removed")
    elif patched != js:
        with open(BOOTSTRAP_JS, "w", encoding="utf-8") as f:
            f.write(patched)
        print("  [OK] service worker removed")
    else:
        print("  [!!] service worker pattern not found -- check manually")


if __name__ == "__main__":
    import sys
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

    print("\n[*] Defense web build post-processing...")
    print(f"    target: {BUILD_DIR}\n")

    if not os.path.exists(INDEX_HTML):
        print("[!] build/web/index.html not found -- run flutter build web --release first")
        exit(1)

    patch_index_html()
    patch_service_worker()
    remove_canvaskit_local()
    remove_symbols()

    total = sum(
        os.path.getsize(os.path.join(r, f))
        for r, _, files in os.walk(BUILD_DIR) for f in files
    )
    print(f"\n  Build size: {total/1024/1024:.1f} MB")
    if total > 250 * 1024 * 1024:
        print("  [!!] WARNING: exceeds CrazyGames 250MB limit!")

    print("\n[OK] Post-processing complete!")
    print("   -> CrazyGames:  upload build/web folder to Developer Portal\n")
