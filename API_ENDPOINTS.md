# API Endpoints Reference - Django Backend

**Base URL:** `http://<HOST_IP>:8000` (development)  
**Production URL:** `https://api.yourdomain.com` (update for your domain)

---

## Authentication Endpoints

### Login
- **Method:** `POST`
- **Path:** `/auth/login/`
- **Auth:** ❌ Not required (public)
- **Content-Type:** `application/json`

**Request:**
```json
{
  "identifier": "user@example.com",
  "password": "password123"
}
```

**Response (200 OK):**
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "shop_name": "My Shop",
    "role": "SHOP_OWNER"
  }
}
```

**Error (401):**
```json
{
  "error": "invalid_credentials",
  "message": "Invalid email or password"
}
```

---

## Product Endpoints

### Fetch All Products
- **Method:** `GET`
- **Path:** `/catalog/products/`
- **Auth:** ✅ Required (Bearer token)
- **Query Params:** `?page=1&page_size=20`

**Headers:**
```
Authorization: Bearer {access_token}
```

**Response (200 OK):**
```json
{
  "count": 50,
  "next": "http://...?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Product Name",
      "price": 99.99,
      "stock": 50,
      "image_url": "http://...media/product1.jpg",
      "category": "General",
      "featured": true,
      "discount_percent": 10
    }
  ]
}
```

### Create Product
- **Method:** `POST`
- **Path:** `/catalog/products/`
- **Auth:** ✅ Required
- **Content-Type:** `application/json`

**Request:**
```json
{
  "name": "New Product",
  "category": "Electronics",
  "price": 149.99,
  "stock": 100,
  "note": "Premium product",
  "featured": true,
  "track_inventory": true,
  "discount_percent": 15,
  "reorder_level": 10
}
```

**Response (201 Created):**
```json
{
  "id": 51,
  "name": "New Product",
  "price": 149.99,
  "stock": 100,
  "image_url": null,
  "message": "Product created successfully"
}
```

---

## Marketer Endpoints

### Get Marketer Overview
- **Method:** `GET`
- **Path:** `/marketer/`
- **Auth:** ✅ Required

**Response (200 OK):**
```json
{
  "top_performers": [...],
  "all_marketers": [...],
  "active_contracts": [...],
  "past_contracts": [...]
}
```

### Get Marketer Messages
- **Method:** `GET`
- **Path:** `/marketer/{marketerId}/messages/`
- **Auth:** ✅ Required

**Response (200 OK):**
```json
{
  "messages": [
    {
      "id": 1,
      "marketer_id": "alem-genet",
      "text": "Hello!",
      "from_marketer": true,
      "sent_at": "2026-06-06T12:00:00Z"
    }
  ]
}
```

### Send Marketer Message
- **Method:** `POST`
- **Path:** `/marketer/{marketerId}/messages/`
- **Auth:** ✅ Required

**Request:**
```json
{
  "text": "Hi, how are you?"
}
```

**Response (201 Created):**
```json
{
  "id": 2,
  "marketer_id": "alem-genet",
  "text": "Hi, how are you?",
  "from_marketer": false,
  "sent_at": "2026-06-06T12:05:00Z"
}
```

### Create Marketer Contract
- **Method:** `POST`
- **Path:** `/marketer/contracts/`
- **Auth:** ✅ Required

**Request:**
```json
{
  "marketer_id": "alem-genet",
  "start_date": "2026-06-06T00:00:00Z",
  "end_date": "2026-07-06T23:59:59Z",
  "budget_total": 5000,
  "specialization": "Social Media",
  "channel": "Instagram",
  "goals": ["Increase followers", "Boost sales"]
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "marketer_id": "alem-genet",
  "status": "active",
  "message": "Contract created successfully"
}
```

---

## Supplier Endpoints

### Get Supplier Dashboard
- **Method:** `GET`
- **Path:** `/supliers/`
- **Auth:** ✅ Required
- **Query Params:** `?category=Electronics&region=Addis`

**Response (200 OK):**
```json
{
  "quick_stats": [
    {
      "label": "Total Suppliers",
      "value": "25",
      "icon": "store",
      "trend": "+3%"
    }
  ],
  "reorder_suggestions": [...],
  "trusted_suppliers": [...],
  "orders": [...],
  "market_suppliers": [...]
}
```

---

## Analytics Endpoints

### Get Weekly Report
- **Method:** `GET`
- **Path:** `/analytics/weekly-report/`
- **Auth:** ✅ Required
- **Query Params:** `?from=2026-06-01&to=2026-06-07`

**Response (200 OK):**
```json
{
  "points": [
    {
      "day_label": "Mon",
      "sales": 1500.00,
      "orders": 12
    },
    {
      "day_label": "Tue",
      "sales": 2100.00,
      "orders": 18
    }
  ],
  "generated_at": "2026-06-06T12:00:00Z",
  "growth_rate": 8.5
}
```

---

## Health & Status Endpoints

### Health Check
- **Method:** `GET`
- **Path:** `/health/`
- **Auth:** ❌ Not required

**Response (200 OK):**
```json
{
  "status": "ok"
}
```

### Admin Panel
- **Method:** GET
- **Path:** `/admin/`
- **Browser:** Open `http://HOST_IP:8000/admin/` in browser

