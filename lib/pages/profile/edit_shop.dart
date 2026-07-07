import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shop_manager/theme/app_themes.dart';

// ─── Lightweight models (local, mirrors backend shape) ────────────────────────

class ThemeOption {
  const ThemeOption({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.version,
    this.previewImageUrl,
  });
  final int id;
  final String name;
  final String slug;
  final String description;
  final String version;
  final String? previewImageUrl;
}

class ShopThemeSettingsLocal {
  ShopThemeSettingsLocal({
    this.primaryColor = '#000000',
    this.secondaryColor = '#ffffff',
    this.fontFamily = 'Arial',
    this.logoUrl,
    this.bannerUrl,
  });
  String primaryColor;
  String secondaryColor;
  String fontFamily;
  String? logoUrl;
  String? bannerUrl;
}

class ShopLocal {
  ShopLocal({
    required this.id,
    required this.name,
    required this.description,
    this.domain,
    this.selectedThemeId,
    required this.themeSettings,
  });
  final String id;
  String name;
  String description;
  String? domain;
  int? selectedThemeId;
  ShopThemeSettingsLocal themeSettings;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class EditShopPage extends StatefulWidget {
  const EditShopPage({super.key, required this.shop});
  final ShopLocal shop;

  @override
  State<EditShopPage> createState() => _EditShopPageState();
}

class _EditShopPageState extends State<EditShopPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── Controllers ──────────────────────────────────────────────────────────────
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _domainCtrl;
  late final TextEditingController _primaryColorCtrl;
  late final TextEditingController _secondaryColorCtrl;
  late final TextEditingController _fontFamilyCtrl;

  // Theme
  int? _selectedThemeId;

  // Image state
  Uint8List? _logoBytes;
  String? _logoFileName;
  Uint8List? _bannerBytes;
  String? _bannerFileName;

  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  // Mock themes — replace with API call
  final List<ThemeOption> _availableThemes = const <ThemeOption>[
    ThemeOption(id: 1, name: 'Minimal', slug: 'minimal',
        description: 'Clean and simple storefront', version: '1.0'),
    ThemeOption(id: 2, name: 'Bold Market', slug: 'bold-market',
        description: 'High contrast, vibrant colours', version: '1.2'),
    ThemeOption(id: 3, name: 'Elegant', slug: 'elegant',
        description: 'Sophisticated layout for premium goods', version: '2.0'),
    ThemeOption(id: 4, name: 'Street', slug: 'street',
        description: 'Urban vibe for fashion & lifestyle', version: '1.1'),
  ];

  final List<String> _fontOptions = const <String>[
    'Arial', 'Roboto', 'Poppins', 'Inter',
    'Merriweather', 'Playfair Display', 'Montserrat',
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final ShopLocal s = widget.shop;
    _nameCtrl          = TextEditingController(text: s.name)         ..addListener(_rebuild);
    _descCtrl          = TextEditingController(text: s.description)  ..addListener(_rebuild);
    _domainCtrl        = TextEditingController(text: s.domain ?? '') ..addListener(_rebuild);
    _primaryColorCtrl  = TextEditingController(
        text: s.themeSettings.primaryColor)                          ..addListener(_rebuild);
    _secondaryColorCtrl = TextEditingController(
        text: s.themeSettings.secondaryColor)                        ..addListener(_rebuild);
    _fontFamilyCtrl    = TextEditingController(
        text: s.themeSettings.fontFamily)                            ..addListener(_rebuild);

    _selectedThemeId = s.selectedThemeId;
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _domainCtrl.dispose();
    _primaryColorCtrl.dispose();
    _secondaryColorCtrl.dispose();
    _fontFamilyCtrl.dispose();
    super.dispose();
  }

  // ── Image helpers ─────────────────────────────────────────────────────────────

