import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/models/supplier_models.dart';
import 'package:shop_manager/providers/supplier_providers.dart';
import 'package:shop_manager/theme/app_themes.dart';
import 'package:shop_manager/models/product.dart';
import 'package:shop_manager/services/product_repository.dart';
class SuppliersPage extends ConsumerWidget {
  const SuppliersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark
        ? const Color(0xFF172026)
        : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;
    final AsyncValue<SupplierDashboardData> dashboardAsync = ref.watch(
      supplierDashboardProvider,
    );

    return Scaffold(
      backgroundColor: bgBottom,
      appBar: AppBar(
        backgroundColor: bgTop,
        surfaceTintColor: Colors.transparent,
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            tooltip: 'Refresh suppliers',
            onPressed: () => ref.invalidate(supplierDashboardProvider),
            icon: Icon(Icons.refresh_rounded, color: scheme.primary),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[bgTop, bgBottom, bgBottom],
            stops: const <double>[0.0, 0.22, 1.0],
          ),
        ),
        child: dashboardAsync.when(
          loading: () => const _SupplierLoadingView(),
          error: (Object error, StackTrace stackTrace) {
            return _SupplierErrorView(
              onRetry: () => ref.invalidate(supplierDashboardProvider),
            );
          },
          data: (SupplierDashboardData data) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(supplierDashboardProvider);
                await ref.read(supplierDashboardProvider.future);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  _SupplierOverviewCard(data: data),
                  const SizedBox(height: 20),
                  
                  _SectionHeader(
                    title: 'All Suppliers',
                    actionLabel:
                        '${data.trustedSuppliers.length + data.marketSuppliers.length} listed',
                  ),
                  const SizedBox(height: 10),
                  ...data.trustedSuppliers.map((SupplierTrustedItem supplier) {
                    return _TrustedSupplierTile(
                      supplier: supplier,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SupplierDetailPage(
                              supplier: supplier,
                              orders: _ordersForSupplier(
                                data.orders,
                                supplier.name,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  ...data.marketSuppliers.map((SupplierMarketItem supplier) {
                    return _MarketSupplierTile(
                      supplier: supplier,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SupplierDetailPage(
                              marketSupplier: supplier,
                              orders: _ordersForSupplier(
                                data.orders,
                                supplier.name,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 10),
                  _SectionHeader(
                    title: 'Purchase Orders',
                    actionLabel: '${data.orders.length} open',
                  ),
                  const SizedBox(height: 10),
                  ...data.orders.map((SupplierOrder order) {
                    return _SupplierOrderTile(
                      order: order,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                SupplierOrderDetailPage(order: order),
                          ),
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 10),
                  _SectionHeader(
                    title: 'Recent Activity',
                    actionLabel: '${data.activities.length} updates',
                  ),
                  const SizedBox(height: 10),
                  ...data.activities.map((SupplierActivityItem activity) {
                    return _SupplierActivityTile(activity: activity);
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SupplierOverviewCard extends StatelessWidget {
  const _SupplierOverviewCard({required this.data});

  final SupplierDashboardData data;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedTextColor = _mutedTextColor(context);
    final Color topCardStart = Color.alphaBlend(
      scheme.primary.withOpacity(isDark ? 0.18 : 0.12),
      scheme.surface,
    );
    final Color topCardEnd = Color.alphaBlend(
      scheme.secondary.withOpacity(isDark ? 0.10 : 0.08),
      scheme.surface,
    );
    final Color topCardBorder = scheme.primary.withOpacity(
      isDark ? 0.24 : 0.18,
    );
    final Color topCardShadow = scheme.primary.withOpacity(
      isDark ? 0.08 : 0.06,
    );
    

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [topCardStart, topCardEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: topCardBorder),
        boxShadow: [
          BoxShadow(
            color: topCardShadow,
            blurRadius: 18,
            spreadRadius: 0.2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_shipping_rounded,
                  size: 20,
                  color: scheme.onPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Supplier Dashboard',
                  style: AppThemes.poppins(
                    context,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _TrendBadge(
                label: _statValue(data, 'Monthly Purchases', 'trend'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statValue(data, 'Monthly Purchases', 'value'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemes.poppins(
                        context,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Purchasing pipeline this month',
                      style: AppThemes.poppins(
                        context,
                        fontSize: 13,
                        color: mutedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  label: 'Suppliers',
                  value: _statValue(data, 'Total Suppliers', 'value'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricChip(
                  label: 'Active Orders',
                  value: _statValue(data, 'Active Orders', 'value'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricChip(
                  label: 'Pending Delivery',
                  value: _statValue(data, 'Pending Deliveries', 'value'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricChip(
                  label: 'Low Stock',
                  value: _statValue(data, 'Low Stock Products', 'value'),
                ),
              ),
            ],
          ),
          
        ],
      ),
    );
  }





}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actionLabel});

  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final Color mutedTextColor = _mutedTextColor(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppThemes.poppins(
              context,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          actionLabel,
          style: AppThemes.poppins(
            context,
            fontSize: 12,
            color: mutedTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color mutedTextColor = _mutedTextColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.poppins(
              context,
              fontSize: 11,
              color: mutedTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.poppins(
              context,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final Color mutedTextColor = _mutedTextColor(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            title,
            style: AppThemes.poppins(
              context,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: mutedTextColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppThemes.poppins(
                context,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final bool isNegative = label.trim().startsWith('-');
    final Color color = isNegative ? Colors.redAccent : Colors.green.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label.isEmpty ? 'Live' : label,
        style: AppThemes.poppins(
          context,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// 

class _TrustedSupplierTile extends StatelessWidget {
  const _TrustedSupplierTile({required this.supplier, required this.onTap});

  final SupplierTrustedItem supplier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color mutedTextColor = _mutedTextColor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary.withOpacity(0.14)),
          ),
          child: Row(
            children: [
              _Avatar(
                label: supplier.name,
                color: _colorFromHex(supplier.avatarColor, scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            supplier.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppThemes.poppins(
                              context,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (supplier.verified)
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: scheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      supplier.categories,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemes.poppins(
                        context,
                        fontSize: 12,
                        color: mutedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          supplier.rating.toStringAsFixed(1),
                          style: AppThemes.poppins(
                            context,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            '${supplier.speed} - ${supplier.lastInteraction}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppThemes.poppins(
                              context,
                              fontSize: 11,
                              color: mutedTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarketSupplierTile extends StatelessWidget {
  const _MarketSupplierTile({required this.supplier, required this.onTap});

  final SupplierMarketItem supplier;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color mutedTextColor = _mutedTextColor(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary.withOpacity(0.14)),
          ),
          child: Row(
            children: [
              _Avatar(
                label: supplier.name,
                color: _colorFromHex(supplier.avatarColor, scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            supplier.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppThemes.poppins(
                              context,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (supplier.verified)
                          Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: scheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      supplier.specialties,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppThemes.poppins(
                        context,
                        fontSize: 12,
                        color: mutedTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          supplier.rating.toStringAsFixed(1),
                          style: AppThemes.poppins(
                            context,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            '${supplier.region} - ${supplier.delivery}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppThemes.poppins(
                              context,
                              fontSize: 11,
                              color: mutedTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: mutedTextColor),
            ],
          ),
        ),
      ),
    );
  }
}
class SupplierDetailPage extends ConsumerStatefulWidget {
  const SupplierDetailPage({
    super.key,
    this.supplier,
    this.marketSupplier,
    this.orders = const <SupplierOrder>[],
  }) : assert(supplier != null || marketSupplier != null);

  final SupplierTrustedItem? supplier;
  final SupplierMarketItem? marketSupplier;
  final List<SupplierOrder> orders;

  @override
  ConsumerState<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends ConsumerState<SupplierDetailPage> {
  late Future<List<Product>> _productsFuture;
  final Set<String> _importingProductIds = <String>{};

  String get _supplierId => widget.supplier?.id ?? widget.marketSupplier?.id ?? '';

  @override
  void initState() {
    super.initState();
    _productsFuture = BackendProductRepository().fetchSupplierProducts(_supplierId);
  }

  void _reload() {
    setState(() {
      _productsFuture = BackendProductRepository().fetchSupplierProducts(_supplierId);
    });
  }

  Future<void> _importProduct(Product product) async {
    final double? price = await _askImportPrice(product);
    if (price == null) return; // user cancelled

    setState(() => _importingProductIds.add(product.id));
    try {
      await BackendProductRepository().importSupplierProduct(product.id, price: price);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${product.name}" imported to your shop.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _importingProductIds.remove(product.id));
    }
  }

  Future<double?> _askImportPrice(Product product) async {
    final TextEditingController controller = TextEditingController(
      text: product.price.toStringAsFixed(2),
    );
    return showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Import "${product.name}"', style: AppThemes.poppins(context, fontSize: 14, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Set your selling price for this product in your shop.',
                style: AppThemes.poppins(context, fontSize: 10,
                    color: _mutedTextColor(context)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Selling price (ETB)', labelStyle: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w500),
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(width: 0.4, color: Colors.grey.shade400),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(width: 0.4, color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(width: 0.7, color: Theme.of(dialogContext).colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final double? value = double.tryParse(controller.text.trim());
                if (value == null || value <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Enter a valid price.')),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark
        ? const Color(0xFF172026)
        : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;
    final String name = widget.supplier?.name ?? widget.marketSupplier?.name ?? 'Supplier';
    final Color avatarColor = _colorFromHex(
      widget.supplier?.avatarColor ?? widget.marketSupplier?.avatarColor ?? '',
      scheme.primary,
    );
    final double rating = widget.supplier?.rating ?? widget.marketSupplier?.rating ?? 0;
    final bool verified =
        widget.supplier?.verified ?? widget.marketSupplier?.verified ?? false;

    return Scaffold(
      backgroundColor: bgBottom,
      appBar: AppBar(
        backgroundColor: bgTop,
        surfaceTintColor: Colors.transparent,
        title: Text(name),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[bgTop, bgBottom, bgBottom],
            stops: const <double>[0.0, 0.22, 1.0],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            _DetailHeaderCard(
              title: name,
              subtitle:
                  widget.supplier?.categories ?? widget.marketSupplier?.specialties ?? '',
              avatarColor: avatarColor,
              icon: Icons.storefront_rounded,
              badge: verified ? 'Verified' : 'Marketplace',
            ),
            const SizedBox(height: 14),
            _InfoPanel(
              title: 'Supplier Info',
              children: [
                _DetailRow(
                  title: 'Rating',
                  value: rating == 0 ? 'Not rated' : rating.toStringAsFixed(1),
                ),
                _DetailRow(
                  title: 'Delivery',
                  value: widget.supplier?.speed ?? widget.marketSupplier?.delivery ?? '-',
                ),
                _DetailRow(
                  title: 'Last interaction',
                  value: widget.supplier?.lastInteraction ?? 'New supplier',
                ),
                _DetailRow(
                  title: 'Region',
                  value: widget.marketSupplier?.region ?? 'Trusted network',
                ),
                _DetailRow(
                  title: 'Starting price',
                  value: widget.marketSupplier?.startPrice ?? 'Contract pricing',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoPanel(
              title: 'Orders',
              children: widget.orders.isEmpty
                  ? <Widget>[
                      _DetailRow(
                        title: 'Open orders',
                        value: 'No active purchase orders',
                      ),
                    ]
                  : widget.orders
                        .map((SupplierOrder order) {
                          return _DetailRow(
                            title: order.id,
                            value:
                                '${order.amount} - ${_statusLabel(order.status)}',
                          );
                        })
                        .toList(growable: false),
            ),
            const SizedBox(height: 14),
            _SupplierProductsPanel(
              productsFuture: _productsFuture,
              importingProductIds: _importingProductIds,
              onImport: _importProduct,
              onRetry: _reload,
            ),
          ],
        ),
      ),
    );
  }
}
class SupplierOrderDetailPage extends StatelessWidget {
  const SupplierOrderDetailPage({super.key, required this.order});

  final SupplierOrder order;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark
        ? const Color(0xFF172026)
        : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;
    final Color statusColor = _orderStatusColor(order.status);

    return Scaffold(
      backgroundColor: bgBottom,
      appBar: AppBar(
        backgroundColor: bgTop,
        surfaceTintColor: Colors.transparent,
        title: Text(order.id),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[bgTop, bgBottom, bgBottom],
            stops: const <double>[0.0, 0.22, 1.0],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            _DetailHeaderCard(
              title: order.id,
              subtitle: order.supplier,
              avatarColor: statusColor,
              icon: Icons.receipt_long_rounded,
              badge: _statusLabel(order.status),
            ),
            const SizedBox(height: 14),
            _InfoPanel(
              title: 'Order Details',
              children: [
                _DetailRow(title: 'Supplier', value: order.supplier),
                _DetailRow(
                  title: 'Products',
                  value: '${order.productCount} items',
                ),
                _DetailRow(title: 'Amount', value: order.amount),
                _DetailRow(title: 'Order date', value: order.orderDate),
                _DetailRow(title: 'Delivery ETA', value: order.eta),
                _DetailRow(title: 'Status', value: _statusLabel(order.status)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeaderCard extends StatelessWidget {
  const _DetailHeaderCard({
    required this.title,
    required this.subtitle,
    required this.avatarColor,
    required this.icon,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final Color avatarColor;
  final IconData icon;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color mutedTextColor = _mutedTextColor(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: avatarColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: avatarColor, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.poppins(
                    context,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.poppins(
                    context,
                    fontSize: 12,
                    color: mutedTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusPill(label: badge, color: avatarColor),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppThemes.poppins(
              context,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
class _SupplierProductsPanel extends StatelessWidget {
  const _SupplierProductsPanel({
    required this.productsFuture,
    required this.importingProductIds,
    required this.onImport,
    required this.onRetry,
  });

  final Future<List<Product>> productsFuture;
  final Set<String> importingProductIds;
  final void Function(Product product) onImport;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color mutedTextColor = _mutedTextColor(context);

    return FutureBuilder<List<Product>>(
      future: productsFuture,
      builder: (BuildContext context, AsyncSnapshot<List<Product>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _InfoPanel(
            title: 'Products',
            children: const <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(minHeight: 4),
              ),
            ],
          );
        }
        if (snapshot.hasError) {
          return _InfoPanel(
            title: 'Products',
            children: <Widget>[
              Text(
                'Could not load products.',
                style: AppThemes.poppins(context, fontSize: 12, color: mutedTextColor),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          );
        }

        final List<Product> products = snapshot.data ?? <Product>[];
        if (products.isEmpty) {
          return _InfoPanel(
            title: 'Products',
            children: <Widget>[
              Text(
                'This supplier has no active products yet.',
                style: AppThemes.poppins(context, fontSize: 12, color: mutedTextColor),
              ),
            ],
          );
        }

        return _InfoPanel(
          title: 'Products (${products.length})',
          children: products.map((Product product) {
            final bool importing = importingProductIds.contains(product.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.primary.withOpacity(0.12)),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ETB ${product.price.toStringAsFixed(2)}',
                          style: AppThemes.poppins(context, fontSize: 11,
                              color: mutedTextColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: importing ? null : () => onImport(product),
                    child: importing
                        ? const SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Import'),
                  ),
                ],
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

class _SupplierOrderTile extends StatelessWidget {
  const _SupplierOrderTile({required this.order, required this.onTap});

  final SupplierOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color mutedTextColor = _mutedTextColor(context);
    final Color statusColor = _orderStatusColor(order.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary.withOpacity(0.14)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.id,
                      style: AppThemes.poppins(
                        context,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusPill(
                    label: _statusLabel(order.status),
                    color: statusColor,
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: mutedTextColor),
                ],
              ),
              const SizedBox(height: 8),
              _DetailRow(title: 'Supplier', value: order.supplier),
              _DetailRow(
                title: 'Items',
                value: '${order.productCount} products',
              ),
              _DetailRow(title: 'Amount', value: order.amount),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 16,
                      color: mutedTextColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${order.orderDate} - ${order.eta}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppThemes.poppins(
                          context,
                          fontSize: 12,
                          color: mutedTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupplierActivityTile extends StatelessWidget {
  const _SupplierActivityTile({required this.activity});

  final SupplierActivityItem activity;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color mutedTextColor = _mutedTextColor(context);
    final Color activityColor = _colorFromHex(activity.color, scheme.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: activityColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconFor(activity.icon),
              color: activityColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.poppins(
                    context,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  activity.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppThemes.poppins(
                    context,
                    fontSize: 11,
                    color: mutedTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            activity.time,
            style: AppThemes.poppins(
              context,
              fontSize: 10,
              color: mutedTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}



class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        _statusLabel(label),
        style: AppThemes.poppins(
          context,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _initials(label),
          style: AppThemes.poppins(
            context,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _SupplierLoadingView extends StatelessWidget {
  const _SupplierLoadingView();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color mutedTextColor = _mutedTextColor(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.primary.withOpacity(0.14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Loading supplier dashboard...',
                style: AppThemes.poppins(
                  context,
                  fontSize: 13,
                  color: mutedTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              const LinearProgressIndicator(minHeight: 5),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupplierErrorView extends StatelessWidget {
  const _SupplierErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color mutedTextColor = _mutedTextColor(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.primary.withOpacity(0.14)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Could not load suppliers',
                style: AppThemes.poppins(
                  context,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Check backend connectivity and try again.',
                style: AppThemes.poppins(
                  context,
                  fontSize: 12,
                  color: mutedTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _statValue(SupplierDashboardData data, String label, String field) {
  for (final SupplierQuickStat stat in data.quickStats) {
    if (stat.label.toLowerCase() == label.toLowerCase()) {
      return field == 'trend' ? stat.trend : stat.value;
    }
  }
  return field == 'trend' ? '' : '-';
}

List<SupplierOrder> _ordersForSupplier(
  List<SupplierOrder> orders,
  String supplierName,
) {
  return orders
      .where((SupplierOrder o) =>
          o.supplier.trim().toLowerCase() == supplierName.trim().toLowerCase())
      .toList(growable: false);
}

Color _mutedTextColor(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  return theme.colorScheme.onSurface.withOpacity(
    theme.brightness == Brightness.dark ? 0.78 : 0.68,
  );
}





Color _orderStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'in_transit':
      return Colors.blue.shade700;
    case 'preparing':
      return Colors.orange.shade700;
    case 'accepted':
      return Colors.green.shade700;
    default:
      return Colors.blueGrey;
  }
}

String _statusLabel(String status) {
  if (status.trim().isEmpty) {
    return 'Unknown';
  }
  return status
      .replaceAll('_', ' ')
      .split(' ')
      .where((String word) => word.isNotEmpty)
      .map((String word) {
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      })
      .join(' ');
}

IconData _iconFor(String icon) {
  switch (icon.toLowerCase()) {
    case 'check_circle':
      return Icons.check_circle_rounded;
    case 'person_add':
      return Icons.person_add_alt_1_rounded;
    case 'payments':
      return Icons.payments_rounded;
    case 'warning':
      return Icons.warning_amber_rounded;
    case 'chat':
      return Icons.chat_bubble_outline_rounded;
    default:
      return Icons.history_rounded;
  }
}

Color _colorFromHex(String hex, Color fallback) {
  final String normalized = hex.replaceFirst('#', '').trim();
  if (normalized.length != 6) {
    return fallback;
  }
  final int? value = int.tryParse('FF$normalized', radix: 16);
  if (value == null) {
    return fallback;
  }
  return Color(value);
}

String _initials(String name) {
  final List<String> parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((String part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return 'S';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}
