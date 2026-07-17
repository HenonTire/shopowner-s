import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shop_manager/models/product.dart';
import 'package:shop_manager/providers/product_providers.dart';
import 'package:shop_manager/services/product_repository.dart';
import 'package:shop_manager/theme/app_themes.dart';

// ─── Variant model (local, for form state only) ───────────────────────────────
class _VariantEntry {
  _VariantEntry();

  String name = '';
  String price = '';
  String color = '';
  String size = '';
}

// ─── Media model (local, for form state only) ─────────────────────────────────
class _MediaEntry {
  _MediaEntry({
    required this.bytes,
    required this.fileName,
    this.isPrimary = false,
  });

  final Uint8List bytes;
  final String fileName;
  String caption = '';
  bool isPrimary;
}

class ProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final String buttonText;
  final VoidCallback onSave;

  const ProfileSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    required this.buttonText,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outline.withOpacity(.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(onPressed: onSave, child: Text(buttonText)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class AddProductPage extends ConsumerStatefulWidget {
  const AddProductPage({super.key, this.onProductSaved, this.existingProduct});

  final VoidCallback? onProductSaved;
  final Product? existingProduct;

  bool get isEditing => existingProduct != null;

  @override
  ConsumerState<AddProductPage> createState() => _AddProductPageState();
}
class _AddProductPageState extends ConsumerState<AddProductPage> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Basic info controllers
  final TextEditingController _nameController      = TextEditingController();
  final TextEditingController _descController      = TextEditingController();
  final TextEditingController _priceController     = TextEditingController();
  final TextEditingController _weightController    = TextEditingController();
  final TextEditingController _dimensionsController = TextEditingController();
  final TextEditingController _tagsController      = TextEditingController();

  String _selectedCategory = 'General';
  bool   _isActive         = true;
  int    _stock            = 0;

  final List<_VariantEntry> _variants    = <_VariantEntry>[];
  final List<_MediaEntry>   _mediaEntries = <_MediaEntry>[];
  final ImagePicker         _imagePicker  = ImagePicker();

  List<ProductMedia>        _existingMedia = <ProductMedia>[];   // ← NEW
 

  bool _isSaving = false;

  final List<String> _categories = <String>[
    'General',
    'Electronics',
    'Fashion',
    'Beauty',
    'Food',
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

@override
  void initState() {
    super.initState();
    final Product? p = widget.existingProduct;
    if (p != null) {
      _nameController.text = p.name;
      _descController.text = p.description;
      _priceController.text = p.price.toString();
      _weightController.text = p.weight?.toString() ?? '';
      _dimensionsController.text = p.dimensions ?? '';
      _tagsController.text = p.tags.join(', ');
      _selectedCategory = p.category ?? 'General';
      _isActive = p.isActive;
      _stock = p.stock;
      _existingMedia = List<ProductMedia>.from(p.media);
      for (final ProductVariant v in p.variants) {
        final _VariantEntry entry = _VariantEntry()
          ..name = v.variantName
          ..price = v.price.toString()
          ..color = v.attributes['color'] ?? ''
          ..size = v.attributes['size'] ?? '';
        _variants.add(entry);
      }
    }
    // Rebuild preview on every keystroke
    _nameController.addListener(_rebuild);
    _priceController.addListener(_rebuild);
    _descController.addListener(_rebuild);
    _tagsController.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _weightController.dispose();
    _dimensionsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  List<String> get _parsedTags => _tagsController.text
      .split(',')
      .map((String t) => t.trim())
      .where((String t) => t.isNotEmpty)
      .toList();

  Future<void> _pickImages() async {
    try {
      final List<XFile> images =
          await _imagePicker.pickMultiImage(imageQuality: 85);
      if (!mounted) return;
      for (final XFile image in images) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() {
          _mediaEntries.add(_MediaEntry(
            bytes: bytes,
            fileName: image.name,
            isPrimary: _mediaEntries.isEmpty,
          ));
        });
      }
    } on PlatformException catch (_) {
      if (!mounted) return;
      _showSnack('Could not open gallery. Check permissions.');
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaEntries.removeAt(index);
      if (_mediaEntries.isNotEmpty &&
          !_mediaEntries.any((_MediaEntry e) => e.isPrimary)) {
        _mediaEntries.first.isPrimary = true;
      }
    });
  }

  void _setPrimary(int index) {
    setState(() {
      for (int i = 0; i < _mediaEntries.length; i++) {
        _mediaEntries[i].isPrimary = i == index;
      }
    });
  }

  void _addVariant()         => setState(() => _variants.add(_VariantEntry()));
  void _removeVariant(int i) => setState(() => _variants.removeAt(i));

void _showSnack(String msg, {bool error = false}) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        msg,
        style: AppThemes.poppins(
          context,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: error ? Colors.red.shade100 : scheme.onInverseSurface,
        ),
      ),
      backgroundColor: error ? Colors.red.shade800 : scheme.inverseSurface,
    ),
  );
}
Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final BackendProductRepository repo = BackendProductRepository();
      final ProductCreateRequest request = ProductCreateRequest(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        stock: _stock,
        category: _selectedCategory,
        weight: double.tryParse(_weightController.text.trim()),
        dimensions: _dimensionsController.text.trim(),
        tags: _parsedTags,
        isActive: _isActive,
        variants: _variants
            .map((_VariantEntry v) => ProductVariantRequest(
                  variantName: v.name,
                  price: double.tryParse(v.price) ?? 0,
                  color: v.color.isEmpty ? null : v.color,
                  size: v.size.isEmpty ? null : v.size,
                ))
            .toList(),
        media: _mediaEntries
            .map((_MediaEntry m) => ProductMediaRequest(
                  bytes: m.bytes,
                  fileName: m.fileName,
                  caption: m.caption,
                  isPrimary: m.isPrimary,
                  order: _mediaEntries.indexOf(m) + 1,
                ))
            .toList(),
      );

      final Product product = widget.isEditing
          ? await repo.updateProduct(widget.existingProduct!.id, request)
          : await repo.createProduct(request);

      if (!mounted) return;

      ref.invalidate(productsProvider);

      _showSnack(widget.isEditing
          ? 'Product "${product.name}" updated!'
          : 'Product "${product.name}" saved!');

      widget.onProductSaved?.call();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Live Preview ──────────────────────────────────────────────────────────────

  Widget _buildLivePreview() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String name  = _nameController.text.trim();
    final String price = _priceController.text.trim();
    final String desc  = _descController.text.trim();

    final _MediaEntry? primaryMedia = _mediaEntries.isEmpty
        ? null
        : _mediaEntries.firstWhere(
            (_MediaEntry e) => e.isPrimary,
            orElse: () => _mediaEntries.first,
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A20) : const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[

          // ── Preview header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(Icons.visibility_outlined,
                      size: 14, color: scheme.primary),
                ),
                const SizedBox(width: 7),
                Text(
                  'Live Preview',
                  style: AppThemes.poppins(context,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary),
                ),
                const Spacer(),
                // Active / inactive badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _isActive
                        ? Colors.green.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _isActive ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isActive ? 'Active' : 'Inactive',
                        style: AppThemes.poppins(context,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _isActive
                                ? Colors.green.shade700
                                : Colors.orange.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Product card preview ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[

                  // Image thumbnail
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                    child: primaryMedia != null
                        ? Image.memory(primaryMedia.bytes,
                            width: 90, height: 110, fit: BoxFit.cover)
                        : Container(
                            width: 90,
                            height: 110,
                            color: scheme.primary.withOpacity(0.07),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(Icons.image_outlined,
                                    color: scheme.primary.withOpacity(0.35),
                                    size: 26),
                                const SizedBox(height: 4),
                                Text(
                                  'No image',
                                  style: AppThemes.poppins(context,
                                      fontSize: 8,
                                      color: scheme.onSurface.withOpacity(0.35),
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                  ),

                  // Product info
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[

                          // Name
                          Text(
                            name.isEmpty ? 'Product name...' : name,
                            style: AppThemes.poppins(context,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: name.isEmpty
                                    ? scheme.onSurface.withOpacity(0.3)
                                    : scheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Category chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.09),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _selectedCategory,
                              style: AppThemes.poppins(context,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.primary),
                            ),
                          ),
                          const SizedBox(height: 5),

                          // Description (2 lines max)
                          if (desc.isNotEmpty)
                            Text(
                              desc,
                              style: AppThemes.poppins(context,
                                  fontSize: 10,
                                  color: scheme.onSurface.withOpacity(0.55),
                                  fontWeight: FontWeight.w400),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                          const SizedBox(height: 6),

                          // Price + stock
                          Row(
                            children: <Widget>[
                              Text(
                                price.isEmpty
                                    ? 'ETB —'
                                    : 'ETB ${double.tryParse(price)?.toStringAsFixed(2) ?? price}',
                                style: AppThemes.poppins(context,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: price.isEmpty
                                        ? scheme.onSurface.withOpacity(0.25)
                                        : scheme.primary),
                              ),
                              const Spacer(),
                              Text(
                                'Stock: $_stock',
                                style: AppThemes.poppins(context,
                                    fontSize: 9,
                                    color: scheme.onSurface.withOpacity(0.45),
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),

                          // Variant chips (up to 3)
                          if (_variants.any(
                              (_VariantEntry v) => v.name.isNotEmpty)) ...<Widget>[
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 4,
                              runSpacing: 3,
                              children: _variants
                                  .where((_VariantEntry v) => v.name.isNotEmpty)
                                  .take(3)
                                  .map((_VariantEntry v) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              scheme.onSurface.withOpacity(0.07),
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          v.name,
                                          style: AppThemes.poppins(context,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w600,
                                              color: scheme.onSurface
                                                  .withOpacity(0.6)),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],

                          // Tag chips (up to 3)
                          if (_parsedTags.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              children: _parsedTags
                                  .take(3)
                                  .map((String tag) => Text(
                                        '#$tag',
                                        style: AppThemes.poppins(context,
                                            fontSize: 8,
                                            color:
                                                scheme.primary.withOpacity(0.6),
                                            fontWeight: FontWeight.w500),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Image count indicator
          if (_mediaEntries.length > 1)
            Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 12),
              child: Row(
                children: <Widget>[
                  Icon(Icons.photo_library_outlined,
                      size: 12, color: scheme.onSurface.withOpacity(0.4)),
                  const SizedBox(width: 4),
                  Text(
                    '${_mediaEntries.length} images',
                    style: AppThemes.poppins(context,
                        fontSize: 10,
                        color: scheme.onSurface.withOpacity(0.4),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Section header ────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: scheme.primary),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppThemes.poppins(context,
                fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.onSurface.withOpacity(0.09)),
      ),
      child: child,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop    = isDark ? const Color(0xFF172026) : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;

    final InputDecorationTheme inputTheme = InputDecorationTheme(
      filled: true,
      fillColor: scheme.onPrimary.withOpacity(0.04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: AppThemes.poppins(context,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface.withOpacity(0.64)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: scheme.onSurface.withOpacity(0.15), width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: scheme.onSurface.withOpacity(0.15), width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            BorderSide(color: scheme.primary.withOpacity(0.50), width: 1),
      ),
    );

    return Scaffold(
      backgroundColor: bgBottom,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[bgTop, bgBottom, bgBottom],
            stops: const <double>[0.0, 0.18, 1.0],
          ),
        ),
        child: SafeArea(
          child: Theme(
            data: Theme.of(context).copyWith(inputDecorationTheme: inputTheme),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: <Widget>[

                  // ── Header ────────────────────────────────────────────────
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.isEditing ? 'Edit Product' : 'Add Product',
                              style: AppThemes.poppins(context,
                                  fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              widget.isEditing
                                  ? 'Update details, variants, and media.'
                                  : 'Fill in details, variants, and media.',)
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Live Preview ──────────────────────────────────────────
                  _buildLivePreview(),

                  // ── 1. Basic Info ─────────────────────────────────────────
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _sectionHeader('Basic Info', Icons.info_outline_rounded),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                              labelText: 'Product name *'),
                          validator: (String? v) =>
                              (v == null || v.trim().length < 3)
                                  ? 'At least 3 characters'
                                  : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(labelText: 'Category'),
                          items: _categories
                              .map((String c) => DropdownMenuItem<String>(
                                  value: c, child: Text(c)))
                              .toList(),
                          onChanged: (String? v) {
                            if (v != null) setState(() => _selectedCategory = v);
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                    labelText: 'Price (ETB) *'),
                                validator: (String? v) =>
                                    (double.tryParse(v?.trim() ?? '') ?? 0) <= 0
                                        ? 'Enter a valid price'
                                        : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                initialValue: '0',
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'Default stock'),
                                onChanged: (String v) =>
                                    setState(() => _stock =
                                        int.tryParse(v.trim()) ?? 0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: _weightController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: const InputDecoration(
                                    labelText: 'Weight (kg)'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _dimensionsController,
                                decoration: const InputDecoration(
                                  labelText: 'Dimensions',
                                  hintText: '32x22x3',
                                  hintStyle: TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _tagsController,
                          decoration: const InputDecoration(
                            labelText: 'Tags',
                            hintStyle: TextStyle(fontSize: 10),
                            hintText: 'tshirt, premium, 2026',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Icon(Icons.check_circle_outline_rounded,
                                size: 17,
                                color: scheme.onSurface.withOpacity(0.55)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Active (visible to buyers)',
                                style: AppThemes.poppins(context,
                                    fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Transform.scale(
                              scale: 0.82,
                              child: Switch(
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                value: _isActive,
                                onChanged: (bool v) =>
                                    setState(() => _isActive = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── 2. Media ──────────────────────────────────────────────
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _sectionHeader(
                            'Media', Icons.photo_library_outlined),
                        if (_existingMedia.isNotEmpty) ...<Widget>[
                          SizedBox(
                            height: 72,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _existingMedia.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (BuildContext context, int i) {
                                final ProductMedia m = _existingMedia[i];
                                return Stack(
                                  children: <Widget>[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        m.file,
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 72,
                                          height: 72,
                                          color: scheme.primary.withOpacity(0.08),
                                          child: Icon(Icons.image_outlined,
                                              color: scheme.primary),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _existingMedia.removeAt(i)),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close_rounded,
                                              size: 13, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Existing images. New images added below will be uploaded too.',
                            style: AppThemes.poppins(context,
                                fontSize: 9,
                                color: scheme.onSurface.withOpacity(0.50),
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_mediaEntries.isEmpty)
                          GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              height: 90,
                              decoration: BoxDecoration(
                                color: scheme.primary.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: scheme.primary.withOpacity(0.25),
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(Icons.add_photo_alternate_outlined,
                                        color: scheme.primary, size: 28),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Tap to add images',
                                      style: AppThemes.poppins(context,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: scheme.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else ...<Widget>[
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _mediaEntries.length + 1,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (BuildContext context, int i) {
                                if (i == _mediaEntries.length) {
                                  return GestureDetector(
                                    onTap: _pickImages,
                                    child: Container(
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color:
                                            scheme.primary.withOpacity(0.06),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                            color: scheme.primary
                                                .withOpacity(0.20)),
                                      ),
                                      child: Icon(Icons.add_rounded,
                                          color: scheme.primary),
                                    ),
                                  );
                                }
                                final _MediaEntry entry = _mediaEntries[i];
                                return Stack(
                                  children: <Widget>[
                                    GestureDetector(
                                      onTap: () => _setPrimary(i),
                                      child: Container(
                                        width: 80,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: entry.isPrimary
                                                ? scheme.primary
                                                : scheme.onSurface
                                                    .withOpacity(0.12),
                                            width: entry.isPrimary ? 2 : 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(11),
                                          child: Image.memory(entry.bytes,
                                              fit: BoxFit.cover),
                                        ),
                                      ),
                                    ),
                                    if (entry.isPrimary)
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: scheme.primary,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Primary',
                                            style: AppThemes.poppins(context,
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                color: scheme.onPrimary),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeMedia(i),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.close_rounded,
                                              size: 13,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap an image to set it as primary. Tap + to add more.',
                            style: AppThemes.poppins(context,
                                fontSize: 9,
                                color: scheme.onSurface.withOpacity(0.50),
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── 3. Variants ───────────────────────────────────────────
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                                child: _sectionHeader(
                                    'Variants', Icons.tune_rounded)),
                            TextButton.icon(
                              onPressed: _addVariant,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text(
                                'Add',
                                style: AppThemes.poppins(context,
                                    fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        if (_variants.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No variants added. Tap "Add" if your product has sizes, colors, etc.',
                              style: AppThemes.poppins(context,
                                  fontSize: 11,
                                  color: scheme.onSurface.withOpacity(0.50),
                                  fontWeight: FontWeight.w500),
                            ),
                          )
                        else
                          ...List<Widget>.generate(_variants.length, (int i) {
                            final _VariantEntry v = _variants[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: scheme.primary.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: scheme.primary.withOpacity(0.12)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        'Variant ${i + 1}',
                                        style: AppThemes.poppins(context,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () => _removeVariant(i),
                                        child: Icon(Icons.close_rounded,
                                            size: 17,
                                            color: Colors.red.shade400),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: v.name,
                                    decoration: const InputDecoration(
                                        labelText:
                                            'Variant name (e.g. Red - Large)'),
                                    onChanged: (String val) =>
                                        setState(() => v.name = val),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: v.price,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(
                                              labelText: 'Price'),
                                          onChanged: (String val) =>
                                              v.price = val,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: v.color,
                                          decoration: const InputDecoration(
                                              labelText: 'Color'),
                                          onChanged: (String val) =>
                                              v.color = val,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: v.size,
                                          decoration: const InputDecoration(
                                              labelText: 'Size'),
                                          onChanged: (String val) =>
                                              v.size = val,
                                        ),
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

                  // ── Action buttons ────────────────────────────────────────
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => widget.onProductSaved?.call(),
                          style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14)),
                          child: Text(
                            'Cancel',
                            style: AppThemes.poppins(context,
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14)),
                          child: _isSaving
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.onPrimary,
                                  ),
                                )
                              : Text(
                                  widget.isEditing ? 'Save Changes' : 'Save Product',
                                  style: AppThemes.poppins(context,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onPrimary),
                                ),
                        ),
                      ),
                    ],
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
