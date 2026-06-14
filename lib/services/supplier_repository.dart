import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shop_manager/models/supplier_models.dart';
import 'package:shop_manager/services/api_config.dart';
import 'package:shop_manager/services/auth_service.dart';

abstract class SupplierRepository {
  Future<SupplierDashboardData> fetchDashboard();
}

class MockSupplierRepository implements SupplierRepository {
  const MockSupplierRepository();

  @override
  Future<SupplierDashboardData> fetchDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 620));
    return const SupplierDashboardData(
      quickStats: <SupplierQuickStat>[
        SupplierQuickStat(label: 'Total Suppliers', value: '42', icon: 'groups', trend: '+8%'),
        SupplierQuickStat(label: 'Active Orders', value: '17', icon: 'shopping_bag', trend: '+3 today'),
        SupplierQuickStat(label: 'Pending Deliveries', value: '9', icon: 'local_shipping', trend: '-2 late'),
        SupplierQuickStat(label: 'Favorite Suppliers', value: '11', icon: 'favorite', trend: '+2 week'),
        SupplierQuickStat(label: 'Low Stock Products', value: '13', icon: 'warning', trend: '4 critical'),
        SupplierQuickStat(label: 'Monthly Purchases', value: 'ETB 248K', icon: 'payments', trend: '+12%'),
      ],
      reorderSuggestions: <SupplierReorderSuggestion>[
        SupplierReorderSuggestion(
          product: 'Cooking Oil 1L',
          currentStock: 6,
          reorderQty: 120,
          supplier: 'Addis Wholesale Trading',
          unitPrice: 145,
          eta: '1 day',
          urgency: 'critical',
        ),
        SupplierReorderSuggestion(
          product: 'Sugar 2kg',
          currentStock: 14,
          reorderQty: 90,
          supplier: 'Abay Grocers Supply',
          unitPrice: 102,
          eta: '2 days',
          urgency: 'low',
        ),
        SupplierReorderSuggestion(
          product: 'Rice 5kg',
          currentStock: 44,
          reorderQty: 40,
          supplier: 'Ethio Grains PLC',
          unitPrice: 360,
          eta: '2 days',
          urgency: 'stable',
        ),
      ],
      trustedSuppliers: <SupplierTrustedItem>[
        SupplierTrustedItem(
          name: 'Addis Wholesale Trading',
          rating: 4.9,
          speed: 'Fast Delivery',
          categories: 'Oils, Grains, Beverages',
          lastInteraction: '2h ago',
          verified: true,
          avatarColor: '#1E88E5',
        ),
        SupplierTrustedItem(
          name: 'Nile Packaging Hub',
          rating: 4.7,
          speed: 'Next Day',
          categories: 'Packaging, Labels',
          lastInteraction: 'Yesterday',
          verified: true,
          avatarColor: '#43A047',
        ),
        SupplierTrustedItem(
          name: 'Selam Fresh Produce',
          rating: 4.8,
          speed: 'Same Day',
          categories: 'Vegetables, Fruits',
          lastInteraction: '3d ago',
          verified: false,
          avatarColor: '#F4511E',
        ),
      ],
      orders: <SupplierOrder>[
        SupplierOrder(
          id: 'PO-2049',
          supplier: 'Addis Wholesale Trading',
          productCount: 8,
          amount: 'ETB 64,300',
          orderDate: 'May 10',
          eta: 'Today, 6:00 PM',
          status: 'in_transit',
        ),
        SupplierOrder(
          id: 'PO-2050',
          supplier: 'Nile Packaging Hub',
          productCount: 5,
          amount: 'ETB 18,900',
          orderDate: 'May 9',
          eta: 'Tomorrow, 11:00 AM',
          status: 'preparing',
        ),
        SupplierOrder(
          id: 'PO-2051',
          supplier: 'Selam Fresh Produce',
          productCount: 12,
          amount: 'ETB 22,100',
          orderDate: 'May 11',
          eta: 'May 13',
          status: 'accepted',
        ),
      ],
      marketSuppliers: <SupplierMarketItem>[
        SupplierMarketItem(
          name: 'Aster Retail Supply',
          specialties: 'Detergents, Soaps, Paper Goods',
          startPrice: 'From ETB 78/unit',
          region: 'Addis Ababa',
          delivery: '24h delivery',
          rating: 4.6,
          verified: true,
          avatarColor: '#8E24AA',
        ),
        SupplierMarketItem(
          name: 'Blue River Foods',
          specialties: 'Dry Foods, Canned Goods',
          startPrice: 'From ETB 91/unit',
          region: 'Oromia',
          delivery: '48h delivery',
          rating: 4.5,
          verified: true,
          avatarColor: '#1565C0',
        ),
        SupplierMarketItem(
          name: 'Green Basket Traders',
          specialties: 'Fresh Produce, Organics',
          startPrice: 'From ETB 64/unit',
          region: 'Amhara',
          delivery: '72h delivery',
          rating: 4.4,
          verified: false,
          avatarColor: '#2E7D32',
        ),
      ],
      activities: <SupplierActivityItem>[
        SupplierActivityItem(
          title: 'Order PO-2048 delivered',
          subtitle: 'Addis Wholesale Trading completed delivery',
          time: '18 min ago',
          icon: 'check_circle',
          color: '#1B8F4D',
        ),
        SupplierActivityItem(
          title: 'New supplier added',
          subtitle: 'Aster Retail Supply joined trusted list',
          time: '1h ago',
          icon: 'person_add',
          color: '#1565C0',
        ),
        SupplierActivityItem(
          title: 'Payment completed',
          subtitle: 'ETB 42,800 paid to Nile Packaging Hub',
          time: '3h ago',
          icon: 'payments',
          color: '#6A1B9A',
        ),
        SupplierActivityItem(
          title: 'Restock alert',
          subtitle: 'Cooking Oil 1L below threshold',
          time: '5h ago',
          icon: 'warning',
          color: '#EF6C00',
        ),
        SupplierActivityItem(
          title: 'Supplier message',
          subtitle: 'Blue River Foods shared new price list',
          time: 'Yesterday',
          icon: 'chat',
          color: '#3949AB',
        ),
      ],
      categoryChips: <String>['All Categories', 'Groceries', 'Packaging', 'Produce'],
      regionChips: <String>['All Regions', 'Addis Ababa', 'Oromia', 'Amhara'],
      speedChips: <String>['Any Speed', '24h', '48h', '72h'],
      ratingChips: <String>['Any Rating', '4.8+', '4.5+', '4.0+'],
    );
  }
}

