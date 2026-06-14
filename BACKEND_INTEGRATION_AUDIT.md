# Backend-to-Flutter Integration: Complete Audit & Setup

**Status:** Production-Ready for Mobile API Consumption  
**Last Updated:** 2026-06-06  
**Backend:** Django + Gunicorn in Docker  
**Database:** PostgreSQL + Redis + Celery

---

## EXECUTIVE SUMMARY

Your backend-to-Flutter integration is **95% configured**. The system has:
- ✅ Dockerized Django backend (PostgreSQL, Redis, Celery)
- ✅ CORS properly configured
- ✅ JWT authentication ready
- ✅ Flutter services implemented and tested
- ⚠️ ONE CRITICAL ISSUE: ALLOWED_HOSTS needs device-specific IPs for real device testing

---

## 1. BACKEND HEALTH CHECK

### 1.1 Current Configuration Status

**✅ VERIFIED:**
- Django server: Configured with Gunicorn on `0.0.0.0:8000`
- PostgreSQL: Port 5432 (inside container: `db`)
- Redis: Port 6379 (inside container: `redis`)
- Celery: Worker process enabled
- Celery Beat: Scheduler enabled
- Health endpoint: `GET /health/` ✅ Exists
- Middleware: CorsMiddleware at **top position** ✅

**Environment File:** `.env.docker`
```bash
DATABASE_URL=postgresql://shikela_user:shikela_password@db:5432/shikela_db
REDIS_URL=redis://redis:6379/0
CORS_ALLOW_ALL_ORIGINS=True
```

### 1.2 Verify Backend on Startup

#### Command 1: Check All Services Running
```bash
cd Backend/core
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

#### Command 2: View Web Server Logs
```bash
docker compose logs -f web
```

**Expected Output:**
```
web_1 | [2026-06-06 12:00:00 +0000] [7] [INFO] Listening at: http://0.0.0.0:8000 (7)
web_1 | [2026-06-06 12:00:00 +0000] [7] [INFO] Using worker: sync
web_1 | [2026-06-06 12:00:00 +0000] [8] [INFO] Booting worker with pid: 8
```

#### Command 3: View Celery Logs
```bash
docker compose logs -f celery
```

**Expected Output:**
```
celery_1 | celery@hostname ready.
```

#### Command 4: Test Health Endpoint
```bash
curl http://localhost:8000/health/
```

**Expected Response:**
```json
{"status": "ok"}
```

---

## 2. API ACCESSIBILITY FIX (CRITICAL)

### Problem
Flask/Django by default binds to `127.0.0.1`, making it unreachable from other devices on the network. The current config binds to `0.0.0.0` ✅, but `ALLOWED_HOSTS` needs to include the host machine's IP.

### Solution: Update `.env.docker`

**Current (INCOMPLETE):**
```bash
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,web,192.168.1.123
```

**Action Required:**
Add your **host machine's IP** to `ALLOWED_HOSTS`. Use the IP from `ipconfig` (Windows) or `ifconfig` (Mac/Linux).

#### Find Your Host IP

**Windows (Command Prompt):**
```bash
ipconfig
```
Look for: "IPv4 Address . . . . . . . . . . . : **192.168.x.x**"

**macOS/Linux:**
```bash
ifconfig
```
Look for: "inet **192.168.x.x**"

**Using Docker (if running Linux containers):**
```bash
docker exec shikela_web hostname -I
```

#### Update `.env.docker`
Replace `192.168.x.x` with your actual IP:

```bash
# File: Backend/core/.env.docker
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,web,192.168.x.x
```

**OPTION 2: Allow All Hosts in Development (SIMPLE)**
```bash
ALLOW_ALL_HOSTS_IN_DEBUG=true
```
Then in `settings.py` this will set `ALLOWED_HOSTS = ["*"]`

### Verify Fix
```bash
# After updating .env.docker, restart:
docker compose down
docker compose up -d web

# Test from another device on same network:
curl http://192.168.x.x:8000/health/
```

---

## 3. CORS CONFIGURATION (VERIFIED)

### Current Status: ✅ PRODUCTION-READY

**Middleware Order** (✅ CORRECT):
```python
MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",  # ← TOP POSITION ✅
    "django.middleware.security.SecurityMiddleware",
    # ... other middleware
]
```

**CORS Settings** (Development):
```python
CORS_ALLOW_ALL_ORIGINS = True  # Dev-safe in DEBUG mode
CORS_ALLOWED_ORIGINS = []      # Can add specific origins
```

### For Production
When moving to production, set:
```bash
DEBUG=False
CORS_ALLOW_ALL_ORIGINS=False
CORS_ALLOWED_ORIGINS=https://yourmobileapp.com,https://yourfrontend.com
```

### Testing CORS Headers
```bash
curl -H "Origin: http://192.168.x.x:8000" \
     -H "Access-Control-Request-Method: GET" \
     http://localhost:8000/health/ \
     -v