---

## Error Responses

All error responses follow this format:

**Format:**
```json
{
  "error": "error_code",
  "message": "Human-readable message",
  "details": {}
}
```

**Common Errors:**

| Status | Error | Message |
|--------|-------|---------|
| 400 | `bad_request` | Invalid request data |
| 401 | `unauthorized` | Missing or invalid token |
| 403 | `forbidden` | User lacks permission |
| 404 | `not_found` | Resource not found |
| 409 | `conflict` | Resource already exists |
| 500 | `server_error` | Internal server error |

---

## HTTP Headers

### Required Headers
```
Content-Type: application/json
Authorization: Bearer {access_token}
```

### Optional Headers
```
Accept: application/json
User-Agent: ShopManagerApp/1.0
X-Request-ID: unique-request-id
```

### Response Headers (Sent by Server)
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
Content-Type: application/json
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
```

---

## Rate Limiting

**Limits (Development):**
- Global: 1000 requests per hour
- Per-user: 100 requests per minute

**Headers Returned:**
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1717681200
```

**Error (429 - Too Many Requests):**
```json
{
  "error": "rate_limit_exceeded",
  "message": "Too many requests. Try again in 60 seconds."
}
```

---

## Pagination

**Standard Pagination Format:**
```json
{
  "count": 100,
  "next": "http://api.example.com/products/?page=2",
  "previous": null,
  "results": [...]
}
```

**Query Parameters:**
- `page` - Page number (default: 1)
- `page_size` - Items per page (default: 20, max: 100)
- `ordering` - Sort field (prefix with `-` for descending)

**Example:**
```
GET /catalog/products/?page=2&page_size=50&ordering=-price
```

---

## Timestamps

All timestamps use **ISO 8601 format** (UTC):

**Format:** `YYYY-MM-DDTHH:MM:SSZ`  
**Example:** `2026-06-06T12:30:45Z`

**Timezone:** UTC (Z = Zulu Time / UTC)

---

## Testing with cURL

**Login Example:**
```bash
curl -X POST http://localhost:8000/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "test@example.com",
    "password": "password123"
  }'
```

**Get Products (with token):**
```bash
TOKEN="eyJ0eXAiOiJKV1QiLCJhbGc..."
curl http://localhost:8000/catalog/products/ \
  -H "Authorization: Bearer $TOKEN"
```

**Create Product:**
```bash
TOKEN="eyJ0eXAiOiJKV1QiLCJhbGc..."
curl -X POST http://localhost:8000/catalog/products/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product",
    "price": 99.99,
    "stock": 50,
    "category": "Test"
  }'
```

---

**Version:** 1.0.0  
**Last Updated:** 2026-06-06  
**Backend:** Django REST Framework 3.16.1
