# BACKEND + FLUTTER LAN CONNECTIVITY FIX

**Status:** Diagnosing and fixing mobile device access issue  
**Problem:** Flutter app can't connect from physical device (works on PC localhost)  
**Root Cause:** ALLOWED_HOSTS + Firewall + Network configuration

---

## PHASE 1: DIAGNOSE CURRENT NETWORK STATE

### Your Network IPs (from ipconfig):
- **192.168.56.1** - Ethernet 4
- **192.168.56.2** - Ethernet 5  
- **192.168.1.123** - Main network (in ALLOWED_HOSTS ✅)
- **172.26.16.1** - WSL vEthernet

### Current Django Configuration:
```
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,web,192.168.1.123 ✅
CORS_ALLOW_ALL_ORIGINS=True ✅
Docker binding: 0.0.0.0:8000 ✅
```

**Issue:** Need to determine which IP your **mobile device** is on, and ensure it's allowed.

---

## PHASE 2: VERIFY BACKEND IS RUNNING

```bash
cd Backend/core

# Check if Docker is running
docker compose ps

# Start if not running
docker compose up -d
```

**Expected:**
```
NAME                 STATUS              PORTS
shikela_db          Up (healthy)        5432/tcp
shikela_redis       Up (healthy)        
shikela_web         Up (healthy)        0.0.0.0:8000->8000/tcp
shikela_celery      Up (healthy)        
shikela_celery_beat Up (healthy)        
```

---

## PHASE 3: TEST BACKEND ON HOST MACHINE

### Test 1: Health Endpoint (localhost)
```bash
curl http://localhost:8000/health/
```
**Expected:** `{"status":"ok"}` ✅

### Test 2: Health Endpoint (LAN IP)
```bash
curl http://192.168.1.123:8000/health/
```
**Expected:** `{"status":"ok"}` ✅

If this fails → **Firewall is blocking port 8000**

### Test 3: Check What Django Sees
```bash
docker compose exec web python -c "
from django.conf import settings
print('ALLOWED_HOSTS:', settings.ALLOWED_HOSTS)
print('DEBUG:', settings.DEBUG)
print('CORS_ALLOW_ALL_ORIGINS:', settings.CORS_ALLOW_ALL_ORIGINS)
"
```

---

## PHASE 4: OPEN WINDOWS FIREWALL (CRITICAL!)

### Method 1: Command Line (Easiest)

**Run PowerShell as Administrator:**
```powershell
# Create firewall rule for port 8000
netsh advfirewall firewall add rule name="Django Backend 8000" dir=in action=allow protocol=tcp localport=8000

# Verify rule was added
netsh advfirewall firewall show rule name="Django Backend 8000"
```

### Method 2: Windows Firewall GUI

1. Open Windows Defender Firewall → Advanced Settings
2. Click "Inbound Rules" → "New Rule"
3. Select "Port" → TCP → Specific local port: **8000**
4. Allow the connection → Apply to Domain, Private, Public
5. Name it "Django Backend 8000"

### Verify Firewall Rule:
```bash
# Check if port is listening
netstat -ano | findstr :8000

# Should show: TCP 0.0.0.0:8000 LISTENING
```

---

## PHASE 5: CONFIGURE DJANGO FOR ALL NETWORK IPs

### Update .env.docker

Add all possible IPs to ALLOWED_HOSTS (or use wildcard for dev):

**Option A: Specific IPs (Recommended for Security)**
```bash
# File: Backend/core/.env.docker
# Current:
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,web,192.168.1.123

# Add your other adapter IPs:
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,web,192.168.1.123,192.168.56.1,192.168.56.2
```

**Option B: Allow All in Development (Simplest)**
```bash
# For development ONLY (not production):
DEBUG=False
ALLOW_ALL_HOSTS_IN_DEBUG=true
```

Then in settings.py, this becomes: `ALLOWED_HOSTS = ["*"]`

