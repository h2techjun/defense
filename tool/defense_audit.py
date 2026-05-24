"""🔍 Defense (Gateway of Regrets) 시스템 통합 audit

사용:
  python tool/defense_audit.py             # human readable
  python tool/defense_audit.py --json      # JSON
"""
from __future__ import annotations

import argparse
import io
import json
import re
import sys
from dataclasses import dataclass, field, asdict
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent
ANDROID = ROOT / "android"


@dataclass
class Check:
    category: str
    name: str
    ok: bool
    detail: str = ""
    severity: str = "error"


@dataclass
class Report:
    checks: list = field(default_factory=list)
    total: int = 0
    passed: int = 0
    failed: int = 0

    def add(self, c: Check) -> None:
        self.checks.append(c)
        self.total += 1
        if c.ok:
            self.passed += 1
        else:
            self.failed += 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    r = Report()

    # A. 메타
    r.add(Check("A.메타", "CLAUDE.md", (ROOT / "CLAUDE.md").exists()))
    r.add(Check("A.메타", "HANDOFF.md", (ROOT / "HANDOFF.md").exists(), severity="warn"))
    r.add(Check("A.메타", "pubspec.yaml", (ROOT / "pubspec.yaml").exists()))

    # B. .env (시크릿 관리)
    env = ROOT / ".env"
    r.add(Check("B.환경", ".env 파일 존재", env.exists(),
        "pubspec assets 에 등록 시 빌드 번들 — .gitignore 확인 필요",
        severity="warn"
    ))
    gitignore = ROOT / ".gitignore"
    if gitignore.exists() and env.exists():
        src = gitignore.read_text(encoding="utf-8", errors="ignore")
        r.add(Check("B.환경", ".env 가 .gitignore 에 포함",
            ".env" in src,
            "안 되면 시크릿 git 커밋 위험"
        ))

    # C. INTERNET 퍼미션
    manifest = ANDROID / "app" / "src" / "main" / "AndroidManifest.xml"
    if manifest.exists():
        src = manifest.read_text(encoding="utf-8", errors="ignore")
        r.add(Check("C.안드로이드", "INTERNET 퍼미션",
            "android.permission.INTERNET" in src,
            "Supabase + 모든 네트워크 호출 필수"
        ))

    # D. shrinkResources (Flutter 에셋 보호)
    gradle = ANDROID / "app" / "build.gradle.kts"
    if gradle.exists():
        src = gradle.read_text(encoding="utf-8", errors="ignore")
        has_true = re.search(r"isShrinkResources\s*=\s*true", src) is not None
        r.add(Check("D.안드로이드", "isShrinkResources != true (이미지 251MB 보호)",
            not has_true,
            "true 면 흰 화면/오디오/이미지 누락"
        ))

    # E. Flame 게임 / state 격리
    game_dir = ROOT / "lib" / "game"
    state_dir = ROOT / "lib" / "state"
    r.add(Check("E.아키텍처", "lib/game 디렉토리 존재", game_dir.exists()))
    r.add(Check("E.아키텍처", "lib/state 디렉토리 존재 (Riverpod 단일 통신 채널)", state_dir.exists()))

    # F. CrazyGames 배포 스크립트
    deploy_patch = ROOT / "tool" / "deploy_patch.py"
    build_web_ps = ROOT / "tool" / "build_web.ps1"
    r.add(Check("F.배포", "tool/deploy_patch.py", deploy_patch.exists(),
        "Web 빌드 후 필수 (안 돌리면 검은 화면)"
    ))
    r.add(Check("F.배포", "tool/build_web.ps1", build_web_ps.exists(),
        "환경변수 주입 빌드 스크립트"
    ))

    # G. 빌드 사이즈 경고 (assets 250MB+)
    assets = ROOT / "assets"
    if assets.exists():
        total_mb = sum(f.stat().st_size for f in assets.rglob("*") if f.is_file()) / 1024 / 1024
        r.add(Check("G.빌드", f"assets/ 사이즈 ({total_mb:.0f} MB)",
            True,  # info only
            f"Workmate 직접 호스팅 불가 (외부 GH Pages 필수)",
            severity="info"
        ))

    # H. pubspec 버전
    pubspec = ROOT / "pubspec.yaml"
    if pubspec.exists():
        src = pubspec.read_text(encoding="utf-8", errors="ignore")
        m = re.search(r"^version:\s*(\d+\.\d+\.\d+)\+(\d+)", src, re.MULTILINE)
        if m:
            r.add(Check("H.버전", "version: X.Y.Z+N",
                True, f"{m.group(1)}+{m.group(2)}", severity="info"
            ))

    # 출력
    if args.json:
        print(json.dumps({
            "total": r.total, "passed": r.passed, "failed": r.failed,
            "checks": [asdict(c) for c in r.checks],
        }, ensure_ascii=False, indent=2))
    else:
        print(f"\n{'='*60}")
        print(f"Defense 시스템 audit -- {r.passed}/{r.total} 통과")
        print(f"{'='*60}\n")
        by_cat = {}
        for c in r.checks:
            by_cat.setdefault(c.category, []).append(c)
        for cat in sorted(by_cat):
            print(f"[{cat}]")
            for c in by_cat[cat]:
                icon = "OK " if c.ok else ("WRN" if c.severity == "warn" else "ERR")
                print(f"  {icon}  {c.name}")
                if c.detail:
                    print(f"        {c.detail}")
            print()

    error_failures = sum(1 for c in r.checks if not c.ok and c.severity == "error")
    return 1 if error_failures else 0


if __name__ == "__main__":
    sys.exit(main())