  Future<void> _pickLogo() async {
    try {
      final XFile? f = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 90);
      if (f == null || !mounted) return;
      final Uint8List bytes = await f.readAsBytes();
      setState(() { _logoBytes = bytes; _logoFileName = f.name; });
    } on PlatformException catch (_) {
      _snack('Could not open gallery. Check permissions.');
    }
  }

  Future<void> _pickBanner() async {
    try {
      final XFile? f = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 85);
      if (f == null || !mounted) return;
      final Uint8List bytes = await f.readAsBytes();
      setState(() { _bannerBytes = bytes; _bannerFileName = f.name; });
    } on PlatformException catch (_) {
      _snack('Could not open gallery. Check permissions.');
    }
  }

  // ── Colour helpers ────────────────────────────────────────────────────────────

  Color _parseHex(String hex, {Color fallback = Colors.black}) {
    try {
      final String clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {}
    return fallback;
  }

  bool _isValidHex(String v) =>
      RegExp(r'^#([0-9A-Fa-f]{6})$').hasMatch(v.trim());

  // ── Save ──────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_isSaving) return;
    if (_nameCtrl.text.trim().length < 2) {
      _snack('Shop name must be at least 2 characters.', error: true);
      _tabController.animateTo(0);
      return;
    }
    if (!_isValidHex(_primaryColorCtrl.text) ||
        !_isValidHex(_secondaryColorCtrl.text)) {
      _snack('Colours must be valid hex codes, e.g. #3A7D44', error: true);
      _tabController.animateTo(2);
      return;
    }

    setState(() => _isSaving = true);
    try {
      // TODO: call your BackendShopRepository.updateShop(...)
      await Future<void>.delayed(const Duration(seconds: 1)); // stub
      if (!mounted) return;
      _snack('Shop updated successfully!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    final ColorScheme s = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: AppThemes.poppins(context,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: error ? Colors.red.shade100 : s.onPrimary)),
      backgroundColor: error ? Colors.red.shade800 : null,
    ));
  }

  // ── Live preview ──────────────────────────────────────────────────────────────

  Widget _buildPreview() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String name   = _nameCtrl.text.trim();
    final String domain = _domainCtrl.text.trim();
    final Color primary = _parseHex(_primaryColorCtrl.text,
        fallback: scheme.primary);
    final Color secondary = _parseHex(_secondaryColorCtrl.text,
        fallback: scheme.surface);
    final ThemeOption? selectedTheme = _availableThemes
        .cast<ThemeOption?>()
        .firstWhere((ThemeOption? t) => t?.id == _selectedThemeId,
            orElse: () => null);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2A20) : const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[

          // Preview label
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(Icons.storefront_outlined,
                      size: 14, color: scheme.primary),
                ),
                const SizedBox(width: 7),
                Text('Shop Preview',
                    style: AppThemes.poppins(context,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary)),
                const Spacer(),
                if (selectedTheme != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(selectedTheme.name,
                        style: AppThemes.poppins(context,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: primary)),
                  ),
              ],
            ),
          ),

          // Storefront mockup
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[

                  // Banner
                  Stack(
                    children: <Widget>[
                      Container(
                        height: 80,
                        width: double.infinity,
                        color: primary.withOpacity(0.15),
                        child: _bannerBytes != null
                            ? Image.memory(_bannerBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity)
                            : widget.shop.themeSettings.bannerUrl != null
                                ? Image.network(
                                    widget.shop.themeSettings.bannerUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (_, __, ___) =>
                                        _bannerPlaceholder(primary),
                                  )
                                : _bannerPlaceholder(primary),
                      ),
                      // Logo overlay
                      Positioned(
                        bottom: -20,
                        left: 14,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: secondary,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 3),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _logoBytes != null
                                ? Image.memory(_logoBytes!, fit: BoxFit.cover)
                                : widget.shop.themeSettings.logoUrl != null
                                    ? Image.network(
                                        widget.shop.themeSettings.logoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _logoPlaceholder(primary),
                                      )
                                    : _logoPlaceholder(primary),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Shop name + domain + desc
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          name.isEmpty ? 'Your shop name...' : name,
                          style: AppThemes.poppins(context,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: name.isEmpty
                                  ? scheme.onSurface.withOpacity(0.28)
                                  : scheme.onSurface),
                        ),
                        if (domain.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 2),
                          Row(
                            children: <Widget>[
                              Icon(Icons.link_rounded,
                                  size: 11,
                                  color: primary.withOpacity(0.7)),
                              const SizedBox(width: 3),
                              Text(domain,
                                  style: AppThemes.poppins(context,
                                      fontSize: 10,
                                      color: primary.withOpacity(0.7),
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        if (_descCtrl.text.trim().isNotEmpty)
                          Text(_descCtrl.text.trim(),
                              style: AppThemes.poppins(context,
                                  fontSize: 10,
                                  color: scheme.onSurface.withOpacity(0.55),
                                  fontWeight: FontWeight.w400),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 10),
                        // Colour swatches
                        Row(
                          children: <Widget>[
                            _swatch(primary, 'Primary'),
                            const SizedBox(width: 8),
                            _swatch(secondary, 'Secondary',
                                bordered: true),
                            const Spacer(),
                            Text(
                              _fontFamilyCtrl.text.trim().isEmpty
                                  ? 'Arial'
                                  : _fontFamilyCtrl.text.trim(),
                              style: AppThemes.poppins(context,
                                  fontSize: 9,
                                  color: scheme.onSurface.withOpacity(0.4),
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.text_fields_rounded,
                                size: 12,
                                color: scheme.onSurface.withOpacity(0.35)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerPlaceholder(Color primary) => Center(
        child: Icon(Icons.panorama_outlined,
            color: primary.withOpacity(0.25), size: 32),
      );

  Widget _logoPlaceholder(Color primary) => Center(
        child: Icon(Icons.storefront_outlined,
            color: primary.withOpacity(0.5), size: 22),
      );

  Widget _swatch(Color color, String label, {bool bordered = false}) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: bordered
                ? Border.all(color: scheme.onSurface.withOpacity(0.2))
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: AppThemes.poppins(context,
                fontSize: 9,
                color: scheme.onSurface.withOpacity(0.45),
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── Section header ────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
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
          Text(title,
              style: AppThemes.poppins(context,
                  fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.onSurface.withOpacity(0.09)),
      ),
      child: child,
    );
  }

  // ── Tab 1 — Basic Info ────────────────────────────────────────────────────────

  Widget _buildBasicTab() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _sectionHeader('Shop Info', Icons.store_outlined),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Shop name *'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _domainCtrl,
                decoration: InputDecoration(
                  labelText: 'Custom domain',
                  hintText: 'myshop.shikela.com',
                  hintStyle: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withOpacity(0.35)),
                  prefixIcon: Icon(Icons.link_rounded,
                      size: 17, color: scheme.onSurface.withOpacity(0.45)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 2 — Theme ─────────────────────────────────────────────────────────────

  Widget _buildThemeTab() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _sectionHeader('Choose Theme', Icons.palette_outlined),
              ...List<Widget>.generate(_availableThemes.length, (int i) {
                final ThemeOption t = _availableThemes[i];
                final bool selected = _selectedThemeId == t.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedThemeId = t.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected
                          ? scheme.primary.withOpacity(0.08)
                          : scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? scheme.primary
                            : scheme.onSurface.withOpacity(0.12),
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        // Theme colour dot placeholder
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: scheme.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.web_outlined,
                              color: scheme.primary.withOpacity(0.6),
                              size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Text(t.name,
                                      style: AppThemes.poppins(context,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color:
                                          scheme.onSurface.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('v${t.version}',
                                        style: AppThemes.poppins(context,
                                            fontSize: 8,
                                            color: scheme.onSurface
                                                .withOpacity(0.45),
                                            fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(t.description,
                                  style: AppThemes.poppins(context,
                                      fontSize: 10,
                                      color:
                                          scheme.onSurface.withOpacity(0.55),
                                      fontWeight: FontWeight.w400)),
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check_circle_rounded,
                              color: scheme.primary, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tab 3 — Appearance ────────────────────────────────────────────────────────

  Widget _buildAppearanceTab() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: <Widget>[

        // ── Logo ────────────────────────────────────────────────────────────
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _sectionHeader('Logo', Icons.image_outlined),
              Row(
                children: <Widget>[
                  // Current logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: scheme.onSurface.withOpacity(0.12)),
                    ),
                    child: ClipOval(
                      child: _logoBytes != null
                          ? Image.memory(_logoBytes!, fit: BoxFit.cover)
                          : widget.shop.themeSettings.logoUrl != null
                              ? Image.network(
                                  widget.shop.themeSettings.logoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                      Icons.storefront_outlined,
                                      color:
                                          scheme.onSurface.withOpacity(0.3)),
                                )
                              : Icon(Icons.storefront_outlined,
                                  color: scheme.onSurface.withOpacity(0.3),
                                  size: 30),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Shop logo',
                            style: AppThemes.poppins(context,
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text('Square image recommended.\nDisplayed as a circle.',
                            style: AppThemes.poppins(context,
                                fontSize: 10,
                                color: scheme.onSurface.withOpacity(0.5),
                                fontWeight: FontWeight.w400)),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _pickLogo,
                          icon: const Icon(Icons.upload_rounded, size: 15),
                          label: Text(
                            _logoBytes != null ? 'Change logo' : 'Upload logo',
                            style: AppThemes.poppins(context,
                                fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Banner ───────────────────────────────────────────────────────────
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _sectionHeader('Banner Image', Icons.panorama_outlined),
              GestureDetector(
                onTap: _pickBanner,
                child: Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: scheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: scheme.primary.withOpacity(0.20)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _bannerBytes != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            Image.memory(_bannerBytes!, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit_rounded,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      : widget.shop.themeSettings.bannerUrl != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                Image.network(
                                    widget.shop.themeSettings.bannerUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _bannerUploadHint(scheme)),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit_rounded,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            )
                          : _bannerUploadHint(scheme),
                ),
              ),
              const SizedBox(height: 6),
              Text('Recommended: 1200 × 300 px',
                  style: AppThemes.poppins(context,
                      fontSize: 9,
                      color: scheme.onSurface.withOpacity(0.4),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),

        // ── Colours ──────────────────────────────────────────────────────────
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _sectionHeader('Brand Colours', Icons.color_lens_outlined),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextFormField(
                          controller: _primaryColorCtrl,
                          decoration: InputDecoration(
                            labelText: 'Primary',
                            hintText: '#3A7D44',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _parseHex(
                                      _primaryColorCtrl.text,
                                      fallback: Colors.black),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.black.withOpacity(0.1)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!_isValidHex(_primaryColorCtrl.text) &&
                            _primaryColorCtrl.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text('Invalid hex',
                                style: AppThemes.poppins(context,
                                    fontSize: 10,
                                    color: Colors.red.shade400,
                                    fontWeight: FontWeight.w500)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        TextFormField(
                          controller: _secondaryColorCtrl,
                          decoration: InputDecoration(
                            labelText: 'Secondary',
                            hintText: '#FFFFFF',
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: _parseHex(
                                      _secondaryColorCtrl.text,
                                      fallback: Colors.white),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.black.withOpacity(0.1)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!_isValidHex(_secondaryColorCtrl.text) &&
                            _secondaryColorCtrl.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text('Invalid hex',
                                style: AppThemes.poppins(context,
                                    fontSize: 10,
                                    color: Colors.red.shade400,
                                    fontWeight: FontWeight.w500)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Font ────────────────────────────────────────────────────────────
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _sectionHeader('Font Family', Icons.text_fields_rounded),
              DropdownButtonFormField<String>(
                initialValue: _fontOptions.contains(_fontFamilyCtrl.text)
                    ? _fontFamilyCtrl.text
                    : _fontOptions.first,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Font'),
                items: _fontOptions
                    .map((String f) =>
                        DropdownMenuItem<String>(value: f, child: Text(f)))
                    .toList(),
                onChanged: (String? v) {
                  if (v != null) {
                    _fontFamilyCtrl.text = v;
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bannerUploadHint(ColorScheme scheme) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.add_photo_alternate_outlined,
                color: scheme.primary, size: 28),
            const SizedBox(height: 6),
            Text('Tap to upload banner',
                style: AppThemes.poppins(context,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary)),
          ],
        ),
      );

  // ── Main build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop    = isDark ? const Color(0xFF172026) : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;

    final InputDecorationTheme inputTheme = InputDecorationTheme(
      filled: true,
      fillColor: scheme.onPrimary.withOpacity(0.04),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: AppThemes.poppins(context,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface.withOpacity(0.64)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
            color: scheme.onSurface.withOpacity(0.15), width: 0.8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
            color: scheme.onSurface.withOpacity(0.15), width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
            color: scheme.primary.withOpacity(0.50), width: 1),
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
            stops: const <double>[0.0, 0.20, 1.0],
          ),
        ),
        child: SafeArea(
          child: Theme(
            data: Theme.of(context)
                .copyWith(inputDecorationTheme: inputTheme),
            child: Column(
              children: <Widget>[

                // ── Top bar ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Edit Shop',
                                style: AppThemes.poppins(context,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            Text('Changes apply to your storefront.',
                                style: AppThemes.poppins(context,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        scheme.onSurface.withOpacity(0.55))),
                          ],
                        ),
                      ),
                      // Save button in top bar
                      ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.onPrimary,
                                ),
                              )
                            : Text('Save',
                                style: AppThemes.poppins(context,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onPrimary)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Live preview ────────────────────────────────────────────
                _buildPreview(),

                const SizedBox(height: 14),

                // ── Tabs ────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: scheme.primary,
                      unselectedLabelColor:
                          scheme.onSurface.withOpacity(0.5),
                      labelStyle: AppThemes.poppins(context,
                          fontSize: 11, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: AppThemes.poppins(context,
                          fontSize: 11, fontWeight: FontWeight.w500),
                      padding: const EdgeInsets.all(4),
                      tabs: const <Tab>[
                        Tab(text: 'Info'),
                        Tab(text: 'Theme'),
                        Tab(text: 'Appearance'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // ── Tab content ─────────────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: <Widget>[
                      _buildBasicTab(),
                      _buildThemeTab(),
                      _buildAppearanceTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}