### Restart Docker After Changes:
```bash
cd Backend/core
docker compose down
docker compose up -d

# Wait 10 seconds
sleep 10

# Verify
docker compose ps
```

---

## PHASE 6: CHECK DOCKER NETWORK CONNECTIVITY

### Test from Inside Docker Container:
```bash
# SSH into web container
docker compose exec web bash

# Inside container, test:
curl http://127.0.0.1:8000/health/
python -c "import socket; print(socket.gethostname())"
exit
```

### Test from Host to Container IP:
```bash
# Get container IP
docker inspect shikela_web | grep "IPAddress"

# Test container IP directly
curl http://<CONTAINER_IP>:8000/health/
```

---

## PHASE 7: VERIFY MOBILE DEVICE CAN REACH HOST

### From Mobile Device (same WiFi network):

**1. Test Host Reachability:**
```bash
# On phone, open browser and navigate to:
http://192.168.1.123:8000/health/

# Should see: {"status":"ok"}
```

**2. If That Works → Test Login:**
```bash
http://192.168.1.123:8000/auth/login/
# (Will show method not allowed - but proves backend reachable)
```

**3. If That Fails:**
- Device not on same network?
- IP mismatch?
- Firewall still blocking?

---

## PHASE 8: FIX FLUTTER APP

### Current Configuration:
```dart
// lib/services/api_config.dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000',  // ❌ Android emulator ONLY
);
```

### Fix: Update Flutter Environment Helper

**Create/Update:** `lib/config/environment.dart`

```dart
class Environment {
  // IMPORTANT: Update with YOUR network IP
  static const String devBackendUrl = 'http://192.168.1.123:8000';
  
  static const String emulatorUrl = 'http://10.0.2.2:8000';
  
  static String getBackendUrl() {
    const String envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    return devBackendUrl;
  }
}
```

### Update api_config.dart:

```dart
import 'package:shop_manager/config/environment.dart';

class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '', // Empty - will use Environment.getBackendUrl()
  );
  
  static String getBaseUrl() {
    if (baseUrl.isNotEmpty) return baseUrl;
    return Environment.getBackendUrl();
  }
}
```

### Run Flutter with Correct IP:

**For Physical Device (on your network):**
```bash
cd apps/shop_manager
flutter run --dart-define=API_BASE_URL=http://192.168.1.123:8000
```

**For Android Emulator:**
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

**For iOS Simulator:**
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

---

## PHASE 9: CHECK FLUTTER HTTP CLIENT

### Verify Token is Being Sent:

**File:** `lib/services/auth_service.dart` → Check `BackendAuthService`

```dart
@override
Future<void> login(LoginRequest request) async {
  final http.Client activeClient = client ?? http.Client();

  try {
    final http.Response response = await activeClient
        .post(
          _endpoint('/auth/login/'),
          headers: const <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 20));
    // ...
  }
}
```

### Add Debug Logging:

```dart
class BackendAuthService implements AuthService {
  @override
  Future<void> login(LoginRequest request) async {
    final http.Client activeClient = client ?? http.Client();
    final Uri endpoint = _endpoint('/auth/login/');
    
    print('🔍 LOGIN DEBUG:');
    print('  URL: $endpoint');
    print('  Method: POST');
    print('  Headers: Accept: application/json, Content-Type: application/json');
    print('  Request body: ${jsonEncode(request.toJson())}');
    
    try {
      final response = await activeClient
          .post(endpoint, ...)
          .timeout(const Duration(seconds: 20));
      
      print('  Response Status: ${response.statusCode}');
      print('  Response Body: ${response.body}');
      // ...
    } catch (e) {
      print('  ERROR: $e');
      rethrow;
    }
  }
}
```

### View Flutter Logs:
```bash
flutter logs
# Watch for login debug output
```

---

## PHASE 10: COMPLETE DIAGNOSTIC CHECKLIST

