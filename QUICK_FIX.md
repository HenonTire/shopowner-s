# IMMEDIATE FIX STEPS - Django + Flutter LAN Connectivity

**Status:** Ready to implement  
**Time Required:** 15-20 minutes  
**Prerequisites:** Docker running, physical device on same WiFi

---

## ⚡ QUICK FIX (Do This First)

### Windows Users (PowerShell as Administrator):

```powershell
# 1. Open firewall for port 8000
netsh advfirewall firewall add rule name="Django Backend 8000" dir=in action=allow protocol=tcp localport=8000

# 2. Verify firewall rule
netsh advfirewall firewall show rule name="Django Backend 8000"

# 3. Go to backend directory
cd Backend/core

# 4. Restart backend with updated ALLOWED_HOSTS
docker compose down
docker compose up -d

# 5. Wait 10 seconds
Start-Sleep -Seconds 10

# 6. Test health endpoint
curl http://localhost:8000/health/

# 7. Test on LAN IP
curl http://192.168.1.123:8000/health/
```

### Linux/Mac Users:

```bash
# 1. Go to backend directory
cd Backend/core

# 2. Restart backend
docker compose down
docker compose up -d

# 3. Wait for services
sleep 15

# 4. Test health endpoint
curl http://localhost:8000/health/

# 5. Test on host IP (replace with your IP)
curl http://YOUR_HOST_IP:8000/health/

# 6. For Linux firewall
sudo ufw allow 8000/tcp
```

---

## 📋 FILES ALREADY FIXED

✅ **Backend/core/.env.docker**
- Updated ALLOWED_HOSTS with all network IPs
- Added ALLOW_ALL_HOSTS_IN_DEBUG=true

✅ **Backend/core/core/settings.py**
- Fixed ALLOWED_HOSTS parsing logic
- CORS middleware properly positioned (first)

✅ **apps/shop_manager/lib/services/api_config.dart**
- Updated to use Environment helper
- Now respects API_BASE_URL environment variable

✅ **apps/shop_manager/lib/services/auth_service.dart**
- Added comprehensive debug logging
- Shows exactly what URL is being called
- Shows response status and errors

✅ **apps/shop_manager/lib/config/environment.dart**
- Multi-environment configuration
- Device-specific URLs (emulator vs physical device)

---

## 🧪 TESTING CHECKLIST

### Step 1: Backend Health (Host Machine)

```bash
# Test 1: Localhost
curl http://localhost:8000/health/
# Expected: {"status":"ok"}

# Test 2: LAN IP
curl http://192.168.1.123:8000/health/
# Expected: {"status":"ok"}

# Test 3: Check Docker config
cd Backend/core
docker compose ps
# All should show "Up (healthy)"
```

✅ **If both work → Go to Step 2**  
❌ **If either fails → Firewall is blocking**

---

### Step 2: Backend Health (Physical Device)

**From your phone on the same WiFi network:**

1. Open web browser
2. Navigate to: `http://192.168.1.123:8000/health/`
3. Should see: `{"status":"ok"}`

✅ **If it works → Go to Step 3**  
❌ **If it fails:**
```bash
# Check device is on same network
ping 192.168.1.123  # From device or computer on same network

# Check firewall
netsh advfirewall firewall show rule name="Django Backend 8000"

# Check port is listening
netstat -ano | findstr :8000
```

---

### Step 3: Flutter App Test

```bash
cd apps/shop_manager

# Clear cache
flutter clean

# Get packages
flutter pub get

# Run with correct backend IP
flutter run --dart-define=API_BASE_URL=http://192.168.1.123:8000

# Watch logs
flutter logs
```

**Expected sequence:**
1. App starts
2. See debug output with backend URL
3. Login screen appears
4. Enter credentials
5. Click Login
6. Dashboard loads

**Debug output should show:**
```
═══════════════════════════════════════════════════════
🔵 FLUTTER LOGIN ATTEMPT
═══════════════════════════════════════════════════════
📍 Backend URL: http://192.168.1.123:8000
📍 Full Endpoint: http://192.168.1.123:8000/auth/login/
👤 Username: test@example.com
═══════════════════════════════════════════════════════
✅ Response received from backend
   Status: 200
   Body: {...}
✅ Login successful!
```

---

## 🔧 TROUBLESHOOTING

### Error: "Connection refused"

```bash
# 1. Is backend running?
docker compose ps

# 2. Is port listening?
netstat -ano | findstr :8000

# 3. If not, start backend
cd Backend/core
docker compose up -d
sleep 10
docker compose ps
```

