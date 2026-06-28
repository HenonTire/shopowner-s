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
  int _selectedMediaIndex = 0;
  int _restockAmount = 0;

  Product get _p => widget.product;

  String _money(double value) => 'ETB ${value.toStringAsFixed(2)}';

  Color _stockColor(int stock) {
    if (stock <= 0) return const Color(0xFFC62828);
    if (stock <= 5) return const Color(0xFFE09B18);
    return const Color(0xFF1B8F4D);
  }

  String _stockLabel(int stock) {
    if (stock <= 0) return 'Out of stock';
    if (stock <= 5) return 'Low stock';
    return 'In stock';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark ? const Color(0xFF172026) : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;

    final int projectedStock = _p.stock + _restockAmount;
    final double stockValue = _p.price * _p.stock;
    final double projectedValue = _p.price * projectedStock;
    final Color stockColor = _stockColor(_p.stock);

    // pick display image
    final List<String> imageUrls = _p.media.isNotEmpty
        ? _p.media.map((ProductMedia m) => m.file).toList()
        : <String>[_p.imageUrl];

    final String displayImage = imageUrls.isNotEmpty &&
            _selectedMediaIndex < imageUrls.length
        ? imageUrls[_selectedMediaIndex]
        : _p.imageUrl;

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
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: <Widget>[

              // ── Header ─────────────────────────────────────────────────────
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Product Detail',
                      style: AppThemes.poppins(context, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (_p.isActive)
                    _badge('Active', const Color(0xFF1B8F4D))
                  else
                    _badge('Inactive', const Color(0xFFC62828)),
                ],
              ),
              const SizedBox(height: 10),

              // ── Media gallery ───────────────────────────────────────────────
              _card(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: displayImage.isNotEmpty
                            ? Image.network(
                                displayImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _imagePlaceholder(scheme),
                              )
                            : _imagePlaceholder(scheme),
                      ),
                    ),
                    if (imageUrls.length > 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: SizedBox(
                          height: 56,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: imageUrls.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (BuildContext context, int i) {
                              final bool selected = i == _selectedMediaIndex;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedMediaIndex = i),
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: selected
                                          ? scheme.primary
                                          : scheme.onSurface.withOpacity(0.14),
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: Image.network(
                                      imageUrls[i],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: scheme.primary.withOpacity(0.08),
                                        child: Icon(Icons.image_outlined,
                                            size: 20, color: scheme.primary),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Core info ───────────────────────────────────────────────────
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _p.name,
                            style: AppThemes.poppins(context, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: stockColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: stockColor.withOpacity(0.34)),
                          ),
                          child: Text(
                            _stockLabel(_p.stock),
                            style: AppThemes.poppins(context, fontSize: 10,
                                fontWeight: FontWeight.w700, color: stockColor),
                          ),
                        ),
                      ],
                    ),
                    if (_p.sku != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${_p.sku}',
                        style: AppThemes.poppins(context, fontSize: 10,
                            color: scheme.onSurface.withOpacity(0.50),
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                    if (_p.category != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Icon(Icons.category_outlined, size: 13,
                              color: scheme.onSurface.withOpacity(0.50)),
                          const SizedBox(width: 4),
                          Text(
                            _p.category!,
                            style: AppThemes.poppins(context, fontSize: 10,
                                color: scheme.onSurface.withOpacity(0.58),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    if (_p.description.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(
                        _p.description,
                        style: AppThemes.poppins(context, fontSize: 12,
                            color: scheme.onSurface.withOpacity(0.72),
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _metricTile(context,
                              label: 'Unit Price',
                              value: _money(_p.price),
                              color: scheme.primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _metricTile(context,
                              label: 'Stock',
                              value: '${_p.stock} units',
                              color: stockColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _metricTile(context,
                              label: 'Stock Value',
                              value: _money(stockValue),
                              color: const Color(0xFF1B8F4D)),
                        ),
                      ],
                    ),
                    if (_p.averageRating != null) ...<Widget>[
                      const SizedBox(height: 8),
                      _metricTile(context,
                          label: 'Rating',
                          value:
                              '${_p.averageRating!.toStringAsFixed(1)} ★  (${_p.reviewsCount} reviews)',
                          color: const Color(0xFFE09B18)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Specs ───────────────────────────────────────────────────────
              if (_p.weight != null || _p.dimensions != null)
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _sectionTitle(context, 'Specifications', Icons.straighten_rounded),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          if (_p.weight != null)
                            Expanded(
                              child: _specTile(context,
                                  label: 'Weight', value: '${_p.weight} kg'),
                            ),
                          if (_p.weight != null && _p.dimensions != null)
                            const SizedBox(width: 8),
                          if (_p.dimensions != null)
                            Expanded(
                              child: _specTile(context,
                                  label: 'Dimensions', value: _p.dimensions!),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (_p.weight != null || _p.dimensions != null)
                const SizedBox(height: 12),

              // ── Tags ────────────────────────────────────────────────────────
              if (_p.tags.isNotEmpty)
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _sectionTitle(context, 'Tags', Icons.label_outline_rounded),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _p.tags.map((String tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: scheme.primary.withOpacity(0.20)),
                            ),
                            child: Text(
                              '#$tag',
                              style: AppThemes.poppins(context,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              if (_p.tags.isNotEmpty) const SizedBox(height: 12),

              // ── Variants ────────────────────────────────────────────────────
              if (_p.variants.isNotEmpty)
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _sectionTitle(context, 'Variants', Icons.tune_rounded),
                      const SizedBox(height: 10),
                      ..._p.variants.map((ProductVariant v) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.primary.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: scheme.primary.withOpacity(0.12)),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      v.variantName,
                                      style: AppThemes.poppins(context,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    if (v.attributes.isNotEmpty)
                                      Text(
                                        v.attributes.entries
                                            .map((MapEntry<String, String> e) =>
                                                '${e.key}: ${e.value}')
                                            .join('  •  '),
                                        style: AppThemes.poppins(context,
                                            fontSize: 10,
                                            color: scheme.onSurface
                                                .withOpacity(0.58),
                                            fontWeight: FontWeight.w500),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    _money(v.price),
                                    style: AppThemes.poppins(context,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.primary),
                                  ),
                                  Text(
                                    '${v.stock} units',
                                    style: AppThemes.poppins(context,
                                        fontSize: 10,
                                        color: _stockColor(v.stock),
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              if (_p.variants.isNotEmpty) const SizedBox(height: 12),

              // ── Restock simulator ───────────────────────────────────────────
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _sectionTitle(
                        context, 'Restock Simulator', Icons.inventory_2_outlined),
                    const SizedBox(height: 4),
                    Text(
                      'Adjust restock quantity to estimate new inventory value.',
                      style: AppThemes.poppins(context, fontSize: 11,
                          color: scheme.onSurface.withOpacity(0.58),
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        OutlinedButton(
                          onPressed: () => setState(() =>
                              _restockAmount = (_restockAmount - 5).clamp(0, 500)),
                          child: const Icon(Icons.remove_rounded, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: scheme.onSurface.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+$_restockAmount units',
                              textAlign: TextAlign.center,
                              style: AppThemes.poppins(context,
                                  fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(() =>
                              _restockAmount = (_restockAmount + 5).clamp(0, 500)),
                          child: const Icon(Icons.add_rounded, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _restockAmount.toDouble(),
                      min: 0,
                      max: 500,
                      divisions: 100,
                      label: '$_restockAmount',
                      onChanged: (double value) =>
                          setState(() => _restockAmount = value.round()),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _metricTile(context,
                              label: 'After Restock',
                              value: '$projectedStock units',
                              color: scheme.primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _metricTile(context,
                              label: 'Projected Value',
                              value: _money(projectedValue),
                              color: projectedValue >= stockValue
                                  ? const Color(0xFF1B8F4D)
                                  : const Color(0xFFC62828)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Actions ─────────────────────────────────────────────────────
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _snack('Edit flow coming soon for ${_p.name}'),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(
                        'Edit',
                        style: AppThemes.poppins(context,
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _snack('Restock request: +$_restockAmount units for ${_p.name}'),
                      icon: const Icon(Icons.add_box_outlined, size: 16),
                      label: Text(
                        'Update Stock',
                        style: AppThemes.poppins(context,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onPrimary),
                      ),
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

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: AppThemes.poppins(context,
                fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.onSurface.withOpacity(0.09)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: scheme.primary),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Text(
        label,
        style: AppThemes.poppins(context,
            fontSize: 10, fontWeight: FontWeight.w700, color: color),
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
            style: AppThemes.poppins(context,
                fontSize: 9,
                color: scheme.onSurface.withOpacity(0.56),
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppThemes.poppins(context,
                fontSize: 11, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _specTile(BuildContext context,
      {required String label, required String value}) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppThemes.poppins(context,
                fontSize: 9,
                color: scheme.onSurface.withOpacity(0.56),
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppThemes.poppins(context,
                fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme scheme) {
    return Container(
      color: scheme.primary.withOpacity(0.08),
      alignment: Alignment.center,
      child: Icon(Icons.image_not_supported_outlined,
          color: scheme.primary, size: 36),
    );
  }
}