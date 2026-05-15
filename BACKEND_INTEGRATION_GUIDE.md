# Backend Integration Guide - Shop Manager App

## Summary
This document details all backend API endpoints needed to fully integrate the Shop Manager Flutter application with a backend server. The app is structured with repositories that handle all data fetching and business logic.

---

## 1. AUTHENTICATION

### Login Endpoint
**File:** `lib/services/auth_service.dart`
**Current Status:** Mock implementation only
**Endpoint:** `POST /auth/login`

#### Request Format:
```json
{
  "identifier": "string (email or username)",
  "password": "string"
}
```

#### Response Format (on success):
```json
{
  "token": "string (JWT or session token)",
  "user": {
    "id": "string",
    "email": "string",
    "name": "string",
    "shopName": "string",
    "role": "string"
  }
}
```

#### Error Response:
```json
{
  "error": "Invalid credentials",
  "message": "string"
}
```

**Notes:**
- Store the returned token for subsequent API calls
- Use the token in Authorization header: `Authorization: Bearer {token}`

---
## 2. PRODUCTS

### 2.1 Fetch All Products
**File:** `lib/services/product_repository.dart`
**Provider:** `lib/providers/product_providers.dart`
**Endpoint:** `GET /products`

#### Response Format:
```json
{
  "products": [
    {
      "id": "string",
      "name": "string",
      "image_url": "string (URL to product image)",
      "price": "number (double, in ETB)",
      "stock": "number (integer)",
      "category": "string (optional)",
      "description": "string (optional)",
      "discount_percent": "number (optional)",
      "featured": "boolean (optional)"
    }
  ],
  "total_count": "number (optional)"
}
```

#### Data Fields Needed:
- `id` - Unique product identifier
- `name` - Product name (displayed in inventory)
- `image_url` - URL to product image
- `price` - Product price in ETB
- `stock` - Current stock quantity
- `category` - Product category (for filtering)
- `featured` - Whether product is featured
- `discount_percent` - Discount percentage if applicable

### 2.2 Create Product
**Endpoint:** `POST /products`
**Request Format:**
```json
{
  "name": "string",
  "category": "string",
  "price": "number",
  "stock": "number",
  "note": "string",
  "featured": "boolean",
  "track_inventory": "boolean",
  "discount_percent": "number",
  "reorder_level": "number",
  "image_file_name": "string (optional)",
  "image_base64": "string (optional - base64 encoded image)"
}
```

#### Response Format:
```json
{
  "id": "string",
  "name": "string",
  "image_url": "string",
  "price": "number",
  "stock": "number",
  "message": "Product created successfully"
}
```

---

## 3. MARKETERS

### 3.1 Fetch Marketer Overview
**File:** `lib/services/marketer_repository.dart`
**Provider:** `lib/providers/marketer_providers.dart`
**Endpoint:** `GET /marketers/overview`

#### Response Format:
```json
{
  "top_performers": [
    {
      "id": "string",
      "name": "string",
      "specialization": "string",
      "tagline": "string",
      "rating": "number (1-5)",
      "total_orders": "number",
      "conversion_rate": "number (percentage)",
      "revenue_generated": "string (formatted, e.g., 'ETB 120,000')",
      "badge_label": "string (e.g., 'Top Performer', 'Growing')",
      "avatar_color": "string (hex color code, e.g., '#1E88E5')"
    }
  ],
  "all_marketers": [
    {
      "id": "string",
      "name": "string",
      "specialization": "string",
      "tagline": "string",
      "rating": "number",
      "total_orders": "number",
      "conversion_rate": "number",
      "revenue_generated": "string",
      "badge_label": "string",
      "avatar_color": "string"
    }
  ],
  "chat_threads": [
    {
      "marketer": {
        "id": "string",
        "name": "string",
        "specialization": "string",
        "tagline": "string",
        "rating": "number",
        "total_orders": "number",
        "conversion_rate": "number",
        "revenue_generated": "string",
        "badge_label": "string",
        "avatar_color": "string"
      },
      "last_message": "string",
      "sent_at": "string (time format, e.g., '09:45' or 'Yesterday')",
      "unread_count": "number",
      "online": "boolean"
    }
  ],
  "active_contracts": [
    {
      "id": "string",
      "marketer_id": "string",
      "name": "string",
      "specialization": "string",
      "contract_status": "string (e.g., 'Active', 'Expiring Soon', 'Pending')",
      "start_date": "string (ISO 8601 format)",
      "end_date": "string (ISO 8601 format)",
      "campaign_progress": "number (0-1, represents percentage)",
      "budget_used": "number",
      "budget_total": "number",
      "revenue": "number",
      "orders": "number",
      "conversion_rate": "number",
      "trend_percent": "number (can be negative)",
      "avatar_color": "string"
    }
  ],
  "past_contracts": [
    {
      "id": "string",
      "marketer_id": "string",
      "name": "string",
      "specialization": "string",
      "final_status": "string (e.g., 'Completed', 'Cancelled')",
      "total_revenue": "number",
      "total_orders": "number",
      "final_conversion_rate": "number",
      "spent": "number",
      "rating": "number (1-5)",
      "review": "string",
      "avatar_color": "string"
    }
  ],
  "unread_chats": "number (optional)"
}
```

