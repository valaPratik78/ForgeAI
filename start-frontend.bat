@echo off
title ForgeAI - Web Frontend (Port 3000)
echo ====================================================
echo   Starting ForgeAI Web Frontend Server (Port 3000)
echo ====================================================

cd /d "%~dp0ForgeAI"
node server.js
pause
