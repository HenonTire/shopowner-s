# Backend Data Structure Reference

Quick reference for backend developers on the exact data format expected by the Flutter app.

## Authentication Response
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user-001",
    "email": "owner@shop.com",
    "name": "Henon Manager",
    "shopName": "Shikela Shop",
    "role": "shop_owner"
  }
}
```

## Products Endpoint Response
```json
{
  "products": [
    {
      "id": "prod-001",
      "name": "Organic Flour 5kg",
      "image_url": "https://images.unsplash.com/...",
      "price": 1240.00,
      "stock": 18,
      "category": "Grains",
      "description": "High quality organic flour",
      "featured": true,
      "discount_percent": 5.0,
      "track_inventory": true,
      "reorder_level": 10
    }
  ],
  "total_count": 150
}
```

## Marketers Overview Response
```json
{
  "top_performers": [
    {
      "id": "alem-genet",
      "name": "Alem Genet",
      "specialization": "Facebook Ads Expert",
      "tagline": "Performance campaigns with weekly ROI reporting.",
      "rating": 4.9,
      "total_orders": 842,
      "conversion_rate": 5.6,
      "revenue_generated": "ETB 120,000",
      "badge_label": "Top Performer",
      "avatar_color": "#1E88E5"
    }
  ],
  "all_marketers": [...],
  "chat_threads": [
    {
      "marketer": { /* marketer object */ },
      "last_message": "I have shared this week's ad set performance report.",
      "sent_at": "09:45",
      "unread_count": 2,
      "online": true
    }
  ],
  "active_contracts": [
    {
      "id": "contract-alem-2026-q2",
      "marketer_id": "alem-genet",
      "name": "Alem Genet",
      "specialization": "Facebook Ads Expert",
      "contract_status": "Active",
      "start_date": "2026-04-10T00:00:00Z",
      "end_date": "2026-06-08T00:00:00Z",
      "campaign_progress": 0.74,
      "budget_used": 51200.0,
      "budget_total": 70000.0,
      "revenue": 154300.0,
      "orders": 911,
      "conversion_rate": 5.8,
      "trend_percent": 7.4,
      "avatar_color": "#1E88E5"
    }
  ],
  "past_contracts": [
    {
      "id": "contract-nati-2025-q4",
      "marketer_id": "nati-birhanu",
      "name": "Nati Birhanu",
      "specialization": "Google Ads Specialist",
      "final_status": "Completed",
      "total_revenue": 187400.0,
      "total_orders": 1092,
      "final_conversion_rate": 4.4,
      "spent": 92000.0,
      "rating": 4,
      "review": "Strong at high-intent traffic and consistent reporting.",
      "avatar_color": "#8E24AA"
    }
  ],
  "unread_chats": 3
}
```

## Marketer Messages Response
```json
{
  "messages": [
    {
      "id": "msg-1",
      "marketer_id": "alem-genet",
      "text": "Hi, I reviewed your shop and I can help improve conversion with better campaign structure.",
      "from_marketer": true,
      "sent_at": "09:18"
    },
    {
      "id": "msg-2",
      "marketer_id": "alem-genet",
      "text": "Great, I want to hire you on contract. Let us align on weekly goals and budget pacing.",
      "from_marketer": false,
      "sent_at": "09:20"
    }
  ],
  "total": 2
}
```

## Suppliers Dashboard Response
```json
{
  "quick_stats": [
    {
      "label": "Total Suppliers",
      "value": "42",
      "icon": "groups_rounded",
      "trend": "+8%"
    },
    {
      "label": "Active Orders",
      "value": "17",
      "icon": "shopping_bag_rounded",
      "trend": "+3 today"
    },
    {
      "label": "Pending Deliveries",
      "value": "9",
      "icon": "local_shipping_rounded",
      "trend": "-2 late"
    },
    {
      "label": "Favorite Suppliers",
      "value": "11",
      "icon": "favorite_rounded",
      "trend": "+2 week"
    },
    {
      "label": "Low Stock Products",
      "value": "13",
      "icon": "warning_amber_rounded",
      "trend": "4 critical"
    },
    {
      "label": "Monthly Purchases",
      "value": "ETB 248K",
      "icon": "payments_rounded",
      "trend": "+12%"
    }
  ],
  "reorder_suggestions": [
    {
      "product": "Cooking Oil 1L",
      "current_stock": 6,
      "reorder_qty": 120,
      "supplier": "Addis Wholesale Trading",
      "unit_price": 145.0,
      "eta": "1 day",
      "urgency": "critical"
    },
    {
      "product": "Sugar 2kg",
      "current_stock": 14,
      "reorder_qty": 90,
      "supplier": "Abay Grocers Supply",
      "unit_price": 102.0,
      "eta": "2 days",
      "urgency": "low"
    },
    {
      "product": "Rice 5kg",
      "current_stock": 44,
      "reorder_qty": 40,
      "supplier": "Ethio Grains PLC",
      "unit_price": 360.0,
      "eta": "2 days",
      "urgency": "stable"
    }
  ],
  "trusted_suppliers": [
    {
      "name": "Addis Wholesale Trading",
      "rating": 4.9,
      "speed": "Fast Delivery",
      "categories": "Oils, Grains, Beverages",
      "last_interaction": "2h ago",
      "verified": true,
      "avatar_color": "#1E88E5"
    }
  ],
  "orders": [
    {
      "id": "PO-2049",
      "supplier": "Addis Wholesale Trading",
      "product_count": 8,
      "amount": "ETB 64,300",
      "order_date": "May 10",
      "eta": "Today, 6:00 PM",
      "status": "in_transit"
    }
  ],
  "market_suppliers": [
    {
      "name": "Aster Retail Supply",
      "specialties": "Detergents, Soaps, Paper Goods",
      "start_price": "From ETB 78/unit",
      "region": "Addis Ababa",
      "delivery": "24h delivery",
      "rating": 4.6,
      "verified": true,
      "avatar_color": "#8E24AA"
    }
  ],
  "activities": [
    {
      "title": "Order PO-2048 delivered",
      "subtitle": "Addis Wholesale Trading completed delivery",
      "time": "18 min ago",
      "icon": "check_circle",
      "color": "#1B8F4D"
    }
  ],
  "category_chips": [
    "All Categories",
    "Grains",
    "Oils",
    "Beverages",
    "Packaging"
  ],
  "region_chips": [
    "All Regions",
    "Addis Ababa",
    "Oromia",
    "Amhara"
  ],
  "speed_chips": [
    "All Speeds",
    "Same Day",
    "Next Day",
    "2-3 Days"
  ],
  "rating_chips": [
    "All Ratings",
    "4.5+",
    "4.0+",
    "3.5+"
  ]
}
```

## Weekly Report Response
```json
{
  "points": [
    {
      "day_label": "Mon",
      "sales": 12340.0,
      "orders": 28
    },
    {
      "day_label": "Tue",
      "sales": 11020.0,
      "orders": 25
    },
    {
      "day_label": "Wed",
      "sales": 13210.0,
      "orders": 30
    },
    {
      "day_label": "Thu",
      "sales": 12540.0,
      "orders": 31
    },
    {
      "day_label": "Fri",
      "sales": 15960.0,
      "orders": 37
    },
    {
      "day_label": "Sat",
      "sales": 17220.0,
      "orders": 42
    },
    {
      "day_label": "Sun",
      "sales": 14180.0,
      "orders": 33
    }
  ],
  "generated_at": "2026-05-12T10:30:00Z",
  "growth_rate": 0.084
}
```

## Create Product Request
```json
{
  "name": "Organic Coffee 500g",
  "category": "Food",
  "price": 560.0,
  "stock": 25,
  "note": "Premium arabica coffee",
  "featured": true,
  "track_inventory": true,
  "discount_percent": 5.0,
  "reorder_level": 10,
  "image_file_name": "coffee.jpg",
  "image_base64": "iVBORw0KGgoAAAANSUhEUgAA..."
}
```

## Create Product Response
```json
{
  "id": "prod-new-001",
  "name": "Organic Coffee 500g",
  "image_url": "https://api.shop.com/images/coffee.jpg",
  "price": 560.0,
  "stock": 25,
  "message": "Product created successfully"
}
```

## Send Message Request
```json
{
  "text": "I'm interested in scaling the campaign next month. What's your availability?"
}
```

## Send Message Response
```json
{
  "id": "msg-new-001",
  "marketer_id": "alem-genet",
  "text": "I'm interested in scaling the campaign next month. What's your availability?",
  "from_marketer": false,
  "sent_at": "14:25",
  "message": "Message sent successfully"
}
```

## Create Contract Request
```json
{
  "marketer_id": "mimi-haile",
  "start_date": "2026-05-06T00:00:00Z",
  "end_date": "2026-07-05T00:00:00Z",
  "budget_total": 64000.0,
  "specialization": "Content Creator",
  "channel": "TikTok",
  "goals": ["Increase orders", "Build audience", "Improve conversion"]
}
```

## Create Contract Response
```json
{
  "id": "contract-mimi-2026-q3",
  "marketer_id": "mimi-haile",
  "status": "pending",
  "message": "Contract created successfully"
}
```

## Error Response Format
```json
{
  "error": "unauthorized",
  "message": "Invalid credentials. Try demo@shikela.com",
  "status_code": 401
}
```

## Pagination Example (for large datasets)
```json
{
  "data": [
    { /* item 1 */ },
    { /* item 2 */ }
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 150,
    "total_pages": 8,
    "has_more": true
  }
}
```

## Important Data Type Notes

1. **Currency Values:** All prices and amounts are decimals (double/number), NOT strings
   - Format in backend: `123.45` not `"123.45"`
   - Format for display: Convert to string with 2 decimal places

2. **IDs:** Use string format for all IDs
   - Marketing IDs follow pattern: `alem-genet`, `samuel-taye`
   - Contract IDs follow pattern: `contract-alem-2026-q2`
   - Product IDs follow pattern: `prod-001`

3. **Colors:** Use 6-digit hex format with # prefix
   - Example: `#1E88E5`
   - Used for avatar backgrounds

