# QUICK REFERENCE CARD

Print or screenshot this for quick access

---

## FIND YOUR IP

**Windows:**
```
ipconfig
→ Look for "IPv4 Address . . . . . . . . . . . : 192.168.x.x"
```

**Mac/Linux:**
```
ifconfig
→ Look for "inet 192.168.x.x"
```

---

## START BACKEND

```bash
cd Backend/core
docker compose up -d
```

---

## VERIFY BACKEND RUNNING

```bash
docker compose ps
curl http://localhost:8000/health/
```

---

## TEST HEALTH ENDPOINT

Replace `192.168.x.x` with your actual IP:

```bash
curl http://192.168.x.x:8000/health/
```

**Expected:** `{"status":"ok"}`

---

## TEST LOGIN

```bash
curl -X POST http://192.168.x.x:8000/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "test@example.com",
    "password": "password123"
  }'
```

**Expected:** JWT token + user info

---

## RUN FLUTTER (DEVELOPMENT)

```bash
cd apps/shop_manager
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000
```

**Replace 192.168.x.x with your IP**

---

## RUN FLUTTER (EMULATOR)

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

---

## VIEW BACKEND LOGS

```bash
docker compose logs -f web      # App logs
docker compose logs -f db       # Database logs
docker compose logs -f celery   # Background tasks
```

---

## STOP BACKEND

```bash
docker compose down
```

---

## RESTART WEB SERVER

```bash
docker compose restart web
```

---

## COMMON ERRORS

| Error | Command to Fix |
|-------|---|
| "Connection refused" | `docker compose ps` (is it running?) |
| "Host unreachable" | `ping 192.168.x.x` (correct IP?) |
| "401 Unauthorized" | Verify token with `flutter logs` |
| "CORS error" | Check `docker compose logs web` |
| "Empty lists" | Verify data exists: `docker compose logs db` |

---

## CRITICAL STEP

**Update:** `Backend/core/.env.docker`

```bash
# Line 3: Replace IP with yours
ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0,web,192.168.YOUR.IP
```

Then restart:
```bash
docker compose down web && docker compose up -d web
```

---

## DOCUMENTATION FILES

- **BACKEND_INTEGRATION_AUDIT.md** → Complete guide
- **QUICK_TESTING_GUIDE.md** → Testing steps
- **API_ENDPOINTS.md** → API reference
- **PRODUCTION_DEPLOYMENT_CHECKLIST.md** → Going live
- **INTEGRATION_COMPLETE.md** → This summary

---

**Bookmark this for quick access!**
