import 'package:flutter/material.dart';
import 'package:shop_manager/models/product.dart';
import 'package:shop_manager/theme/app_themes.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.product,
  });

  final Product product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _restockAmount = 0;

  String _money(double value) => 'ETB ${value.toStringAsFixed(2)}';

  Color _stockColor(int stock) {
    if (stock <= 0) {
      return const Color(0xFFC62828);
    }
    if (stock <= 5) {
      return const Color(0xFFE09B18);
    }
    return const Color(0xFF1B8F4D);
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

  @override
  Widget build(BuildContext context) {
    final Product product = widget.product;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark ? const Color(0xFF172026) : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;

    final int projectedStock = product.stock + _restockAmount;
    final double stockValue = product.price * product.stock;
    final double projectedValue = product.price * projectedStock;
    final Color stockColor = _stockColor(product.stock);

    return Scaffold(
      backgroundColor: bgBottom,
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Product Detail',
                      style: AppThemes.poppins(context, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                      return Container(
                        color: scheme.primary.withOpacity(0.08),
                        alignment: Alignment.center,
                        child: Icon(Icons.image_not_supported_outlined, color: scheme.primary, size: 36),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(product.name, style: AppThemes.poppins(context, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 5),
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: stockColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: stockColor.withOpacity(0.34)),
                          ),
                          child: Text(
                            _stockLabel(product.stock),
                            style: AppThemes.poppins(context, fontSize: 10, fontWeight: FontWeight.w700, color: stockColor),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${product.stock} units available',
                          style: AppThemes.poppins(context, fontSize: 11, color: scheme.onSurface.withOpacity(0.68), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _metricTile(context, label: 'Unit Price', value: _money(product.price), color: scheme.primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _metricTile(context, label: 'Stock Value', value: _money(stockValue), color: const Color(0xFF1B8F4D)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _metricTile(
                      context,
                      label: 'Projected Value',
                      value: _money(projectedValue),
                      color: projectedValue >= stockValue ? const Color(0xFF1B8F4D) : const Color(0xFFC62828),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Restock Simulator', style: AppThemes.poppins(context, fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'Adjust restock quantity to estimate new inventory and value.',
                      style: AppThemes.poppins(context, fontSize: 11, color: scheme.onSurface.withOpacity(0.62), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        OutlinedButton(
                          onPressed: () => setState(() => _restockAmount = (_restockAmount - 5).clamp(0, 500)),
                          child: const Icon(Icons.remove_rounded),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: scheme.onSurface.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Restock: $_restockAmount units',
                              textAlign: TextAlign.center,
                              style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(() => _restockAmount = (_restockAmount + 5).clamp(0, 500)),
                          child: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Slider(
                      value: _restockAmount.toDouble(),
                      min: 0,
                      max: 500,
                      divisions: 100,
                      label: '$_restockAmount',
                      onChanged: (double value) => setState(() => _restockAmount = value.round()),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Projected stock after restock: $projectedStock units',
                      style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w600, color: scheme.onSurface.withOpacity(0.70)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Edit flow can be connected next for ${product.name}', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onPrimary)),
                          ),
                        );
                      },
                      child: Text('Edit Product', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.primary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Restock request: +$_restockAmount units', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onPrimary)),
                          ),
                        );
                      },
                      child: Text('Update Stock', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricTile(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppThemes.poppins(context, fontSize: 10, color: scheme.onSurface.withOpacity(0.62), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppThemes.poppins(context, fontSize: 12, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
