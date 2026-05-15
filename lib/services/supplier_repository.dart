import 'package:shop_manager/models/supplier_models.dart';

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
  const BackendSupplierRepository();

  @override
  Future<SupplierDashboardData> fetchDashboard() {
    throw UnimplementedError(
      'Connect BackendSupplierRepository.fetchDashboard to your API endpoint.',
    );
  }
}
