@echo off
REM Windows Firewall Configuration for Django Backend Port 8000
REM Run this as Administrator to allow port 8000 through the firewall

REM Check if running as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ERROR: This script must be run as Administrator!
    echo.
    echo Steps to run as Administrator:
    echo 1. Press Windows + R
    echo 2. Type: cmd
    echo 3. Press Ctrl+Shift+Enter (instead of just Enter)
    echo 4. Run this script again
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Django Backend Firewall Configuration
echo ========================================
echo.

REM Remove old rule if it exists
echo Removing old firewall rule (if exists)...
netsh advfirewall firewall delete rule name="Django Backend 8000" >nul 2>&1

REM Add inbound rule
echo Adding inbound firewall rule for port 8000...
netsh advfirewall firewall add rule name="Django Backend 8000" dir=in action=allow protocol=tcp localport=8000 profile=any description="Allow Django backend API access from network devices"

REM Verify rule was created
echo.
echo Verifying rule was created...
netsh advfirewall firewall show rule name="Django Backend 8000"

echo.
echo ========================================
echo Checking if port 8000 is listening...
echo ========================================
echo.
netstat -ano | findstr :8000

if %errorlevel% neq 0 (
    echo.
    echo WARNING: Port 8000 is not currently listening.
    echo Make sure Docker backend is running: docker compose up -d
    echo.
) else (
    echo.
    echo SUCCESS: Port 8000 is listening!
    echo.
)

echo.
echo ========================================
echo ✅ Firewall configuration complete!
echo ========================================
echo.
echo Next steps:
echo 1. Make sure Django backend is running: docker compose up -d
echo 2. Test from host: curl http://192.168.1.123:8000/health/
echo 3. Test from device on same network: http://192.168.1.123:8000/health/
echo 4. Run Flutter with: flutter run --dart-define=API_BASE_URL=http://192.168.1.123:8000
echo.
pause