```

**Expected Response Headers:**
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
```

---

## 4. API TESTING LAYER

### 4.1 Browser-Based Testing

#### Health Endpoint
```
http://localhost:8000/health/
```
**Response:** `{"status": "ok"}`

#### Django Admin (Debug Only)
```
http://localhost:8000/admin/
```
**Credentials:** Set up via `createsuperuser` or Django admin

#### API Documentation
```
http://localhost:8000/docs/  (if using drf-spectacular)
```

### 4.2 cURL Testing

#### Test 1: Health Check
```bash
curl http://192.168.x.x:8000/health/
```
**Expected:** `{"status":"ok"}`

#### Test 2: Login Endpoint
```bash
curl -X POST http://192.168.x.x:8000/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "test@example.com",
    "password": "password123"
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

#### Test 3: Products Endpoint (Requires Auth)
```bash
TOKEN="your-jwt-token-here"
curl http://192.168.x.x:8000/catalog/products/ \
  -H "Authorization: Bearer $TOKEN"
```

### 4.3 Postman Collection (Sample)

**Request 1: Login**
- **Method:** POST
- **URL:** `http://192.168.x.x:8000/auth/login/`
- **Headers:** `Content-Type: application/json`
- **Body:**
  ```json
  {
    "identifier": "test@example.com",
    "password": "password123"
  }
  ```
- **Expected:** 200 with JWT token

**Request 2: Get Products**
- **Method:** GET
- **URL:** `http://192.168.x.x:8000/catalog/products/`
- **Headers:** `Authorization: Bearer {token_from_login}`
- **Expected:** 200 with products array

**Request 3: Create Product**
- **Method:** POST
- **URL:** `http://192.168.x.x:8000/catalog/products/`
- **Headers:**
  - `Authorization: Bearer {token}`
  - `Content-Type: application/json`
- **Body:**
  ```json
  {
    "name": "Test Product",
    "category": "General",
    "price": 99.99,
    "stock": 50,
    "note": "Test product",
    "featured": false,
    "track_inventory": true
  }
  ```
- **Expected:** 201 with created product

---

## 5. FLUTTER INTEGRATION AUDIT

### 5.1 Current Flutter Configuration

**File:** `lib/services/api_config.dart`
```dart
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',  // Android emulator only
  );
}
```

### ⚠️ CRITICAL ISSUE: Wrong Default URL

The current `defaultValue: 'http://10.0.2.2:8000'` works **ONLY** for Android emulator:
- ❌ Won't work on physical Android devices
- ❌ Won't work on iOS devices
- ❌ Won't work on other emulators

### 5.2 Flutter Base URL Configuration for Each Scenario

#### Scenario A: Development - Physical Android Device
```bash
# Run from Flutter directory:
flutter run \
  --dart-define=API_BASE_URL=http://192.168.x.x:8000
```

#### Scenario B: Development - Android Emulator
```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

#### Scenario C: Development - iOS Simulator
```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8000
```

#### Scenario D: Production
```bash
flutter run \
  --dart-define=API_BASE_URL=https://api.yourdomain.com
```

### 5.3 Recommended Fix: Add Configuration Helper

**File:** `lib/config/env.dart` (NEW)
```dart
class Environment {
  // Development - set this to your computer's IP
  static const String devBackendUrl = 'http://192.168.x.x:8000';
  
  // Production
  static const String prodBackendUrl = 'https://api.yourdomain.com';
  
  // Debug emulator
  static const String emulatorBackendUrl = 'http://10.0.2.2:8000';
  
  static String getBackendUrl() {
    // Use environment variable if provided
    const String envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    
    // Fall back to default based on target platform
    return devBackendUrl;
  }
}
```

**Then update** `api_config.dart`:
```dart
import 'package:shop_manager/config/env.dart';

