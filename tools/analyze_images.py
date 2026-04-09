from PIL import Image
import os, sys

categories = {}
base = "assets/images"
for root, dirs, files in os.walk(base):
    for f in files:
        if not f.endswith(".png"):
            continue
        path = os.path.join(root, f)
        cat = root.replace(base + "/", "").replace(base + "\\", "").split("/")[0].split("\\")[0]
        try:
            img = Image.open(path)
            has_alpha = img.mode in ("RGBA", "LA", "PA")
            uses_alpha = False
            if has_alpha:
                alpha = img.getchannel("A")
                extrema = alpha.getextrema()
                uses_alpha = extrema[0] < 255
            size_kb = os.path.getsize(path) / 1024
            if cat not in categories:
                categories[cat] = {"total": 0, "transparent": 0, "opaque": 0, "size_mb": 0, "files": []}
            categories[cat]["total"] += 1
            categories[cat]["size_mb"] += size_kb / 1024
            if uses_alpha:
                categories[cat]["transparent"] += 1
            else:
                categories[cat]["opaque"] += 1
            categories[cat]["files"].append((f, uses_alpha, size_kb, img.size))
        except Exception as e:
            print(f"Error: {path}: {e}", file=sys.stderr)

print("=" * 60)
print(f"{'카테고리':<15} {'총':<5} {'투명':<5} {'불투명':<5} {'크기 MB':<10}")
print("=" * 60)

total_t = 0
total_o = 0
for cat in sorted(categories.keys()):
    c = categories[cat]
    total_t += c["transparent"]
    total_o += c["opaque"]
    print(f"{cat:<15} {c['total']:<5} {c['transparent']:<5} {c['opaque']:<5} {c['size_mb']:<10.1f}")
    for f, alpha, size, dims in sorted(c["files"], key=lambda x: -x[2])[:3]:
        tag = "ALPHA" if alpha else "SOLID"
        print(f"  {size:7.0f} KB  {dims[0]}x{dims[1]}  [{tag}] {f}")

print("=" * 60)
print(f"{'합계':<15} {total_t + total_o:<5} {total_t:<5} {total_o:<5}")
print(f"\nJPG 변환 가능(불투명): {total_o}개")
print(f"PNG 유지 필요(투명): {total_t}개")
