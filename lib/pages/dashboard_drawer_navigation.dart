import 'package:flutter/material.dart';
import 'package:shop_manager/models/dashboard_drawer_models.dart';
import 'package:shop_manager/models/shop.dart';
import 'package:shop_manager/pages/add_marketer_contract_page.dart';
import 'package:shop_manager/pages/add_product_page.dart';
import 'package:shop_manager/pages/earnings_payouts_page.dart';
import 'package:shop_manager/pages/inventory_page.dart';
import 'package:shop_manager/pages/marketer_contracts_page.dart';
import 'package:shop_manager/pages/profile/edit_shop.dart';
import 'package:shop_manager/pages/profile/profile_page.dart';
import 'package:shop_manager/pages/welcome.dart';
import 'package:shop_manager/pages/suppliers_page.dart';
import 'package:shop_manager/services/auth_service.dart';
import 'package:shop_manager/services/shop_repository.dart';

Future<void> handleDashboardDrawerItemTap(
  BuildContext context,
  DashboardDrawerItemId item, {
  ValueChanged<bool>? onThemeChanged,
  bool isDarkMode = false,
}) async {
  switch (item) {
    case DashboardDrawerItemId.dashboard:
      // Drawer is opened from the dashboard/home screen itself —
      // just close the drawer and land back on it.
      Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
      return;
    case DashboardDrawerItemId.products:
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const InventoryPage()));
      return;
    case DashboardDrawerItemId.shop:
      await _openShopPage(context);
      return;
    case DashboardDrawerItemId.profileSettings:
    case DashboardDrawerItemId.settings:
    case DashboardDrawerItemId.paymentMethods:
    case DashboardDrawerItemId.language:
    case DashboardDrawerItemId.security:
      // These all live as sections inside ProfilePage — route there
      // instead of separate placeholder pages.
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ProfilePage(onThemeChanged: onThemeChanged),
        ),
      );
      return;
    case DashboardDrawerItemId.suppliers:
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const SuppliersPage()));
      return;
    case DashboardDrawerItemId.contractsAndAgreements:
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MarketerContractsPage()),
      );
      return;
    case DashboardDrawerItemId.financialReports:
    case DashboardDrawerItemId.marketerPayments:
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const EarningsPayoutsPage()),
      );
      return;
    case DashboardDrawerItemId.logout:
      await _logout(context, isDarkMode: isDarkMode, onThemeChanged: onThemeChanged);
      return;
      
    case DashboardDrawerItemId.subscriptionVip:
    case DashboardDrawerItemId.orders:
    case DashboardDrawerItemId.analytics:
    case DashboardDrawerItemId.hireMarketers:
    case DashboardDrawerItemId.campaignAnalytics:
    case DashboardDrawerItemId.salesReports:
    case DashboardDrawerItemId.lowStockAlerts:
    case DashboardDrawerItemId.restockSuggestions:
    case DashboardDrawerItemId.trendingProducts:
    case DashboardDrawerItemId.customers:
    case DashboardDrawerItemId.expenses:
    case DashboardDrawerItemId.activityLogs:
    case DashboardDrawerItemId.activeCampaigns:
    case DashboardDrawerItemId.previousCampaigns:
    case DashboardDrawerItemId.employeeManagement:
    case DashboardDrawerItemId.rolesPermissions:
    case DashboardDrawerItemId.attendance:
    case DashboardDrawerItemId.staffPerformance:
    case DashboardDrawerItemId.aiInsights:
    case DashboardDrawerItemId.profitPredictions:
    case DashboardDrawerItemId.notifications:
    case DashboardDrawerItemId.messages:
    case DashboardDrawerItemId.announcements:
    case DashboardDrawerItemId.supportCenter:
    case DashboardDrawerItemId.couponsDiscounts:
    case DashboardDrawerItemId.referralProgram:
    case DashboardDrawerItemId.promotions:
    case DashboardDrawerItemId.partnerPrograms:
    case DashboardDrawerItemId.darkMode:
      _showComingSoon(context, item);
      return;
  }
}

Future<void> handleDashboardQuickActionTap(
  BuildContext context,
  DashboardQuickActionId action,
) async {
  switch (action) {
    case DashboardQuickActionId.addProduct:
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const AddProductPage()));
      return;
    case DashboardQuickActionId.startCampaign:
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const AddMarketerContractPage(),
        ),
      );
      return;
    case DashboardQuickActionId.createInvoice:
    case DashboardQuickActionId.addExpense:
    case DashboardQuickActionId.addSupplier:
      _showQuickActionSnack(context, action);
      return;
  }
}

Future<void> _openShopPage(BuildContext context) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final BackendShopRepository repo = BackendShopRepository();
    final Shop shop = await repo.fetchMyShop();

    if (!context.mounted) return;
    Navigator.of(context).pop(); // close loading dialog

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditShopPage(shop: shop)),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop(); // close loading dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load shop: $e')),
    );
  }
}