#### Data Fields Needed:
- `id` - Unique marketer identifier
- `name` - Marketer name
- `specialization` - Marketing specialization
- `tagline` - Short description
- `rating` - Rating (1-5 scale)
- `total_orders` - Total orders generated
- `conversion_rate` - Conversion rate as percentage
- `revenue_generated` - Total revenue (formatted as string)
- `badge_label` - Status badge text
- `avatar_color` - Hex color for avatar
- `contract_status` - Status of current contract
- `campaign_progress` - Progress from 0 to 1 (for progress bars)
- `start_date`/`end_date` - Contract dates (ISO 8601)
- `budget_used`/`budget_total` - Budget information

### 3.2 Fetch Marketer Chat Messages
**Endpoint:** `GET /marketers/{marketerId}/messages`

#### Response Format:
```json
{
  "messages": [
    {
      "id": "string",
      "marketer_id": "string",
      "text": "string",
      "from_marketer": "boolean",
      "sent_at": "string (time format or ISO 8601)"
    }
  ],
  "total": "number (optional)"
}
```

### 3.3 Send Marketer Message
**Endpoint:** `POST /marketers/{marketerId}/messages`

#### Request Format:
```json
{
  "text": "string"
}
```

#### Response Format:
```json
{
  "id": "string",
  "marketer_id": "string",
  "text": "string",
  "from_marketer": "boolean",
  "sent_at": "string",
  "message": "Message sent successfully"
}
```

### 3.4 Create Marketer Contract
**Endpoint:** `POST /marketers/contracts`

#### Request Format:
```json
{
  "marketer_id": "string",
  "start_date": "string (ISO 8601)",
  "end_date": "string (ISO 8601)",
  "budget_total": "number",
  "specialization": "string",
  "channel": "string",
  "goals": ["string"]
}
```

#### Response Format:
```json
{
  "id": "string",
  "marketer_id": "string",
  "status": "string",
  "message": "Contract created successfully"
}
```

---

## 4. SUPPLIERS

### 4.1 Fetch Supplier Dashboard
**File:** `lib/services/supplier_repository.dart`
**Provider:** `lib/providers/supplier_providers.dart`
**Endpoint:** `GET /suppliers/dashboard`

#### Response Format:
```json
{
  "quick_stats": [
    {
      "label": "string",
      "value": "string",
      "icon": "string (icon name)",
      "trend": "string (e.g., '+8%', '-2 late')"
    }
  ],
  "reorder_suggestions": [
    {
      "product": "string",
      "current_stock": "number",
      "reorder_qty": "number",
      "supplier": "string",
      "unit_price": "number",
      "eta": "string (e.g., '1 day')",
      "urgency": "string (e.g., 'critical', 'low', 'stable')"
    }
  ],
  "trusted_suppliers": [
    {
      "name": "string",
      "rating": "number (1-5)",
      "speed": "string (delivery speed)",
      "categories": "string (comma-separated)",
      "last_interaction": "string",
      "verified": "boolean",
      "avatar_color": "string (hex code)"
    }
  ],
  "orders": [
    {
      "id": "string",
      "supplier": "string",
      "product_count": "number",
      "amount": "string (formatted, e.g., 'ETB 64,300')",
      "order_date": "string",
      "eta": "string",
      "status": "string (e.g., 'in_transit', 'preparing', 'accepted')"
    }
  ],
  "market_suppliers": [
    {
      "name": "string",
      "specialties": "string",
      "start_price": "string",
      "region": "string",
      "delivery": "string",
      "rating": "number",
      "verified": "boolean",
      "avatar_color": "string"
    }
  ],
  "activities": [
    {
      "title": "string",
      "subtitle": "string",
      "time": "string",
      "icon": "string",
      "color": "string (hex code)"
    }
  ],
  "category_chips": ["string"],
  "region_chips": ["string"],
  "speed_chips": ["string"],
  "rating_chips": ["string"]
}
```

#### Data Fields Needed:
- `quick_stats` - Summary statistics
- `reorder_suggestions` - Products that need reordering
- `trusted_suppliers` - List of reliable suppliers
- `orders` - Current and past supplier orders
- `market_suppliers` - Available suppliers in the market
- `activities` - Recent supplier activities
- `*_chips` - Filter options for different categories

---

## 5. WEEKLY REPORTS & SALES DATA

### 5.1 Fetch Weekly Report
**File:** `lib/services/weekly_report_repository.dart`
**Provider:** `lib/providers/weekly_report_providers.dart`
**Endpoint:** `GET /reports/weekly`

#### Query Parameters (optional):
```
?from=2026-01-01&to=2026-01-07
```

