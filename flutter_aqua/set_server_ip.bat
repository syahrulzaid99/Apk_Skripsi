@echo off
setlocal enabledelayedexpansion

echo ========================================
echo   Auto-Detect Server IP Configuration
echo ========================================
echo.

REM Mendapatkan IP address dari adapter WiFi aktif
set IP=
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set IPADDR=%%a
    REM Hapus spasi di awal dan akhir
    for /f "tokens=*" %%b in ("!IPADDR!") do set IP=%%b
)

if "%IP%"=="" (
    echo ERROR: Tidak dapat mendeteksi IP address
    echo Pastikan Anda terhubung ke WiFi
    pause
    exit /b 1
)

echo IP Address terdeteksi: %IP%
echo.

REM Path ke file api_config.dart
set CONFIG_FILE=lib\config\api_config.dart

REM Backup file asli
copy "%CONFIG_FILE%" "%CONFIG_FILE%.backup" >nul 2>&1

REM Update file config dengan IP baru menggunakan PowerShell
powershell -Command "(Get-Content '%CONFIG_FILE%') -replace 'http://[^:]+:3000', 'http://%IP%:3000' | Set-Content '%CONFIG_FILE%'"

echo.
echo ========================================
echo   Konfigurasi berhasil diupdate!
echo ========================================
echo.
echo Server URL: http://%IP%:3000
echo.
echo File yang diupdate: %CONFIG_FILE%
echo Backup disimpan di: %CONFIG_FILE%.backup
echo.
echo Sekarang Anda bisa menjalankan Flutter app
echo.
pause
