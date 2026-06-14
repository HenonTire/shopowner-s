# ⚡ START HERE - DO THESE 5 STEPS NOW

**Goal:** Get Flutter app working from physical device on your network  
**Time:** 15 minutes  
**Status:** All code fixes applied, ready for your actions

---

## STEP 1: Open Windows Firewall (2 minutes)

### Option A: Script (Easiest)
```powershell
# Right-click PowerShell → "Run as Administrator"
cd apps\shop_manager
.\setup_firewall.bat
```

### Option B: Manual Command
```powershell
# Right-click PowerShell → "Run as Administrator"
netsh advfirewall firewall add rule name="Django Backend 8000" dir=in action=allow protocol=tcp localport=8000netsh advfirewall firewall add rule name="Django Backend 8000" dir=in action=allow protocol=tcp localport=8000
```

**Verify it worked:**
```powershell
netsh advfirewall firewall show rule name="Django Backend 8000"
```

---

## STEP 2: Restart Backend (3 minutes)

```bash
cd Backend\core
docker compose down
docker compose up -d
sleep 15
```

**Verify all services are healthy:**
```bash
docker compose ps
```

Expected output:
```
NAME                 STATUS              PORTS
shikela_db          Up (healthy)        5432/tcp
shikela_redis       Up (healthy)        
shikela_web         Up (healthy)        0.0.0.0:8000->8000/tcp
shikela_celery      Up (healthy)        
shikela_celery_beat Up (healthy)        
```

---

## STEP 3: Test Backend (2 minutes)

### Test from your computer (localhost):
```bash
curl http://localhost:8000/health/
```
**Expected:** `{"status":"ok"}` ✅

### Test from your computer (LAN IP):
```bash
curl http://192.168.1.123:8000/health/
```
**Expected:** `{"status":"ok"}` ✅

If either fails → Firewall or backend not running properly

---

## STEP 4: Test from Physical Device (1 minute)

**On your phone/tablet (same WiFi as computer):**

1. Open web browser
2. Type in address bar: `http://192.168.1.123:8000/health/`
3. Press Enter
4. Should see: `{"status":"ok"}`

If this works ✅ → Go to Step 5  
If this fails ❌ → Device not on same network or firewall still blocking

---

## STEP 5: Run Flutter App (5 minutes)

```bash
cd apps\shop_manager

# Clear cache
flutter clean

# Get packages
flutter pub get

# Run app with correct backend URL
flutter run --dart-define=API_BASE_URL=http://192.168.1.123:8000
```

**Watch the output:**
- You should see debug logs showing the backend URL
- App should start and show login screen
- Login with your credentials
- Dashboard should appear

**Debug output you should see:**
```
═══════════════════════════════════════════════════════
🔵 FLUTTER LOGIN ATTEMPT
═══════════════════════════════════════════════════════
📍 Backend URL: http://192.168.1.123:8000
✅ Response received from backend
✅ Login successful!
═══════════════════════════════════════════════════════
```

---

## ❌ WHAT IF STEP X FAILS?

### Step 1 Failed: Can't run firewall script
- Make sure PowerShell is running as Administrator
- Try running `setup_firewall.bat` directly (double-click)

### Step 2 Failed: Docker services not healthy
```bash
docker compose logs web  # See what went wrong
docker compose down
docker compose up -d
```

### Step 3 Failed: `curl http://192.168.1.123:8000/health/` doesn't return {"status":"ok"}
```bash
# Check if firewall rule was added
netsh advfirewall firewall show rule name="Django Backend 8000"

# Check if port is listening
netstat -ano | findstr :8000

# Check backend logs
docker compose logs web | tail -30
```

### Step 4 Failed: Device browser can't reach the backend
```bash
# 1. Verify device is on same network
ping 192.168.1.123  # From your computer

# 2. Try this from computer (if it works, firewall might block device)
curl http://192.168.1.123:8000/health/

# 3. Check if IP is correct (might be 192.168.x.x not 192.168.1.123)
ipconfig | findstr "IPv4 Address"
```

### Step 5 Failed: Flutter app shows "Couldn't reach backend"
```bash
# Check Flutter logs
flutter logs | grep -i "backend\|error\|connection"

# Check the URL is correct in debug output
# Should show: Backend URL: http://192.168.1.123:8000

# Try different backends:
# For emulator:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# For localhost:
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

---

## 📍 YOUR NETWORK IP

Your computer's IP is: **192.168.1.123**

If this is wrong, find the correct one:
```powershell
ipconfig | findstr "IPv4 Address"
```

Then replace `192.168.1.123` with your actual IP everywhere:
- Firewall script
- curl commands
- Flutter run command
- Device browser address

---

## ✅ SUCCESS = You See This

1. **Terminal shows:**
   ```
   ✓ All Docker services healthy
   ✓ curl returns {"status":"ok"}
   ```

2. **Device browser shows:**
   ```
   {"status":"ok"}
   ```

3. **Flutter shows:**
   ```
   Login screen appears
   After login: Dashboard appears
   No error messages
   ```

---

## 📚 REFERENCE DOCS (If you need details)

- **QUICK_FIX.md** - Detailed fix guide with troubleshooting
- **BACKEND_FLUTTER_FIX_COMPLETE.md** - Complete summary of all changes
- **LAN_CONNECTIVITY_FIX.md** - 11-phase diagnostic guide
- **setup_firewall.bat** - Firewall automation script
- **setup_backend.sh** - Backend setup automation script

---

## 🎯 TL;DR (The Absolute Minimum)

```powershell
# 1. Firewall (as Administrator)
netsh advfirewall firewall add rule name="Django Backend 8000" dir=in action=allow protocol=tcp localport=8000

# 2. Restart backend
cd Backend\core && docker compose down && docker compose up -d && sleep 15

# 3. Test
curl http://192.168.1.123:8000/health/

# 4. Run Flutter
cd ..\..\apps\shop_manager && flutter run --dart-define=API_BASE_URL=http://192.168.1.123:8000
```

---

**You're 5 steps away from a working mobile app! 🚀**  
**Start with STEP 1 above.**