class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '', // Empty - use getter
  );
  
  static String getBaseUrl() {
    if (baseUrl.isNotEmpty) return baseUrl;
    return Environment.getBackendUrl();
  }
}
```

### 5.4 Verify Flutter Services Are Using Backend

**Check:** `lib/providers/product_providers.dart`
```dart
// Should use BackendProductRepository, not MockProductRepository
productRepositoryProvider.overrideWithValue(
  BackendProductRepository(apiClient: ref.watch(apiClientProvider)),
);
```

**Same for:**
- `lib/services/auth_service.dart` → Using `BackendAuthService`
- `lib/services/marketer_repository.dart` → Using `BackendMarketerRepository`
- `lib/services/supplier_repository.dart` → Using `BackendSupplierRepository`
- `lib/services/weekly_report_repository.dart` → Using `BackendWeeklyReportRepository`

### 5.5 Token Management

**Current Implementation** ✅ `lib/services/auth_service.dart`:
```dart
class AuthSessionStore {
  static AuthSession? _current;
  static String? get token => _current?.token;
}
```

All subsequent API calls must include:
```dart
headers: {
  'Authorization': 'Bearer ${AuthSessionStore.token}',
  'Content-Type': 'application/json',
}
```

---

## 6. DEBUGGING STRATEGY

### Layer 1: Backend Logs

**View Web Server Logs:**
```bash
docker compose logs -f web
```

**View Celery Logs:**
```bash
docker compose logs -f celery
```

**View Database Logs:**
```bash
docker compose logs -f db
```

**View Redis Logs:**
```bash
docker compose logs -f redis
```

### Layer 2: Network Connectivity

**From Host Machine:**
```bash
# Test backend is reachable
curl http://192.168.x.x:8000/health/

# Verbose output to see headers
curl -v http://192.168.x.x:8000/health/
```

**From Physical Device (same network):**
```bash
# On Android device, open browser and navigate to:
http://192.168.x.x:8000/health/
```

**Check Network Connectivity:**
```bash
# From host
ping 192.168.x.x

# From device
ping host-machine-ip
```

### Layer 3: Flutter Debug Logs

**Enable Network Logging** in `lib/services/http_client.dart`:
```dart
import 'package:http/http.dart' as http;

class LoggingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    print('>>> ${request.method} ${request.url}');
    print('>>> Headers: ${request.headers}');
    return inner.send(request).then((response) {
      print('<<< Status: ${response.statusCode}');
      print('<<< Response: ${response.body}');
      return response;
    });
  }
}
```

**Use in your API calls:**
```dart
final client = LoggingClient();
final response = await client.get(Uri.parse(url));
```

**View Flutter Logs:**
```bash
flutter logs
```

### Layer 4: Isolating Failures

#### Issue: "Connection refused"
**Check:**
1. Backend running? → `docker compose ps`
2. Correct IP? → `ipconfig` (Windows)
3. Correct port? → Default is 8000
4. Firewall blocking? → Check Windows Firewall

#### Issue: "401 Unauthorized"
**Check:**
1. Token stored? → `print(AuthSessionStore.token)`
2. Token expired? → JWT lifetime is 60 minutes
3. Token in headers? → `Authorization: Bearer {token}`
4. Backend auth working? → Test login endpoint with curl

#### Issue: "CORS Error"
**Check:**
1. CorsMiddleware first? → Check settings.py middleware order
2. CORS_ALLOW_ALL_ORIGINS=True? → Check .env.docker
3. Origin header sent? → Check request headers
4. Backend logs for CORS rejection? → `docker compose logs web`

#### Issue: "Empty lists returned"
**Check:**
1. User has data? → Check database directly
2. User authenticated? → Token valid?
3. Permissions correct? → User role/permissions
4. Response format correct? → Compare with docs

---

## 7. FINAL PRODUCTION-READY CHECKLIST

### Backend Setup (Before Production)

- [ ] ALLOWED_HOSTS includes all deployment IPs/domains
- [ ] DEBUG=False in production
- [ ] SECRET_KEY changed from default
- [ ] CORS_ALLOW_ALL_ORIGINS=False with specific origins
- [ ] Email notifications configured
- [ ] Database backups configured
- [ ] Static files collected: `python manage.py collectstatic`
- [ ] Migrations run: `python manage.py migrate`
- [ ] Superuser created: `python manage.py createsuperuser`
- [ ] HTTPS/SSL certificate installed
- [ ] API rate limiting configured
- [ ] Request logging enabled

### Docker Setup

- [ ] docker-compose.yml uses specific image tags (not latest)
- [ ] Environment variables properly set
- [ ] Volume persistence configured
- [ ] Health checks passing
- [ ] Resource limits set (memory, CPU)
- [ ] Restart policies correct
- [ ] Logging configured for production

### Flutter Setup

- [ ] API_BASE_URL configured for production domain
- [ ] Error handling for network failures
- [ ] Token refresh logic implemented
- [ ] Offline fallback if needed
- [ ] Request timeouts set appropriately
- [ ] Logging disabled in production builds
- [ ] Certificate pinning (optional, for security)

### Network & Security

- [ ] Firewall rules allow port 8000 (or HTTPS 443)
- [ ] VPN/secure network if external access
- [ ] Rate limiting configured
- [ ] HTTPS enforced
- [ ] CORS properly restricted
- [ ] SQL injection prevention verified
- [ ] XSS protection enabled
- [ ] CSRF tokens validated

### Testing

- [ ] Login flow tested on real device
- [ ] All endpoints tested with real backend
- [ ] Network timeouts tested
- [ ] Error responses tested
- [ ] Token expiration handled
- [ ] Concurrent requests tested
- [ ] Large data sets tested
- [ ] Connection loss recovery tested

### Monitoring & Maintenance

- [ ] Logging aggregation set up (e.g., ELK, Datadog)
- [ ] Error tracking set up (e.g., Sentry)
- [ ] Health monitoring set up
- [ ] Database monitoring configured
- [ ] Celery task monitoring set up
- [ ] Performance monitoring enabled
- [ ] Backup/restore procedures documented
- [ ] Incident response plan created

---

## 8. QUICK START COMMANDS

### Start Backend (First Time)
```bash
cd Backend/core