### Error: "Firewall blocked"

```bash
# Windows PowerShell (as Administrator):
netsh advfirewall firewall add rule name="Django Backend 8000" dir=in action=allow protocol=tcp localport=8000

# Linux UFW:
sudo ufw allow 8000/tcp

# Linux iptables:
sudo iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
```

### Error: "Connection refused" on device but works on host

**Cause:** Firewall or ALLOWED_HOSTS issue

```bash
# 1. Check ALLOWED_HOSTS includes your IP
docker compose exec web python -c "from django.conf import settings; print(settings.ALLOWED_HOSTS)"

# 2. If missing, update .env.docker and restart
# Change: ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,web,192.168.1.123
# To include your device IP

docker compose down
docker compose up -d
```

### Error: "401 Unauthorized"

```bash
# 1. Verify user exists
docker compose exec db psql -U shikela_user -d shikela_db -c "SELECT email FROM account_user;"

# 2. Test login with curl
curl -X POST http://192.168.1.123:8000/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"identifier":"test@example.com","password":"password"}'

# 3. Check backend logs
docker compose logs web | grep -i auth
```

### Error: "Empty lists" from API

```bash
# 1. Check database has data
docker compose exec db psql -U shikela_user -d shikela_db -c "SELECT COUNT(*) FROM catalog_product;"

# 2. Create test data
docker compose exec web python manage.py shell
# Then in Python shell:
from catalog.models import Product
Product.objects.create(name="Test", price=99.99, stock=50)
exit()
```

### Error: "CORS error"

```bash
# 1. Check CORS is enabled
docker compose exec web python -c "from django.conf import settings; print('CORS:', settings.CORS_ALLOW_ALL_ORIGINS)"

# 2. Check middleware order
docker compose exec web python -c "
from django.conf import settings
for i, m in enumerate(settings.MIDDLEWARE):
    print(f'{i}: {m}')
"
# CorsMiddleware should be first (index 0)

# 3. Restart to apply changes
docker compose restart web
```

---

## 📊 CONFIGURATION FILES CHANGED

### 1. Backend/core/.env.docker
```diff
- ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,web,192.168.1.123
+ ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,web,192.168.1.123,192.168.56.1,192.168.56.2,*
+ ALLOW_ALL_HOSTS_IN_DEBUG=true
```

### 2. Backend/core/core/settings.py
```python
# ALLOWED_HOSTS now properly handles all network IPs
ALLOWED_HOSTS = list(dict.fromkeys(_default_allowed_hosts + _env_allowed_hosts))
if DEBUG and os.getenv("ALLOW_ALL_HOSTS_IN_DEBUG") == "true":
    ALLOWED_HOSTS = ["*"]
```

### 3. Flutter lib/services/api_config.dart
```dart
// Now uses Environment helper for device-specific URLs
static String get baseUrl {
  if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
  return Environment.getBackendUrl();
}
```

### 4. Flutter lib/services/auth_service.dart
```dart
// Added comprehensive debug logging showing:
// - Backend URL being called
// - Response status and body
// - Exact error messages
```

---

## ✅ SUCCESS CHECKLIST

- [ ] Firewall rule added for port 8000
- [ ] Backend services running and healthy
- [ ] Health endpoint returns 200 on host
- [ ] Health endpoint returns 200 on device
- [ ] ALLOWED_HOSTS includes all network IPs
- [ ] CORS_ALLOW_ALL_ORIGINS is true
- [ ] Flutter app has correct backend URL
- [ ] Flutter logs show correct URL
- [ ] Login attempt shows debug output
- [ ] Login returns token successfully
- [ ] Dashboard loads without errors
- [ ] Can see data (products, marketers, etc)

---

## 🚀 NEXT STEPS

1. **Right Now:**
   - Run firewall setup script (Windows: `setup_firewall.bat`)
   - Or run bash setup (Linux/Mac: `bash setup_backend.sh`)

2. **Then:**
   - Test health endpoint from host: `curl http://192.168.1.123:8000/health/`
   - Test from device browser: `http://192.168.1.123:8000/health/`

3. **Finally:**
   - Run Flutter with: `flutter run --dart-define=API_BASE_URL=http://192.168.1.123:8000`
   - Watch `flutter logs` for debug output

---

**Time to Success:** 5-15 minutes  
**If Still Having Issues:** Check specific error in troubleshooting section above
