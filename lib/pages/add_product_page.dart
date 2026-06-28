import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shop_manager/models/product.dart';
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
  String caption = '';  // ← moved out of constructor
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
        side: BorderSide(
          color: scheme.outline.withOpacity(.2),
        ),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ...children,

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onSave,
                child: Text(buttonText),
              ),
            )
          ],
        ),
      ),
    );
  }
}


// ─── Page ─────────────────────────────────────────────────────────────────────
class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Basic info
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _dimensionsController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  String _selectedCategory = 'General';
  bool _isActive = true;
  int _stock = 0;

  // Variants
  final List<_VariantEntry> _variants = <_VariantEntry>[];

  // Media
  final List<_MediaEntry> _mediaEntries = <_MediaEntry>[];
  final ImagePicker _imagePicker = ImagePicker();

  bool _isSaving = false;

  final List<String> _categories = <String>[
    'General',
    'Electronics',
    'Fashion',
    'Beauty',
    'Food',
  ];

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

  // ── Helpers ──────────────────────────────────────────────────────────────────

  List<String> get _parsedTags => _tagsController.text
      .split(',')
      .map((String t) => t.trim())
      .where((String t) => t.isNotEmpty)
      .toList();

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (!mounted) return;
      for (final XFile image in images) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() {
          _mediaEntries.add(
            _MediaEntry(
              bytes: bytes,
              fileName: image.name,
              isPrimary: _mediaEntries.isEmpty,
            ),
          );
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
      if (_mediaEntries.isNotEmpty && !_mediaEntries.any((_MediaEntry e) => e.isPrimary)) {
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

  void _addVariant() {
    setState(() => _variants.add(_VariantEntry()));
  }

  void _removeVariant(int index) {
    setState(() => _variants.removeAt(index));
  }

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
            color: error ? Colors.red.shade100 : scheme.onPrimary,
          ),
        ),
        backgroundColor: error ? Colors.red.shade800 : null,
      ),
    );
  }

  Future<void> _save() async {
  if (!_formKey.currentState!.validate() || _isSaving) return;
  setState(() => _isSaving = true);

  try {
    final BackendProductRepository repo = BackendProductRepository();
    final Product product = await repo.createProduct(
      ProductCreateRequest(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        stock: _stock,
        category: _selectedCategory,
        weight: double.tryParse(_weightController.text.trim()),
        dimensions: _dimensionsController.text.trim(),
        tags: _parsedTags,
        isActive: _isActive,
        variants: _variants.map((_VariantEntry v) => ProductVariantRequest(
          variantName: v.name,
          price: double.tryParse(v.price) ?? 0,
          color: v.color.isEmpty ? null : v.color,  // ← null if empty
          size: v.size.isEmpty ? null : v.size,      // ← null if empty
        )).toList(),
        media: _mediaEntries.map((_MediaEntry m) => ProductMediaRequest(
          bytes: m.bytes,
          fileName: m.fileName,
          caption: m.caption,
          isPrimary: m.isPrimary,
          order: _mediaEntries.indexOf(m) + 1,
        )).toList(),
      ),
    );

    if (!mounted) return;
    _showSnack('Product "${product.name}" saved!');
   Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddProductPage(),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    _showSnack('Failed: $e', error: true);
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
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
            style: AppThemes.poppins(context, fontSize: 13, fontWeight: FontWeight.w700),
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
    final Color bgTop = isDark ? const Color(0xFF172026) : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;

    final InputDecorationTheme inputTheme = InputDecorationTheme(
      filled: true,
      fillColor: scheme.onPrimary.withOpacity(0.04),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: AppThemes.poppins(
        context,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface.withOpacity(0.64),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.15), width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.15), width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: scheme.primary.withOpacity(0.50), width: 1),
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

                  // ── Header ──────────────────────────────────────────────────
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Add Product',
                              style: AppThemes.poppins(context, fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Fill in details, variants, and media.',
                              style: AppThemes.poppins(
                                context,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurface.withOpacity(0.58),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── 1. Basic Info ────────────────────────────────────────────
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _sectionHeader('Basic Info', Icons.info_outline_rounded),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Product name *'),
                          validator: (String? v) =>
                              (v == null || v.trim().length < 3) ? 'At least 3 characters' : null,
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
                          value: _selectedCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Category'),
                          items: _categories
                              .map((String c) => DropdownMenuItem<String>(value: c, child: Text(c)))
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
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Price (ETB) *'),
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
                                decoration: const InputDecoration(labelText: 'Default stock'),
                                onChanged: (String v) =>
                                    _stock = int.tryParse(v.trim()) ?? 0,
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
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _dimensionsController,
                                decoration: const InputDecoration(
                                  labelText: 'Dimensions',
                                  hintText: '32x22x3',
                                  hintStyle: TextStyle(fontSize: 10, ),
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
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 17,
                              color: scheme.onSurface.withOpacity(0.55),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Active (visible to buyers)',
                                style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Transform.scale(
                              scale: 0.82,
                              child: Switch(
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                value: _isActive,
                                onChanged: (bool v) => setState(() => _isActive = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── 2. Media ─────────────────────────────────────────────────
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _sectionHeader('Media', Icons.photo_library_outlined),
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
                                  style: BorderStyle.solid,
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
                                      style: AppThemes.poppins(
                                        context,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.primary,
                                      ),
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
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (BuildContext context, int i) {
                                if (i == _mediaEntries.length) {
                                  return GestureDetector(
                                    onTap: _pickImages,
                                    child: Container(
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: scheme.primary.withOpacity(0.06),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: scheme.primary.withOpacity(0.20)),
                                      ),
                                      child: Icon(Icons.add_rounded, color: scheme.primary),
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
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: entry.isPrimary
                                                ? scheme.primary
                                                : scheme.onSurface.withOpacity(0.12),
                                            width: entry.isPrimary ? 2 : 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(11),
                                          child: Image.memory(entry.bytes, fit: BoxFit.cover),
                                        ),
                                      ),
                                    ),
                                    if (entry.isPrimary)
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: scheme.primary,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Primary',
                                            style: AppThemes.poppins(
                                              context,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w700,
                                              color: scheme.onPrimary,
                                            ),
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
                          const SizedBox(height: 6),
                          Text(
                            'Tap an image to set it as primary. Tap + to add more.',
                            style: AppThemes.poppins(
                              context,
                              fontSize: 9,
                              color: scheme.onSurface.withOpacity(0.50),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── 3. Variants ──────────────────────────────────────────────
                  _card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _sectionHeader('Variants', Icons.tune_rounded),
                            ),
                            TextButton.icon(
                              onPressed: _addVariant,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text(
                                'Add',
                                style: AppThemes.poppins(
                                    context, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        if (_variants.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No variants added. Tap "Add" if your product has sizes, colors, etc.',
                              style: AppThemes.poppins(
                                context,
                                fontSize: 11,
                                color: scheme.onSurface.withOpacity(0.50),
                                fontWeight: FontWeight.w500,
                              ),
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
                                border: Border.all(color: scheme.primary.withOpacity(0.12)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Text(
                                        'Variant ${i + 1}',
                                        style: AppThemes.poppins(
                                            context, fontSize: 11, fontWeight: FontWeight.w700),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () => _removeVariant(i),
                                        child: Icon(Icons.close_rounded,
                                            size: 17, color: Colors.red.shade400),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: v.name,
                                    decoration: const InputDecoration(
                                        labelText: 'Variant name (e.g. Red - Large)'),
                                    onChanged: (String val) => v.name = val,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: v.price,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(labelText: 'Price'),
                                          onChanged: (String val) => v.price = val,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: v.color,
                                          decoration: const InputDecoration(labelText: 'Color'),
                                          onChanged: (String val) => v.color = val,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          initialValue: v.size,
                                          decoration: const InputDecoration(labelText: 'Size'),
                                          onChanged: (String val) => v.size = val,
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

                  // ── Action buttons ───────────────────────────────────────────
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppThemes.poppins(
                                context, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
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
                                  'Save Product',
                                  style: AppThemes.poppins(
                                    context,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onPrimary,
                                  ),
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
