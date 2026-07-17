class ShopThemeSettings {
  const ShopThemeSettings({
    this.primaryColor = '#000000',
    this.secondaryColor = '#ffffff',
    this.fontFamily = 'Arial',
    this.logo,
    this.bannerImage,
  });

  final String primaryColor;
  final String secondaryColor;
  final String fontFamily;
  final String? logo;
  final String? bannerImage;

  factory ShopThemeSettings.fromJson(Map<String, dynamic> json) {
    return ShopThemeSettings(
      primaryColor: json['primary_color']?.toString() ?? '#000000',
      secondaryColor: json['secondary_color']?.toString() ?? '#ffffff',
      fontFamily: json['font_family']?.toString() ?? 'Arial',
      logo: json['logo']?.toString(),
      bannerImage: json['banner_image']?.toString(),
    );
  }
}

class ShopTheme {
  const ShopTheme({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.version,
    this.previewImage,
    this.logoUrl,
  });

  final int id;
  final String name;
  final String slug;
  final String description;
  final String version;
  final String? previewImage;
  final String? logoUrl;

  factory ShopTheme.fromJson(Map<String, dynamic> json) {
    return ShopTheme(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      previewImage: json['preview_image']?.toString(),
      logoUrl: json['logo_url']?.toString(),
    );
  }
}

class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.description,
    this.domain,
    this.theme,
    required this.themeSettings,
  });

  final String id;
  final String name;
  final String description;
  final String? domain;
  final ShopTheme? theme;
  final ShopThemeSettings themeSettings;

  factory Shop.fromJson(Map<String, dynamic> json) {
    final dynamic themeRaw = json['theme'];
    final dynamic settingsRaw = json['theme_settings'];

    return Shop(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      domain: json['domain']?.toString(),
      theme: themeRaw is Map<String, dynamic>
          ? ShopTheme.fromJson(themeRaw)
          : null,
      themeSettings: settingsRaw is Map<String, dynamic>
          ? ShopThemeSettings.fromJson(settingsRaw)
          : const ShopThemeSettings(),
    );
  }
}