#### Response Format:
```json
{
  "points": [
    {
      "day_label": "string (e.g., 'Mon', 'Tue')",
      "sales": "number (in ETB)",
      "orders": "number"
    }
  ],
  "generated_at": "string (ISO 8601)",
  "growth_rate": "number (percentage)"
}
```

#### Data Fields Needed:
- `day_label` - Day of week
- `sales` - Total sales for that day in ETB
- `orders` - Number of orders for that day
- `growth_rate` - Week-over-week growth rate

---

## 6. HOME/DASHBOARD PAGE

**File:** `lib/pages/home.dart`
**Data Required:**
- Weekly sales report (from Weekly Report endpoint)
- Quick stats (sales, orders, growth)
- Latest orders
- Top products

---

## 7. INVENTORY PAGE

**File:** `lib/pages/inventory_page.dart`
**Data Required:**
- Product list (from Products endpoint)
- Stock status indicators
- Low stock alerts
- Inventory summary

---

## 8. PROFILE/MARKETERS PAGE

**File:** `lib/pages/profile_page.dart`
**Data Required:**
- Top performing marketers
- Active marketer contracts
- Marketing performance metrics

---

## 9. REPORT PAGE

**File:** `lib/pages/report_page.dart`
**Data Required:**
- Daily/Weekly/Monthly/Yearly sales data
- Order counts
- Revenue trends
- Average basket value

---

## 10. DATA MODELS REFERENCE

### Product Model
```dart
class Product {
  final String id;
  final String name;
  final String imageUrl;
  final double price;
  final int stock;
}
```

### MarketerSummary Model
```dart
class MarketerSummary {
  final String id;
  final String name;
  final String specialization;
  final String tagline;
  final double rating;
  final int totalOrders;
  final double conversionRate;
  final String revenueGenerated;
  final String badgeLabel;
  final String avatarColorHex;
}
```

### WeeklyReport Model
```dart
class WeeklyReport {
  final List<WeeklyReportPoint> points;
  final DateTime generatedAt;
  final double growthRate;
}
```

---

## 11. IMPLEMENTATION STEPS

### Step 1: Create Backend Service Classes
Replace Mock implementations with actual HTTP clients:
- `BackendProductRepository` in `product_repository.dart`
- `BackendMarketerRepository` in `marketer_repository.dart`
- `BackendSupplierRepository` in `supplier_repository.dart`
- `BackendWeeklyReportRepository` in `weekly_report_repository.dart`
- Real `AuthService` implementation

### Step 2: Update Providers
Update the provider files to use backend services instead of mock:
```dart
// Before (in providers/product_providers.dart):
return const MockProductRepository();

// After:
return BackendProductRepository(apiClient: ref.watch(apiClientProvider));
```

### Step 3: Add Error Handling
- Implement proper error handling for network failures
- Add retry logic for failed requests
- Display user-friendly error messages

### Step 4: Add Token Management
- Store and refresh JWT tokens
- Handle expired token scenarios
- Automatically refresh before expiration

### Step 5: Implement Pagination (if needed)
For large datasets like products and suppliers:
```json
{
  "data": [...],
  "page": 1,
  "page_size": 20,
  "total": 100,
  "has_more": true
}
```

---

## 12. MISSING IMPLEMENTATIONS

### Current Mock-Only Features:
1. ✅ Chat messaging (send/receive messages)
2. ✅ Message persistence
3. ✅ Real-time notifications
4. ✅ File uploads (product images)
5. ✅ Contract management (creation, updates)
6. ✅ Marketer availability/online status
7. ✅ Advanced filtering and search
8. ✅ Analytics and insights
9. ✅ Expense tracking
10. ✅ Customer management

---

## 13. API STANDARDS

### Common Headers:
```
Authorization: Bearer {token}
Content-Type: application/json
Accept: application/json
```

### Error Response Format (Standard):
```json
{
  "error": "string (error code)",
  "message": "string (human readable message)",
  "status_code": "number (HTTP status code)",
  "details": "object (optional, additional error details)"
}
```

### Pagination (Recommended):
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

### Timestamps:
- All timestamps should be in ISO 8601 format
- Server timezone: UTC recommended
- App handles local timezone display

---

## 14. READY-TO-INTEGRATE CHECKLIST

- ✅ All data models have `fromJson()` and `toJson()` methods
- ✅ All repositories have abstract classes defined
- ✅ All providers are set up with FutureProvider pattern
- ✅ Error handling structure in place
- ✅ Mock data available for testing UI
- ✅ No compilation errors
- ✅ marketerId properly propagated through all pages
- ✅ All pages ready to receive backend data

---

## 15. NEXT STEPS

1. **Create API Client:** Use `http` or `dio` package
2. **Implement Backend Repositories:** Replace all Mock implementations
3. **Set Up Error Handling:** Create custom exceptions and error handling
4. **Add Token Management:** Implement JWT token refresh logic
5. **Test with Real Backend:** Verify all endpoints work correctly
6. **Add Logging:** Implement app-wide logging for debugging
7. **Performance Optimization:** Add caching and pagination where needed