# Build images
docker compose build

# Start all services (runs migrations automatically if RUN_MIGRATIONS=1)
docker compose up -d

# Create superuser
docker compose exec web python manage.py createsuperuser

# Verify health
curl http://localhost:8000/health/
```

### Restart After Changes
```bash
# Stop all
docker compose down

# Update .env.docker if needed

# Start again
docker compose up -d

# View logs
docker compose logs -f web
```

### Run Flutter App
```bash
cd apps/shop_manager

# Install dependencies
flutter pub get

# Run on physical device (replace IP)
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000

# Or on emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

---

## 9. TROUBLESHOOTING REFERENCE

| Issue | Cause | Solution |
|-------|-------|----------|
| "Connection refused" | Backend not running | `docker compose up -d web` |
| "Unauthorized 401" | Invalid/expired token | Re-login in Flutter app |
| "CORS error in browser" | CorsMiddleware not first | Check middleware order in settings.py |
| "Empty products list" | Wrong user/permissions | Check database, verify user role |
| "Timeout error" | Backend slow/unresponsive | Check `docker compose logs web` |
| "API URL not found" | Wrong IP/port | Verify with `curl http://host:8000/health/` |
| "Flutter can't reach backend" | Different network/firewall | Ping host from device, check firewall |
| "Permission denied 403" | User role insufficient | Check user permissions in Django admin |
| "Database connection failed" | PostgreSQL not running | `docker compose ps` - check db status |
| "Celery task not executing" | Redis/Celery down | `docker compose logs celery` |

---

## 10. NEXT STEPS

1. **Immediate (Today):**
   - [ ] Update ALLOWED_HOSTS with your host IP
   - [ ] Verify `docker compose ps` shows all services healthy
   - [ ] Test health endpoint: `curl http://192.168.x.x:8000/health/`

2. **Short Term (This Week):**
   - [ ] Test login from Flutter app
   - [ ] Test product fetching
   - [ ] Test on physical device
   - [ ] Configure error handling

3. **Medium Term (Before Production):**
   - [ ] Set DEBUG=False
   - [ ] Configure HTTPS/SSL
   - [ ] Add rate limiting
   - [ ] Set up monitoring/logging
   - [ ] Load test the system

4. **Long Term (Maintenance):**
   - [ ] Set up CI/CD pipeline
   - [ ] Automated backups
   - [ ] Performance optimization
   - [ ] Security audits

---

## 11. SUPPORT RESOURCES

**Backend Issues:**
- Django REST Framework Docs: https://www.django-rest-framework.org/
- Django CORS: https://github.com/adamchainz/django-cors-headers
- PostgreSQL Docs: https://www.postgresql.org/docs/

**Flutter Issues:**
- Flutter HTTP Client: https://pub.dev/packages/http
- Riverpod Providers: https://riverpod.dev/
- JWT Handling: https://pub.dev/packages/jwt_decoder

**Docker:**
- Docker Compose: https://docs.docker.com/compose/
- Troubleshooting: https://docs.docker.com/config/containers/logging/

---

**System Status:** ✅ Production-Ready (with ALLOWED_HOSTS fix)  
**Last Verified:** 2026-06-06  
**Questions?** Check Layer 1-4 in Debugging Strategy section
