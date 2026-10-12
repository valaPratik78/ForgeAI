# ForgeAI One-Click Launcher

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "         🚀 Launching ForgeAI Suite                " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# 1. Resolve Java Runtime
$javaCandidates = @(
    "C:\Users\PRATIK VALA\.vscode\extensions\redhat.java-1.56.0-win32-x64\jre\21.0.12.1-win32-x86_64",
    $env:JAVA_HOME
)

$selectedJavaHome = $null
foreach ($path in $javaCandidates) {
    if ($path -and (Test-Path "$path\bin\java.exe")) {
        $selectedJavaHome = $path
        break
    }
}

if ($selectedJavaHome) {
    Write-Host "[✓] Found Java 21 at: $selectedJavaHome" -ForegroundColor Green
    $env:JAVA_HOME = $selectedJavaHome
    $env:Path = "$selectedJavaHome\bin;$env:Path"
} else {
    Write-Host "[!] Using system default Java" -ForegroundColor Yellow
}

# 2. Check Backend Path
$backendDir = "C:\Users\PRATIK VALA\Desktop\forgeai\forgeai-backend-main\forgeai-backend-main\backend"
if (-not (Test-Path $backendDir)) {
    Write-Host "[!] Backend directory not found at $backendDir" -ForegroundColor Red
} else {
    # Check if backend is already responding on 8080
    $backendRunning = $false
    try {
        $res = Invoke-WebRequest -Uri "http://localhost:8080/" -UseBasicParsing -TimeoutSec 2
        if ($res.StatusCode -eq 200) { $backendRunning = $true }
    } catch {}

    if ($backendRunning) {
        Write-Host "[✓] Spring Boot Backend is already running on http://localhost:8080" -ForegroundColor Green
    } else {
        Write-Host "[*] Starting Spring Boot Backend on http://localhost:8080..." -ForegroundColor Yellow
        $backendProcess = Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendDir'; `$env:JAVA_HOME='$selectedJavaHome'; `$env:Path='$selectedJavaHome\bin;`$env:Path'; .\mvnw.cmd spring-boot:run" -PassThru
        Start-Sleep -Seconds 4
    }
}

# 3. Start Frontend
$frontendDir = Join-Path $PSScriptRoot "ForgeAI"
Write-Host "[*] Starting Frontend Web Server on http://localhost:3000..." -ForegroundColor Cyan
Start-Process "http://localhost:3000"

Set-Location $frontendDir
node server.js
