import 'package:flutter/material.dart';

enum DashboardDrawerSectionId {
  pinnedShortcuts,
  businessManagement,
  marketing,
  teamAndStaff,
  smartTools,
  communication,
  growthPromotions,
  settingsAndAccount,
}

enum DashboardDrawerItemId {
  dashboard,
  products,
  orders,
  shop,
  analytics,
  settings,
  suppliers,
  customers,
  expenses,
  financialReports,
  salesReports,
  activityLogs,
  hireMarketers,
  activeCampaigns,
  previousCampaigns,
  contractsAndAgreements,
  campaignAnalytics,
  marketerPayments,
  employeeManagement,
  rolesPermissions,
  attendance,
  staffPerformance,
  aiInsights,
  restockSuggestions,
  lowStockAlerts,
  profitPredictions,
  trendingProducts,
  notifications,
  messages,
  announcements,
  supportCenter,
  couponsDiscounts,
  referralProgram,
  promotions,
  partnerPrograms,
  profileSettings,
  subscriptionVip,
  paymentMethods,
  language,
  darkMode,
  security,
  logout,
}

enum DashboardQuickActionId {
  addProduct,
  createInvoice,
  addExpense,
  startCampaign,
  addSupplier,
}

class DashboardDrawerItemData {
  const DashboardDrawerItemData({
    required this.id,
    required this.label,
    required this.icon,
    this.supportsPin = true,
    this.isDestructive = false,
  });

  final DashboardDrawerItemId id;
  final String label;
  final IconData icon;
  final bool supportsPin;
  final bool isDestructive;
}

class DashboardDrawerSectionData {
  const DashboardDrawerSectionData({
    required this.id,
    required this.title,
    required this.items,
  });

  final DashboardDrawerSectionId id;
  final String title;
  final List<DashboardDrawerItemData> items;
}

class DashboardQuickActionData {
  const DashboardQuickActionData({
    required this.id,
    required this.label,
    required this.icon,
  });

  final DashboardQuickActionId id;
  final String label;
  final IconData icon;
}
