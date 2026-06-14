# Production Deployment Checklist & Configuration

**Status:** Pre-Production (Ready for deployment after this checklist)  
**Timeline:** 2-3 days before going live

---

## 1. SECURITY HARDENING

### 1.1 Django Settings

**File:** `Backend/core/.env` (Production)

```bash
# === CRITICAL SETTINGS ===
DEBUG=False
ALLOWED_HOSTS=api.yourdomain.com,yourdomain.com,www.yourdomain.com
SECRET_KEY=generate-new-secret-key-here  # Use: python -c "import secrets; print(secrets.token_urlsafe(50))"

# === SECURITY ===
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
SECURE_BROWSER_XSS_FILTER=True
X_FRAME_OPTIONS=DENY
SECURE_CONTENT_SECURITY_POLICY=True

# === CORS (RESTRICTED) ===
CORS_ALLOW_ALL_ORIGINS=False
CORS_ALLOWED_ORIGINS=https://yourdomain.com,https://app.yourdomain.com

# === RATE LIMITING ===
RATE_LIMIT_ENABLED=True
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_PERIOD=3600

# === DATABASE (Use External Service) ===
DATABASE_URL=postgresql://user:password@managed-db-host:5432/shikela_db

# === REDIS (Use External Service) ===
REDIS_URL=redis://:password@managed-redis-host:6379/0

# === EMAIL ===
EMAIL_NOTIFICATIONS_ENABLED=True
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
EMAIL_USE_TLS=True
DEFAULT_FROM_EMAIL=no-reply@yourdomain.com

# === LOGGING ===
LOG_LEVEL=INFO
LOG_FILE=/var/log/django/app.log
```

### 1.2 Generate New Secret Key
```bash
python -c "import secrets; print(secrets.token_urlsafe(50))"
# Output: abc...xyz
# Copy this and update SECRET_KEY
```

### 1.3 Update Django Settings for HTTPS
```python
# File: Backend/core/core/settings.py (add to end)

if not DEBUG:
    SECURE_SSL_REDIRECT = os.getenv("SECURE_SSL_REDIRECT", "true").lower() in {"1", "true"}
    SESSION_COOKIE_SECURE = os.getenv("SESSION_COOKIE_SECURE", "true").lower() in {"1", "true"}
    CSRF_COOKIE_SECURE = os.getenv("CSRF_COOKIE_SECURE", "true").lower() in {"1", "true"}
```

---

## 2. HTTPS/SSL SETUP

### 2.1 Get SSL Certificate

