import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/dashboard_drawer_models.dart';
import 'package:shop_manager/models/product.dart';
import 'package:shop_manager/pages/dashboard_drawer_navigation.dart';
import 'package:shop_manager/pages/product_detail_page.dart';
import 'package:shop_manager/pages/suppliers_page.dart';
import 'package:shop_manager/providers/product_providers.dart';
import 'package:shop_manager/theme/app_themes.dart';
import 'package:shop_manager/widgets/shop_owner_dashboard_drawer.dart';

class InventoryPage extends ConsumerWidget {
  const InventoryPage({
    super.key,
    this.isDarkMode = false,
    this.onThemeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool>? onThemeChanged;

  Color _stockColor(int stock) {
    if (stock <= 0) {
      return Colors.redAccent;
    }
    if (stock <= 5) {
      return Colors.orange.shade700;
    }
    return Colors.green.shade700;
  }

  String _stockLabel(int stock) {
    if (stock <= 0) {
      return 'Out of stock';
    }
    if (stock <= 5) {
      return 'Low stock';
    }
    return 'In stock';
  }

  String _formatInteger(int value) {
    final String raw = value.abs().toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final int indexFromEnd = raw.length - i;
      buffer.write(raw[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return value < 0 ? '-${buffer.toString()}' : buffer.toString();
  }

  String _formatCurrency(double value) {
    final String fixed = value.abs().toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final int whole = int.tryParse(parts.first) ?? 0;
    final String formattedWhole = _formatInteger(whole);
    final String sign = value < 0 ? '-' : '';
    return 'ETB $sign$formattedWhole.${parts.last}';
  }

  Widget _summaryCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.poppins(
                    context,
                    fontSize: 10,
                    color: scheme.onSurface.withOpacity(0.66),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.poppins(
                    context,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(BuildContext context, Product product) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color stockColor = _stockColor(product.stock);
    final String stockLabel = _stockLabel(product.stock);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailPage(product: product),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary.withOpacity(0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: double.infinity,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                        return Container(
                          color: scheme.primary.withOpacity(0.08),
                          child: Icon(Icons.image_not_supported_outlined, color: scheme.primary),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppThemes.poppins(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatCurrency(product.price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppThemes.poppins(
                  context,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.secondary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${product.stock} units',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemes.poppins(
                        context,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: stockColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: stockColor.withOpacity(0.34)),
                    ),
                    child: Text(
                      stockLabel,
                      style: AppThemes.poppins(
                        context,
                        fontSize: 9,
                        color: stockColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.primary.withOpacity(0.14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: scheme.primary, size: 30),
            const SizedBox(height: 8),
            Text(
              'Could not load inventory.',
              style: AppThemes.poppins(
                context,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => ref.invalidate(productsProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(productsProvider);
  }

  void _openSuppliers(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SuppliersPage()),
    );
  }

  Widget _supplierShortcutCard(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openSuppliers(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary.withOpacity(0.16)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                scheme.primary.withOpacity(0.12),
                scheme.primary.withOpacity(0.04),
              ],
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: scheme.primary.withOpacity(0.16)),
                ),
                child: Icon(Icons.local_shipping_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Suppliers',
                      style: AppThemes.poppins(
                        context,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Open supplier list and contact details',
                      style: AppThemes.poppins(
                        context,
                        fontSize: 11,
                        color: scheme.onSurface.withOpacity(0.68),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context, WidgetRef ref) {
    return ShopOwnerDashboardDrawer(
      isDarkMode: isDarkMode,
      onThemeChanged: onThemeChanged,
      shopName: 'Shikela Shop',
      ownerName: 'Henon Manager',
      businessStatus: 'Business Active',
      subscriptionLabel: 'VIP Pro',
      onClose: () => Navigator.of(context).pop(),
      onMenuItemSelected: (DashboardDrawerItemId itemId) {
        Navigator.of(context).pop();
        handleDashboardDrawerItemTap(context, itemId);
      },
      onQuickActionSelected: (DashboardQuickActionId quickActionId) {
        Navigator.of(context).pop();
        if (quickActionId == DashboardQuickActionId.addSupplier) {
          ref.invalidate(productsProvider);
        }
        handleDashboardQuickActionTap(context, quickActionId);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark ? const Color(0xFF172026) : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;
    final AsyncValue<List<Product>> productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: bgBottom,
      endDrawer: _buildSideMenu(context, ref),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[bgTop, bgBottom, bgBottom],
            stops: const <double>[0.0, 0.22, 1.0],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Inventory',
                        style: AppThemes.poppins(
                          context,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.invalidate(productsProvider),
                      icon: Icon(Icons.refresh_rounded, color: scheme.primary),
                    ),
                    Builder(
                      builder: (BuildContext innerContext) {
                        return Container(
                          decoration: BoxDecoration(
                            color: scheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            tooltip: 'Open menu',
                            onPressed: () => Scaffold.of(innerContext).openEndDrawer(),
                            icon: Icon(Icons.tune_rounded, color: scheme.primary),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Text(
                  'Track products, stock health, and inventory value.',
                  style: AppThemes.poppins(
                    context,
                    fontSize: 13,
                    color: scheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                _supplierShortcutCard(context),
                const SizedBox(height: 12),
                  Expanded(
                    child: productsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (Object error, StackTrace stackTrace) => _errorState(context, ref),
                    data: (List<Product> products) {
                      if (products.isEmpty) {
                        return Center(
                          child: Text(
                            'No products in inventory yet.',
                            style: AppThemes.poppins(
                              context,
                              fontSize: 13,
                              color: scheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }

                      final int totalUnits = products.fold<int>(
                        0,
                        (int sum, Product product) => sum + product.stock,
                      );
                      final int lowStockCount = products
                          .where((Product product) => product.stock > 0 && product.stock <= 5)
                          .length;
                      final int outOfStockCount = products
                          .where((Product product) => product.stock <= 0)
                          .length;
                      final double stockValue = products.fold<double>(
                        0,
                        (double sum, Product product) => sum + (product.price * product.stock),
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: scheme.primary.withOpacity(0.14)),
                            ),
                            child: Text(
                              'Total inventory value: ${_formatCurrency(stockValue)}',
                              style: AppThemes.poppins(
                                context,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: CustomScrollView(
                              slivers: [
                                SliverToBoxAdapter(
                                  child: GridView.count(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 2.25,
                                    children: [
                                      _summaryCard(
                                        context,
                                        label: 'Products',
                                        value: '${products.length}',
                                        icon: Icons.category_rounded,
                                      ),
                                      _summaryCard(
                                        context,
                                        label: 'Units in stock',
                                        value: '$totalUnits',
                                        icon: Icons.inventory_2_rounded,
                                      ),
                                      _summaryCard(
                                        context,
                                        label: 'Low stock items',
                                        value: '$lowStockCount',
                                        icon: Icons.warning_amber_rounded,
                                      ),
                                      _summaryCard(
                                        context,
                                        label: 'Out of stock',
                                        value: '$outOfStockCount',
                                        icon: Icons.error_outline_rounded,
                                      ),
                                    ],
                                  ),
                                ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 12),
                                ),
                                SliverGrid(
                                  delegate: SliverChildBuilderDelegate(
                                    (BuildContext context, int index) {
                                      return _productCard(context, products[index]);
                                    },
                                    childCount: products.length,
                                  ),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 0.70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