Future<void> _logout(
  BuildContext context, {
  required bool isDarkMode,
  required ValueChanged<bool>? onThemeChanged,
}) async {
  AuthSessionStore.clear();

  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => WelcomePage(
        isDarkMode: isDarkMode,
        onThemeChanged: onThemeChanged ?? (bool _) {},
      ),
    ),
    (Route<dynamic> route) => false,
  );
}

void _showComingSoon(BuildContext context, DashboardDrawerItemId item) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${_itemLabel(item)} is ready for integration.'),
      duration: const Duration(seconds: 2),
    ),
  );
}

void _showQuickActionSnack(
  BuildContext context,
  DashboardQuickActionId action,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('${_quickLabel(action)} action triggered.'),
      duration: const Duration(seconds: 2),
    ),
  );
}

String _itemLabel(DashboardDrawerItemId item) {
  switch (item) {
    case DashboardDrawerItemId.dashboard:
      return 'Dashboard';
    case DashboardDrawerItemId.products:
      return 'Products';
    case DashboardDrawerItemId.orders:
      return 'Orders';
    case DashboardDrawerItemId.shop:
      return 'Shop';
    case DashboardDrawerItemId.analytics:
      return 'Analytics';
    case DashboardDrawerItemId.settings:
      return 'Settings';
    case DashboardDrawerItemId.suppliers:
      return 'Suppliers';
    case DashboardDrawerItemId.customers:
      return 'Customers';
    case DashboardDrawerItemId.expenses:
      return 'Expenses';
    case DashboardDrawerItemId.financialReports:
      return 'Financial reports';
    case DashboardDrawerItemId.salesReports:
      return 'Sales reports';
    case DashboardDrawerItemId.activityLogs:
      return 'Activity logs';
    case DashboardDrawerItemId.hireMarketers:
      return 'Hire marketers';
    case DashboardDrawerItemId.activeCampaigns:
      return 'Active campaigns';
    case DashboardDrawerItemId.previousCampaigns:
      return 'Previous campaigns';
    case DashboardDrawerItemId.contractsAndAgreements:
      return 'Contracts & agreements';
    case DashboardDrawerItemId.campaignAnalytics:
      return 'Campaign analytics';
    case DashboardDrawerItemId.marketerPayments:
      return 'Marketer payments';
    case DashboardDrawerItemId.employeeManagement:
      return 'Employee management';
    case DashboardDrawerItemId.rolesPermissions:
      return 'Roles & permissions';
    case DashboardDrawerItemId.attendance:
      return 'Attendance';
    case DashboardDrawerItemId.staffPerformance:
      return 'Staff performance';
    case DashboardDrawerItemId.aiInsights:
      return 'AI insights';
    case DashboardDrawerItemId.restockSuggestions:
      return 'Restock suggestions';
    case DashboardDrawerItemId.lowStockAlerts:
      return 'Low stock alerts';
    case DashboardDrawerItemId.profitPredictions:
      return 'Profit predictions';
    case DashboardDrawerItemId.trendingProducts:
      return 'Trending products';
    case DashboardDrawerItemId.notifications:
      return 'Notifications';
    case DashboardDrawerItemId.messages:
      return 'Messages';
    case DashboardDrawerItemId.announcements:
      return 'Announcements';
    case DashboardDrawerItemId.supportCenter:
      return 'Support center';
    case DashboardDrawerItemId.couponsDiscounts:
      return 'Coupons & discounts';
    case DashboardDrawerItemId.referralProgram:
      return 'Referral program';
    case DashboardDrawerItemId.promotions:
      return 'Promotions';
    case DashboardDrawerItemId.partnerPrograms:
      return 'Partner programs';
    case DashboardDrawerItemId.profileSettings:
      return 'Profile settings';
    case DashboardDrawerItemId.subscriptionVip:
      return 'Subscription / VIP';
    case DashboardDrawerItemId.paymentMethods:
      return 'Payment methods';
    case DashboardDrawerItemId.language:
      return 'Language';
    case DashboardDrawerItemId.darkMode:
      return 'Dark mode';
    case DashboardDrawerItemId.security:
      return 'Security';
    case DashboardDrawerItemId.logout:
      return 'Logout';
  }
}

String _quickLabel(DashboardQuickActionId action) {
  switch (action) {
    case DashboardQuickActionId.addProduct:
      return 'Add product';
    case DashboardQuickActionId.createInvoice:
      return 'Create invoice';
    case DashboardQuickActionId.addExpense:
      return 'Add expense';
    case DashboardQuickActionId.startCampaign:
      return 'Start campaign';
    case DashboardQuickActionId.addSupplier:
      return 'Add supplier';
  }
}