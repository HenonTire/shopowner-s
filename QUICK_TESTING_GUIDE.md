# Quick Testing Guide - Backend to Flutter Integration

**Goal:** Verify all backend services work correctly and Flutter can communicate with them  
**Time:** ~30 minutes  
**Prerequisites:** Docker running, Flutter installed, device/emulator ready

---

## Phase 1: Backend Verification (5 minutes)

### Step 1.1: Start Backend Services
```bash
cd Backend/core
docker compose up -d
```

Wait 15-30 seconds for services to initialize.

### Step 1.2: Verify Services Running
```bash
docker compose ps
```

**Expected Output:**
```
NAME                 STATUS              PORTS
shikela_db          Up (healthy)        5432/tcp
shikela_redis       Up (healthy)        (no ports)
shikela_web         Up (healthy)        0.0.0.0:8000->8000/tcp
shikela_celery      Up (healthy)        (no ports)
shikela_celery_beat Up (healthy)        (no ports)
```

✅ **All should show "Up (healthy)"**

### Step 1.3: Test Health Endpoint
```bash
curl http://localhost:8000/health/
```

**Expected Output:**
```json
{"status":"ok"}
```

✅ **If you see this, backend is working**

---

## Phase 2: Find Your Host Machine IP (2 minutes)

### Windows (Command Prompt)
```bash
ipconfig
```

**Look for section:**
```
Ethernet adapter ... :
   IPv4 Address . . . . . . . . . . . : 192.168.x.x
```

Write down the IP: `192.168.___.___.___`

### macOS/Linux (Terminal)
```bash
ifconfig
```

**Look for:**
```
inet 192.168.x.x
```

---

## Phase 3: Update Configuration (2 minutes)

### Update `.env.docker` (Backend)
```bash
# File: Backend/core/.env.docker
# Line 3: Replace 192.168.1.123 with your actual IP
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,web,192.168.x.x
```

### Restart Web Service
```bash
cd Backend/core
docker compose down web
docker compose up -d web

# Wait 5 seconds for startup
sleep 5

# Verify
curl http://192.168.x.x:8000/health/
```

✅ **Should return `{"status":"ok"}`**

---

## Phase 4: API Endpoint Testing (5 minutes)

### Test 4.1: Health Endpoint
```bash
curl http://192.168.x.x:8000/health/
```
**Expected:** `{"status":"ok"}`

### Test 4.2: Login Endpoint (Create Test User First)
```bash
# First, create a test user in Django admin
docker compose exec web python manage.py shell
```

In the Django shell:
```python
from account.models import User

# Create test user
User.objects.create_user(
    email='test@example.com',
    username='testuser',
    password='TestPassword123!',
    name='Test User',
    shop_name='Test Shop'
)
print("User created!")
exit()
```

Then test login:
```bash
curl -X POST http://192.168.x.x:8000/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "test@example.com",
    "password": "TestPassword123!"
  }'
```

**Expected Response:**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "email": "test@example.com",
    "name": "Test User",
    "shop_name": "Test Shop",
    "role": "SHOP_OWNER"
  }
}
```

✅ **If you see JWT token, authentication works**

### Test 4.3: Products Endpoint
```bash
# Use the token from previous response
TOKEN="eyJ0eXAiOiJKV1QiLCJhbGc..."

curl http://192.168.x.x:8000/catalog/products/ \
  -H "Authorization: Bearer $TOKEN"
```

**Expected Response:**
```json
{
  "count": 0,
  "next": null,
  "previous": null,
  "results": []
}
```

✅ **Empty list is OK - no products yet**

### Test 4.4: Create Product
```bash
TOKEN="eyJ0eXAiOiJKV1QiLCJhbGc..."

curl -X POST http://192.168.x.x:8000/catalog/products/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "category": "Electronics",
    "price": 99.99,
    "stock": 50,
    "note": "Integration test",
    "featured": false,
    "track_inventory": true
  }'
```

**Expected Response:**
```json
{
  "id": 1,
  "name": "Test Product",
  "price": 99.99,
  "stock": 50,
  "image_url": null,
  "message": "Product created successfully"
}
```

✅ **If you see this, products endpoint works**

---

## Phase 5: Flutter Configuration (2 minutes)

### Update Flutter Environment
```dart
// File: lib/config/environment.dart
// Replace this line with your actual IP:
static const String devBackendUrl = 'http://192.168.x.x:8000';
```

---

## Phase 6: Flutter App Testing (10 minutes)

### Test 6.1: Android Emulator
```bash
cd apps/shop_manager

# Make sure emulator is running
# Then run app (emulator URL)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

**Expected Flow:**
1. App starts
2. Login screen appears
3. Enter: `test@example.com` / `TestPassword123!`
4. Click Login
5. App should load dashboard
6. Should see "Test Product" in inventory

### Test 6.2: Physical Android Device (Same Network)
```bash
# Connect device via USB or same WiFi
flutter devices  # Verify device shows

flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
```

**Expected Flow:** Same as above

### Test 6.3: iOS Simulator
```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

---

## Phase 7: Verify All Features (5 minutes)

### Checklist
- [ ] Login works
- [ ] Dashboard loads
- [ ] Products visible
- [ ] Can create product (if form available)
- [ ] No 401/403 errors
- [ ] No timeout errors
- [ ] Network log shows correct API calls

### View Debug Logs
```bash
flutter logs
```

**Look for any errors like:**
- ❌ `Connection refused` → Backend not running
- ❌ `401 Unauthorized` → Token issue
- ❌ `CORS error` → CORS not configured
- ❌ `Network timeout` → IP/port wrong

---

## Troubleshooting

### "Connection refused"
```bash
# Check backend running
docker compose ps

# Check correct IP
curl http://192.168.x.x:8000/health/

# Check firewall allows port 8000
```

### "401 Unauthorized"
```bash
# Verify token is being sent
flutter logs  # Look for Authorization header

# Verify user exists
docker compose exec web python manage.py shell
from account.models import User
print(User.objects.all())
```

### "CORS error in console"
```bash
# Check middleware order in settings.py
# CorsMiddleware should be FIRST

# Check CORS_ALLOW_ALL_ORIGINS=True
grep "CORS_ALLOW_ALL_ORIGINS" Backend/core/.env.docker
```

### "Timeout error"
```bash
# Check backend logs
docker compose logs -f web

# Verify database connection
docker compose logs db
```

### "Empty product list"
```bash
# Create test data as shown in Phase 4
# OR

# Check user permissions
docker compose exec web python manage.py shell
from account.models import User
user = User.objects.get(email='test@example.com')
print(f"Role: {user.role}")
```

---

## Success Criteria

✅ **All tests pass if:**
1. Health endpoint returns `{"status":"ok"}`
2. Login creates valid JWT token
3. Products endpoint returns 200 (even if empty)
4. Create product returns 201
5. Flutter app logs in successfully
6. Flutter app shows dashboard without errors

---

## Next: Production Setup

Once all tests pass, proceed with:
1. Set `DEBUG=False` in `.env.docker`
2. Generate new `SECRET_KEY`
3. Configure HTTPS/SSL
4. Set proper `ALLOWED_HOSTS` for production domain
5. Configure rate limiting
6. Set up monitoring/logging

---

**Quick Reference:**
```bash
# Start backend
cd Backend/core && docker compose up -d

# Test health
curl http://192.168.x.x:8000/health/

# View logs
docker compose logs -f web

# Run Flutter (emulator)
cd apps/shop_manager && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Run Flutter (device)
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
```
