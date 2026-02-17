@echo off
echo ===================================================
echo Haewon's Door (Gateway of Regrets) - Defense Game
echo ===================================================
echo.
echo Setting up Flutter environment...
set PATH=%PATH%;C:\flutter\bin

echo.
echo Checking Flutter installation...
call flutter --version
if %ERRORLEVEL% NEQ 0 (
    echo Flutter SDK not found or not in PATH.
    echo Please ensure C:\flutter exists.
    pause
    exit /b
)

echo.
echo Getting project dependencies...
call flutter pub get

echo.
echo Starting game in Chrome...
call flutter run -d chrome

pause
