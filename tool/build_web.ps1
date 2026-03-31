# Web 빌드 스크립트 — Supabase 키 자동 주입
# 사용법: powershell -File tool/build_web.ps1

$env_file = ".env"
$supabaseUrl = ""
$supabaseAnonKey = ""

if (Test-Path $env_file) {
    Get-Content $env_file | ForEach-Object {
        if ($_ -match "^SUPABASE_URL=(.+)$") { $supabaseUrl = $Matches[1].Trim() }
        if ($_ -match "^SUPABASE_ANON_KEY=(.+)$") { $supabaseAnonKey = $Matches[1].Trim() }
    }
}

if ([string]::IsNullOrEmpty($supabaseUrl) -or [string]::IsNullOrEmpty($supabaseAnonKey)) {
    Write-Host "WARNING: Supabase keys not found in .env — cloud save disabled" -ForegroundColor Yellow
    flutter build web --release
} else {
    Write-Host "Building with Supabase: $supabaseUrl" -ForegroundColor Green
    flutter build web --release `
        --dart-define="SUPABASE_URL=$supabaseUrl" `
        --dart-define="SUPABASE_ANON_KEY=$supabaseAnonKey"
}

# 프로덕션 불필요 파일 정리 (CrazyGames 50MB 제한 대응)
Get-ChildItem build/web -Recurse -Filter "*.js.symbols" | Remove-Item -Force
Write-Host "Cleaned .js.symbols files" -ForegroundColor Gray

$size = (Get-ChildItem build/web -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "`nBuild size: $([math]::Round($size, 1)) MB" -ForegroundColor Cyan

if ($size -gt 50) {
    Write-Host "WARNING: Over 50MB CrazyGames limit!" -ForegroundColor Red
} else {
    Write-Host "CrazyGames ready!" -ForegroundColor Green
}