**Option A: Free Certificate (Let's Encrypt)**
```bash
# Using Certbot with Docker
docker run -it --rm --name certbot \
  -v "/etc/letsencrypt:/etc/letsencrypt" \
  -v "/var/lib/letsencrypt:/var/lib/letsencrypt" \
  -p 80:80 -p 443:443 \
  certbot/certbot certonly --standalone \
  -d yourdomain.com \
  -d www.yourdomain.com
```

**Option B: Paid Certificate**
- GoDaddy, Namecheap, or other providers
- Follow their installation guide

### 2.2 Update Docker Compose for SSL

**File:** `Backend/core/docker-compose.yml`

```yaml
web:
  build: .
  container_name: shikela_web
  command: gunicorn core.wsgi:application --bind 0.0.0.0:8000
  volumes:
    - .:/app
    - /etc/letsencrypt:/etc/letsencrypt:ro  # SSL certificates
    - media_volume:/app/media
  ports:
    - "80:80"    # HTTP (redirect to HTTPS)
    - "443:443"  # HTTPS
  restart: unless-stopped
```

### 2.3 Configure Nginx Reverse Proxy (Recommended)

**File:** `nginx.conf` (New file)

```nginx
upstream django_app {
    server web:8000;
}

server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    location / {
        proxy_pass http://django_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /static/ {
        alias /app/staticfiles/;
    }
    
    location /media/ {
        alias /app/media/;
    }
}
```

**Update Docker Compose to include Nginx:**
```yaml
nginx:
    image: nginx:alpine
    container_name: shikela_nginx
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
      - /etc/letsencrypt:/etc/letsencrypt:ro
      - static_volume:/app/staticfiles:ro
      - media_volume:/app/media:ro
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - web
```

---

## 3. DATABASE SETUP

### 3.1 Use Managed Database (Recommended for Production)

**Providers:**
- Amazon RDS (PostgreSQL)
- Google Cloud SQL
- DigitalOcean Managed Databases
- Azure Database for PostgreSQL
- Heroku Postgres

**Update `.env` with connection string:**
```bash
DATABASE_URL=postgresql://user:password@db-host:5432/dbname
```

### 3.2 Run Initial Migrations

```bash
docker compose exec web python manage.py migrate

# Create superuser
docker compose exec web python manage.py createsuperuser
```

### 3.3 Backup Database Regularly

```bash
# Manual backup
docker compose exec db pg_dump -U shikela_user shikela_db > backup.sql

# Restore from backup
docker compose exec -T db psql -U shikela_user shikela_db < backup.sql

# Automated backup (add to cron)
0 2 * * * docker compose exec -T db pg_dump -U shikela_user shikela_db > /backups/db_$(date +\%Y\%m\%d).sql
```

---

## 4. MONITORING & LOGGING

### 4.1 Set Up Error Tracking (Sentry)

```bash
# Install Sentry SDK
pip install sentry-sdk
```

**Update Django Settings:**
```python
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration

sentry_sdk.init(
    dsn=os.getenv("SENTRY_DSN", ""),
    integrations=[DjangoIntegration()],
    traces_sample_rate=0.1,
    send_default_pii=False,
    environment=os.getenv("ENVIRONMENT", "production")
)
```

**Environment Variable:**
```bash
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
```

### 4.2 Set Up Application Logging

```python
# File: Backend/core/core/settings.py

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "{levelname} {asctime} {module} {process:d} {thread:d} {message}",
            "style": "{",
        },
    },
    "handlers": {
        "file": {
            "level": "INFO",
            "class": "logging.FileHandler",
            "filename": "/var/log/django/django.log",
            "formatter": "verbose",
        },
        "console": {
            "level": "INFO",
            "class": "logging.StreamHandler",
            "formatter": "verbose",
        },
    },
    "root": {
        "handlers": ["console", "file"],
        "level": "INFO",
    },
}
```

### 4.3 Monitor with Datadog/New Relic

```bash
# Datadog APM
pip install ddtrace

# Start with APM tracing
ddtrace-run gunicorn core.wsgi:application --bind 0.0.0.0:8000
```

---

## 5. CELERY SETUP FOR PRODUCTION

### 5.1 Use Supervisor for Process Management

**File:** `/etc/supervisor/conf.d/celery.conf`

```ini
[program:celery]
command=celery -A core worker -l info
directory=/app
user=nobody
numprocs=1
stdout_logfile=/var/log/celery/worker.log
stderr_logfile=/var/log/celery/worker.log
autostart=true
autorestart=true
startsecs=10
stopwaitsecs=600

[program:celery-beat]
command=celery -A core beat -l info
directory=/app
user=nobody
numprocs=1
stdout_logfile=/var/log/celery/beat.log
stderr_logfile=/var/log/celery/beat.log
autostart=true
autorestart=true
startsecs=10
```

### 5.2 Redis Persistence

```bash
# File: redis.conf
appendonly yes
appendfsync everysec
```

---

## 6. FLUTTER APP PRODUCTION BUILD

### 6.1 Update API Configuration

**File:** `lib/config/environment.dart`

```dart
static const String prodBackendUrl = 'https://api.yourdomain.com';
```

### 6.2 Build Release APK/IPA

**Android:**
```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com
```

**iOS:**
```bash
flutter build ios --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com
```

### 6.3 Update Firebase/Analytics

```dart
// Disable debug features in production
if (kReleaseMode) {
  // Production configuration
  initializeFirebase();
}
```

---

## 7. DEPLOYMENT VERIFICATION

### Checklist Before Going Live

- [ ] DEBUG=False confirmed
- [ ] SECRET_KEY changed to new value
- [ ] ALLOWED_HOSTS set to production domain
- [ ] CORS_ALLOW_ALL_ORIGINS=False
- [ ] CORS_ALLOWED_ORIGINS set correctly
- [ ] SSL certificate installed and working
- [ ] Nginx reverse proxy configured (if used)
- [ ] Database backups configured
- [ ] Email sending tested
- [ ] Error tracking (Sentry) configured
- [ ] Application logging configured
- [ ] Rate limiting enabled
- [ ] Firewall allows ports 80, 443
- [ ] DNS points to correct IP
- [ ] Health endpoint returns 200
- [ ] Login endpoint tested
- [ ] All APIs return expected results
- [ ] Flutter app connects successfully
- [ ] Token refresh works
- [ ] Error handling works
- [ ] Monitoring active
- [ ] On-call rotation set up

### Final Tests

```bash
# 1. Test HTTPS
curl -v https://api.yourdomain.com/health/

# 2. Test login
curl -X POST https://api.yourdomain.com/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"identifier":"test@example.com","password":"password"}'

# 3. Test with Flutter
flutter run --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com

# 4. Load test
ab -n 1000 -c 100 https://api.yourdomain.com/health/
```

---

## 8. POST-DEPLOYMENT

### Monitoring Daily
- [ ] Check error tracking (Sentry)
- [ ] Check application logs
- [ ] Monitor server resources (CPU, memory, disk)
- [ ] Monitor API response times
- [ ] Check database performance

### Weekly
- [ ] Review security logs
- [ ] Verify backups are working
- [ ] Update dependencies (security patches)
- [ ] Review rate limiting hits

### Monthly
- [ ] Security audit
- [ ] Performance review
- [ ] Capacity planning
- [ ] Disaster recovery drill

---

## 9. ROLLBACK PROCEDURE

If something goes wrong:

```bash
# 1. Stop current deployment
docker compose down

# 2. Restore from backup
docker compose exec -T db psql -U shikela_user shikela_db < backup.sql

# 3. Revert code to previous version
git checkout previous-tag

# 4. Rebuild and restart
docker compose build
docker compose up -d

# 5. Verify
curl https://api.yourdomain.com/health/
```

---

**Ready for Production:** Follow all steps above before going live  
**Support:** Check logs with `docker compose logs -f web`