4. **Status Values:** Use snake_case strings
   - Contract status: `active`, `pending`, `expiring_soon`, `completed`, `cancelled`
   - Order status: `in_transit`, `preparing`, `accepted`
   - Urgency: `critical`, `low`, `stable`

5. **Percentages:** Use decimal values (0.0 to 1.0) or raw percentages
   - `campaign_progress`: 0.74 (represents 74%)
   - `conversion_rate`: 5.6 (represents 5.6%)
   - `trend_percent`: 7.4 (represents +7.4%)

6. **Dates & Times:** 
   - Full timestamps: ISO 8601 format (e.g., `2026-05-12T10:30:00Z`)
   - Time only: 24-hour format (e.g., `09:45`)
   - Relative time: Text format (e.g., `2h ago`, `Yesterday`)

7. **Numbers:**
   - Ratings: 1.0 to 5.0 (can be decimal)
   - Counts: Integers (orders, products)
   - Monetary: Decimals (prices, revenue)

---

## Field Mapping Reference

| Frontend Field | Backend Field | Type | Example |
|---|---|---|---|
| avatarColor | avatar_color | string | `#1E88E5` |
| badgeLabel | badge_label | string | `Top Performer` |
| campaignProgress | campaign_progress | number | 0.74 |
| conversionRate | conversion_rate | number | 5.6 |
| contractStatus | contract_status | string | `Active` |
| finalConversionRate | final_conversion_rate | number | 4.4 |
| finalStatus | final_status | string | `Completed` |
| lastMessage | last_message | string | Message text |
| marketerName | name | string | `Alem Genet` |
| marketerId | id | string | `alem-genet` |
| revenueGenerated | revenue_generated | string | `ETB 120,000` |
| sentAt | sent_at | string | `09:45` |
| specialization | specialization | string | Category |
| totalOrders | total_orders | number | 842 |
| totalRevenue | total_revenue | number | 187400.0 |
| unreadCount | unread_count | number | 2 |

---

## Validation Rules

- Hex colors must start with `#` and have 6 digits
- All ID strings must be non-empty and contain only alphanumeric and hyphens
- Ratings must be between 1.0 and 5.0
- Percentages/progress must be valid numbers
- Dates must be valid ISO 8601 format
- All required fields must be present (no null values)
- Stock counts must be non-negative integers

