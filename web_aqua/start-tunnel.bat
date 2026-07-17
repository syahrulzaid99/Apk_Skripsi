@echo off
REM ============================================================
REM  Start Backend + LocalTunnel (URL stabil, akses lintas jaringan)
REM  Cara pakai:
REM    1. Jalankan: start-tunnel.bat
REM    2. Tunggu sampai muncul URL https://xxxx.loca.lt
REM    3. Di HP, buka Settings > tempel URL itu ke "Server URL" > Simpan
REM    4. (Opsional) Buka https://xxxx.loca.lt di browser, password = nama PC
REM  Catatan: localtunnel gratis, URL berubah tiap restart script.
REM ============================================================
echo [1/2] Menyalakan backend (web_aqua)...
start "web_aqua-backend" cmd /k "npm run dev"

timeout /t 3 >nul

echo [2/2] Membuka tunnel localtunnel di port 3000...
echo URL akan muncul di bawah (format: https://xxxx.loca.lt)
echo Password tunnel = nama PC ini (cek: hostname)
echo.
npx localtunnel --port 3000