```bash
# 1. Backend Running?
docker compose ps
# ✅ All should show "Up (healthy)"

# 2. Port Open on Host?
netstat -ano | findstr :8000
# ✅ Should show LISTENING

# 3. Firewall Allowing?
netsh advfirewall firewall show rule name="Django Backend 8000"
# ✅ Should show Rule Enabled

# 4. ALLOWED_HOSTS Correct?
docker compose exec web python -c "from django.conf import settings; print(settings.ALLOWED_HOSTS)"
# ✅ Should include your network IPs

# 5. Test from Host:
curl http://192.168.1.123:8000/health/
# ✅ Should return {"status":"ok"}

# 6. Test from Device Browser:
# Navigate to: http://192.168.1.123:8000/health/
# ✅ Should see JSON response

# 7. Flutter Logs Show Correct URL?
flutter logs | grep API_BASE_URL
# ✅ Should show correct IP
```

---

## PHASE 11: IF STILL NOT WORKING

### Symptom: "Connection refused"
**Fix:**
```bash
# 1. Is Docker running?
docker ps

# 2. Is port bound?
netstat -ano | findstr :8000

# 3. Is firewall blocking?
netsh advfirewall firewall show rule name="Django Backend 8000"

# 4. Backend logs
docker compose logs web | tail -50
```

### Symptom: "401 Unauthorized"
**Fix:**
```bash
# 1. Check token is being sent
flutter logs | grep Authorization

# 2. Test login with curl
curl -X POST http://192.168.1.123:8000/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"identifier":"test@example.com","password":"password"}'

# 3. Check backend auth logs
docker compose logs web | grep -i "auth\|login"
```

### Symptom: "CORS error"
**Fix:**
```bash
# Check CORS config
docker compose exec web python -c "from django.conf import settings; print('CORS:', settings.CORS_ALLOW_ALL_ORIGINS)"

# Should show: CORS: True

# If not, restart:
docker compose restart web
```

### Symptom: "Empty lists returned"
**Fix:**
```bash
# Check database has data
docker compose exec db psql -U shikela_user -d shikela_db -c "SELECT COUNT(*) FROM catalog_product;"

# Check user permissions
docker compose exec db psql -U shikela_user -d shikela_db -c "SELECT role FROM account_user WHERE email='test@example.com';"
```

---

## QUICK FIX SCRIPT

Copy and run this complete fix:

```bash
#!/bin/bash

cd Backend/core

# 1. Update ALLOWED_HOSTS
cat .env.docker | sed 's/ALLOWED_HOSTS=.*/ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,web,192.168.1.123,192.168.56.1,192.168.56.2/' > .env.docker.tmp
mv .env.docker.tmp .env.docker

# 2. Restart Docker
docker compose down
docker compose up -d

# 3. Wait for services
sleep 10

# 4. Verify
echo "✅ Checking services..."
docker compose ps

echo ""
echo "✅ Testing health endpoint..."
curl http://localhost:8000/health/

echo ""
echo "✅ Testing on LAN IP..."
curl http://192.168.1.123:8000/health/

echo ""
echo "✅ Docker configuration:"
docker compose exec web python -c "from django.conf import settings; print('ALLOWED_HOSTS:', settings.ALLOWED_HOSTS)"

echo ""
echo "✅ Ready for Flutter testing!"
```

---

## FINAL TESTING COMMAND (Flutter)

```bash
# From your Flutter directory:
cd apps/shop_manager

# Clear build cache
flutter clean

# Get packages
flutter pub get

# Run on device with correct backend IP
flutter run --dart-define=API_BASE_URL=http://192.168.1.123:8000

# Check logs
flutter logs
```

---

## SUCCESS CRITERIA

✅ Backend test:
```bash
curl http://192.168.1.123:8000/health/
# Returns: {"status":"ok"}
```

✅ Device browser test:
```
Open: http://192.168.1.123:8000/health/
See: {"status":"ok"}
```

✅ Flutter app test:
```
App launches → Login screen
Enter credentials
Click Login
Dashboard appears without errors
```

---

**Next Step:** Follow Phase 1-11 in order, then report any errors at specific phases.
