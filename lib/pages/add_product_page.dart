import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shop_manager/theme/app_themes.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  final List<String> _categories = <String>[
    'General',
    'Electronics',
    'Fashion',
    'Beauty',
    'Food',
  ];

  String _selectedCategory = 'General';
  bool _featured = false;
  bool _trackInventory = true;
  double _discountPercent = 0;
  int _reorderLevel = 6;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _toDouble(String value) => double.tryParse(value.trim()) ?? 0;
  int _toInt(String value) => int.tryParse(value.trim()) ?? 0;

  String _money(double value) => 'ETB ${value.toStringAsFixed(2)}';

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null || !mounted) {
        return;
      }
      final Uint8List bytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    } on PlatformException catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open gallery. Check app permissions and try again.',
            style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _nameController.clear();
      _priceController.clear();
      _stockController.clear();
      _noteController.clear();
      _selectedImage = null;
      _selectedImageBytes = null;
      _selectedCategory = 'General';
      _featured = false;
      _trackInventory = true;
      _discountPercent = 0;
      _reorderLevel = 6;
    });
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final double price = _toDouble(_priceController.text);
    final double salePrice = price * (1 - (_discountPercent / 100));
    final int stock = _toInt(_stockController.text);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Product "${_nameController.text.trim()}" saved | Sale ${_money(salePrice)} | Stock $stock${_selectedImage != null ? ' | Image selected' : ''}',
          style: AppThemes.poppins(
            context,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: scheme.onPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop = isDark ? const Color(0xFF172026) : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;
    final double price = _toDouble(_priceController.text);
    final int stock = _toInt(_stockController.text);
    final double salePrice = price * (1 - (_discountPercent / 100));
    final bool lowStock = _trackInventory && stock <= _reorderLevel;
    final InputDecorationTheme boxInputTheme = InputDecorationTheme(
      filled: true,
      fillColor: scheme.onPrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: AppThemes.poppins(
        context,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface.withOpacity(0.52),
      ),
      labelStyle: AppThemes.poppins(
        context,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface.withOpacity(0.64),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.16), width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.onSurface.withOpacity(0.16), width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary.withOpacity(0.40), width: 1),
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
            stops: const <double>[0.0, 0.22, 1.0],
          ),
        ),
        child: SafeArea(
          child: Theme(
            data: Theme.of(context).copyWith(inputDecorationTheme: boxInputTheme),
            child: Form(
              key: _formKey,
              child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: <Widget>[
                Text(
                  'Add Product',
                  style: AppThemes.poppins(
                    context,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create product details, pricing, inventory, and launch settings in one place.',
                  style: AppThemes.poppins(
                    context,
                    fontSize: 12,
                    color: scheme.onSurface.withOpacity(0.68),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Live Preview', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: scheme.primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _selectedImageBytes == null
                                ? Icon(Icons.inventory_2_rounded, color: scheme.primary, size: 30)
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _selectedImageBytes!,
                                      fit: BoxFit.cover,
                                      width: 54,
                                      height: 54,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _nameController.text.trim().isEmpty ? 'Product name' : _nameController.text.trim(),
                                  style: AppThemes.poppins(context, fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  _selectedCategory,
                                  style: AppThemes.poppins(context, fontSize: 11, color: scheme.onSurface.withOpacity(0.62)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  price > 0 ? _money(salePrice) : 'Set price',
                                  style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1B8F4D)),
                                ),
                              ],
                            ),
                          ),
                          if (_featured)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B8F4D).withOpacity(0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Featured',
                                style: AppThemes.poppins(context, fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF1B8F4D)),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lowStock ? 'Stock alert: reorder soon' : 'Inventory looks healthy',
                        style: AppThemes.poppins(
                          context,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: lowStock ? const Color(0xFFC62828) : const Color(0xFF1B8F4D),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (String? value) => (value == null || value.trim().length < 3) ? 'Enter at least 3 characters' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.map((String category) => DropdownMenuItem<String>(value: category, child: Text(category))).toList(),
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _selectedCategory = value);
                  },
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.onPrimary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.onSurface.withOpacity(0.16), width: 0.5),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _selectedImage == null ? 'No image selected' : _selectedImage!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppThemes.poppins(
                            context,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface.withOpacity(0.66),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _pickImageFromGallery,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: scheme.onSurface.withOpacity(0.16), width: 0.5),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        child: Text(
                          'Choose Image',
                          style: AppThemes.poppins(context, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'Price'),
                        validator: (String? value) => _toDouble(value ?? '') <= 0 ? 'Enter a valid price' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'Stock'),
                        validator: (String? value) => _toInt(value ?? '') < 0 ? 'Invalid stock' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.onSurface.withOpacity(0.09)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Discount ${_discountPercent.toStringAsFixed(0)}%',
                              style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            price > 0 ? _money(salePrice) : '-',
                            style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1B8F4D)),
                          ),
                        ],
                      ),
                      Slider(
                        value: _discountPercent,
                        min: 0,
                        max: 40,
                        divisions: 20,
                        label: '${_discountPercent.toStringAsFixed(0)}%',
                        onChanged: (double value) => setState(() => _discountPercent = value),
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    'Featured',
                                    style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.80,
                                  child: Switch(
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    value: _featured,
                                    onChanged: (bool value) => setState(() => _featured = value),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    'Track stock',
                                    style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.80,
                                  child: Switch(
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    value: _trackInventory,
                                    onChanged: (bool value) => setState(() => _trackInventory = value),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4,),
                      if (_trackInventory) ...<Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Reorder Level: $_reorderLevel units',
                                style: AppThemes.poppins(context, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _reorderLevel.toDouble(),
                          min: 1,
                          max: 40,
                          divisions: 39,
                          label: '$_reorderLevel',
                          onChanged: (double value) => setState(() => _reorderLevel = value.round()),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Internal Note',
                    alignLabelWithHint: true,
                    hintText: 'Write quick launch notes for your team...',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetForm,
                        child: Text('Reset', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        child: Text('Save Product', style: AppThemes.poppins(context, fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onPrimary)),
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