class BackendSupplierRepository implements SupplierRepository {
  BackendSupplierRepository({
    String? baseUrl,
    this.client,
  }) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final String baseUrl;
  final http.Client? client;

  @override
  Future<SupplierDashboardData> fetchDashboard() async {
    final http.Client activeClient = client ?? http.Client();
    try {
      final String? token = AuthSessionStore.token;
      if (token == null) {
        throw Exception('Not authenticated. Please login first.');
      }

      final http.Response response = await activeClient
          .get(
            _endpoint('/supliers/'),
            headers: <String, String>{
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to fetch dashboard: ${response.statusCode}');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      return SupplierDashboardData(
        quickStats: _parseQuickStats(data['quick_stats'] ?? []),
        reorderSuggestions: _parseReorderSuggestions(data['reorder_suggestions'] ?? []),
        trustedSuppliers: _parseTrustedSuppliers(data['trusted_suppliers'] ?? []),
        orders: _parseOrders(data['orders'] ?? []),
        marketSuppliers: _parseMarketSuppliers(data['market_suppliers'] ?? []),
        activities: _parseActivities(data['activities'] ?? []),
        categoryChips: List<String>.from(data['category_chips'] as List? ?? []),
        regionChips: List<String>.from(data['region_chips'] as List? ?? []),
        speedChips: List<String>.from(data['speed_chips'] as List? ?? []),
        ratingChips: List<String>.from(data['rating_chips'] as List? ?? []),
      );
    } catch (e) {
      rethrow;
    } finally {
      if (client == null) {
        activeClient.close();
      }
    }
  }

  Uri _endpoint(String path) {
    final String normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBaseUrl$path');
  }

  List<SupplierQuickStat> _parseQuickStats(List<dynamic> data) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> stat) => SupplierQuickStat(
              label: stat['label']?.toString() ?? '',
              value: stat['value']?.toString() ?? '',
              icon: stat['icon']?.toString() ?? '',
              trend: stat['trend']?.toString() ?? '',
            ))
        .toList();
  }

  List<SupplierReorderSuggestion> _parseReorderSuggestions(List<dynamic> data) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> sugg) => SupplierReorderSuggestion(
              product: sugg['product']?.toString() ?? '',
              currentStock: sugg['current_stock'] as int? ?? 0,
              reorderQty: sugg['reorder_qty'] as int? ?? 0,
              supplier: sugg['supplier']?.toString() ?? '',
              unitPrice: (sugg['unit_price'] as num?)?.toDouble() ?? 0.0,
              eta: sugg['eta']?.toString() ?? '',
              urgency: sugg['urgency']?.toString() ?? '',
            ))
        .toList();
  }

  List<SupplierTrustedItem> _parseTrustedSuppliers(List<dynamic> data) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> item) => SupplierTrustedItem(
              name: item['name']?.toString() ?? '',
              rating: (item['rating'] as num?)?.toDouble() ?? 0,
              speed: item['speed']?.toString() ?? '',
              categories: item['categories']?.toString() ?? '',
              lastInteraction: item['last_interaction']?.toString() ?? '',
              verified: item['verified'] as bool? ?? false,
              avatarColor: item['avatar_color']?.toString() ?? '#1E88E5',
            ))
        .toList();
  }

  List<SupplierOrder> _parseOrders(List<dynamic> data) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> order) => SupplierOrder(
              id: order['id']?.toString() ?? '',
              supplier: order['supplier']?.toString() ?? '',
              productCount: order['product_count'] as int? ?? 0,
              amount: order['amount']?.toString() ?? '',
              orderDate: order['order_date']?.toString() ?? '',
              eta: order['eta']?.toString() ?? '',
              status: order['status']?.toString() ?? '',
            ))
        .toList();
  }

  List<SupplierMarketItem> _parseMarketSuppliers(List<dynamic> data) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> item) => SupplierMarketItem(
              name: item['name']?.toString() ?? '',
              specialties: item['specialties']?.toString() ?? '',
              startPrice: item['start_price']?.toString() ?? '',
              region: item['region']?.toString() ?? '',
              delivery: item['delivery']?.toString() ?? '',
              rating: (item['rating'] as num?)?.toDouble() ?? 0,
              verified: item['verified'] as bool? ?? false,
              avatarColor: item['avatar_color']?.toString() ?? '#1E88E5',
            ))
        .toList();
  }

  List<SupplierActivityItem> _parseActivities(List<dynamic> data) {
    return data
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> activity) => SupplierActivityItem(
              title: activity['title']?.toString() ?? '',
              subtitle: activity['subtitle']?.toString() ?? '',
              time: activity['time']?.toString() ?? '',
              icon: activity['icon']?.toString() ?? '',
              color: activity['color']?.toString() ?? '',
            ))
        .toList();
  }
}
