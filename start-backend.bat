@echo off
title ForgeAI - Spring Boot Backend (Port 8080)
echo ====================================================
echo   Starting ForgeAI Spring Boot Backend (Port 8080)
echo ====================================================

set JAVA_HOME=C:\Users\PRATIK VALA\.vscode\extensions\redhat.java-1.56.0-win32-x64\jre\21.0.12.1-win32-x86_64
set PATH=%JAVA_HOME%\bin;%PATH%
set OPENROUTER_API_KEY=dummy-key

if exist "%~dp0backend" (
    cd /d "%~dp0backend"
) else if exist "%~dp0ForgeAI\backend" (
    cd /d "%~dp0ForgeAI\backend"
) else (
    cd /d "C:\Users\PRATIK VALA\Desktop\forgeai\forgeai-backend-main\forgeai-backend-main\backend"
)

call mvnw.cmd spring-boot:run
pause
