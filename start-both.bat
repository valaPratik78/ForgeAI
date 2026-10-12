@echo off
title ForgeAI Launcher
echo ====================================================
echo   Launching ForgeAI Frontend and Backend
echo ====================================================

echo [*] Starting Backend in new window...
start "ForgeAI Backend (8080)" cmd /k "%~dp0start-backend.bat"

timeout /t 5 /nobreak > nul

echo [*] Starting Frontend in new window...
start "ForgeAI Frontend (3000)" cmd /k "%~dp0start-frontend.bat"

timeout /t 2 /nobreak > nul

echo [*] Opening ForgeAI in your default browser...
start http://localhost:3000

echo [✓] Both services launched successfully!
