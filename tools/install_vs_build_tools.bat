@echo off
echo =======================================================
echo    해원의 문 - Visual Studio C++ 빌드 도구 자동 설치기
echo =======================================================
echo.
echo Flutter Windows 데스크톱 앱 빌드를 위한 패키지를 다운로드하고 설치합니다.
echo 이 작업은 관리자 권한이 필요하며, PC 사양에 따라 5~10분이 소요될 수 있습니다.
echo 팝업이 뜨면 '예(Yes)'를 눌러주세요.
echo.
pause

echo.
echo [1/2] Visual Studio 설치 프로그램 다운로드 중...
curl -L -o "%TEMP%\vs_buildtools.exe" "https://aka.ms/vs/17/release/vs_BuildTools.exe"

echo.
echo [2/2] C++ 데스크톱 개발 환경 자동 설치 중... (백그라운드)
echo 설치가 완료될 때까지 이 창을 닫지 마세요!
"%TEMP%\vs_buildtools.exe" --quiet --wait --norestart --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended

echo.
echo =======================================================
echo ✅ 설치가 완료되었습니다! 이제 창을 닫으셔도 됩니다.
echo (경우에 따라 PC를 한 번 재부팅해야 적용될 수 있습니다.)
echo =======================================================
pause
