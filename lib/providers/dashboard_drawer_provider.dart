import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/dashboard_drawer_models.dart';

class DashboardDrawerState {
  const DashboardDrawerState({
    required this.expandedSections,
    required this.pinnedItems,
    required this.selectedItem,
    required this.badges,
  });

  final Set<DashboardDrawerSectionId> expandedSections;
  final Set<DashboardDrawerItemId> pinnedItems;
  final DashboardDrawerItemId? selectedItem;
  final Map<DashboardDrawerItemId, int> badges;

  DashboardDrawerState copyWith({
    Set<DashboardDrawerSectionId>? expandedSections,
    Set<DashboardDrawerItemId>? pinnedItems,
    DashboardDrawerItemId? selectedItem,
    bool clearSelection = false,
    Map<DashboardDrawerItemId, int>? badges,
  }) {
    return DashboardDrawerState(
      expandedSections: expandedSections ?? this.expandedSections,
      pinnedItems: pinnedItems ?? this.pinnedItems,
      selectedItem: clearSelection ? null : (selectedItem ?? this.selectedItem),
      badges: badges ?? this.badges,
    );
  }
}

class DashboardDrawerController extends StateNotifier<DashboardDrawerState> {
  DashboardDrawerController()
      : super(
          const DashboardDrawerState(
            expandedSections: <DashboardDrawerSectionId>{
              DashboardDrawerSectionId.businessManagement,
              DashboardDrawerSectionId.settingsAndAccount,
            },
            pinnedItems: <DashboardDrawerItemId>{
              DashboardDrawerItemId.products,
              DashboardDrawerItemId.analytics,
              DashboardDrawerItemId.profileSettings,
            },
            selectedItem: DashboardDrawerItemId.dashboard,
            badges: <DashboardDrawerItemId, int>{
              DashboardDrawerItemId.orders: 3,
              DashboardDrawerItemId.customers: 2,
            },
          ),
        );

  void toggleSection(DashboardDrawerSectionId id) {
    final Set<DashboardDrawerSectionId> next = Set<DashboardDrawerSectionId>.from(state.expandedSections);
    if (!next.add(id)) {
      next.remove(id);
    }
    state = state.copyWith(expandedSections: next);
  }

  void togglePin(DashboardDrawerItemId id) {
    final Set<DashboardDrawerItemId> next = Set<DashboardDrawerItemId>.from(state.pinnedItems);
    if (!next.add(id)) {
      next.remove(id);
    }
    state = state.copyWith(pinnedItems: next);
  }

  void selectItem(DashboardDrawerItemId id) {
    final Map<DashboardDrawerItemId, int> badges = Map<DashboardDrawerItemId, int>.from(state.badges);
    final int? currentBadge = badges[id];
    if (currentBadge != null && currentBadge > 0) {
      badges[id] = math.max(0, currentBadge - 1);
      if (badges[id] == 0) {
        badges.remove(id);
      }
    }
    state = state.copyWith(selectedItem: id, badges: badges);
  }

  void setBadge(DashboardDrawerItemId id, int count) {
    final Map<DashboardDrawerItemId, int> badges = Map<DashboardDrawerItemId, int>.from(state.badges);
    if (count <= 0) {
      badges.remove(id);
    } else {
      badges[id] = count;
    }
    state = state.copyWith(badges: badges);
  }
}

final StateNotifierProvider<DashboardDrawerController, DashboardDrawerState> dashboardDrawerProvider =
    StateNotifierProvider<DashboardDrawerController, DashboardDrawerState>(
  (StateNotifierProviderRef<DashboardDrawerController, DashboardDrawerState> ref) {
    return DashboardDrawerController();
  },
);
