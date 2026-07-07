/// Flutter Configuration Helper - Environment-specific API URLs
///
/// Usage: Update [devBackendUrl] with your computer's IP address
/// Then use Environment.getBackendUrl() throughout the app
library;

class Environment {
  Environment._(); // Private constructor to prevent instantiation

  // ===== CONFIGURATION SECTION =====
  // IMPORTANT: Update devBackendUrl with your machine's IPv4 address
  // Find it on Windows with: ipconfig
  // Look for "IPv4 Address . . . . . . . . . . . : 192.168.x.x"

  /// Development backend (update with YOUR machine's IP)
  /// Find your IP: Windows (ipconfig) / Mac (ifconfig) / Linux (hostname -I)
  static const String devBackendUrl = 'http://localhost:8000';

  /// Production backend
  static const String prodBackendUrl = 'https://api.yourdomain.com';

  /// Android emulator (default AVD)
  /// Access host machine's localhost via 10.0.2.2
  static const String androidEmulatorUrl = 'http://10.0.2.2:8000';

  /// iOS simulator (can access localhost directly)
  static const String iosSimulatorUrl = 'http://localhost:8000';

  /// Get the appropriate backend URL for current environment
  /// Priority:
  /// 1. Environment variable (API_BASE_URL)
  /// 2. Device-specific defaults
  static String getBackendUrl() {
    // Check if environment variable was set at build time
    const String envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Use sensible defaults based on context
    // In production, you'd check kReleaseMode or similar
    return devBackendUrl;
  }

  /// Validate URL before using
  static bool isValidUrl(String url) {
    try {
      Uri.parse(url);
      return url.contains('http://') || url.contains('https://');
    } catch (_) {
      return false;
    }
  }

  /// Get URL with trailing slash normalized
  static String normalizeUrl(String url) {
    return url.endsWith('/') ? url : '$url/';
  }

  /// Check if running on emulator (useful for URL switching)
  static const String emulatorCheck = 'EMULATOR_VERSION';

  /// Available URLs for debugging/testing
  static const Map<String, String> urlPresets = {
    'Development (192.168.x.x)': devBackendUrl,
    'Android Emulator': androidEmulatorUrl,
    'iOS Simulator': iosSimulatorUrl,
    'Production': prodBackendUrl,
    'Localhost': 'http://localhost:8000',
  };
}

// ===== FLUTTER RUN COMMANDS =====
// Copy-paste these commands to run with different backends:

// Command 1: Physical Android Device (update IP)
// flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000

// Command 2: Android Emulator
// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

// Command 3: iOS Simulator
// flutter run --dart-define=API_BASE_URL=http://localhost:8000

// Command 4: Production
// flutter run --dart-define=API_BASE_URL=https://api.yourdomain.com

// ===== FINDING YOUR COMPUTER'S IP =====
// Windows Command Prompt:
//   ipconfig
//   Look for: "IPv4 Address . . . . . . . . . . . : 192.168.x.x"
//
// macOS Terminal:
//   ifconfig
//   Look for: "inet 192.168.x.x"
//
// Linux Terminal:
//   hostname -I
//   Returns: 192.168.x.x
//
// Docker Container (get host IP):
//   docker exec shikela_web hostname -I
