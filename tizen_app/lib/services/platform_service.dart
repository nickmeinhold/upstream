enum TvPlatform { webos, tizen, web, unknown }

/// Platform service for Tizen TV - always returns Tizen
class PlatformService {
  /// Detect the current TV platform
  static TvPlatform detectPlatform() {
    // This is a native Tizen app, always return Tizen
    return TvPlatform.tizen;
  }

  /// Check if running on a TV platform (WebOS or Tizen)
  static bool get isTvPlatform => true;

  /// Check if running on LG WebOS
  static bool get isWebOS => false;

  /// Check if running on Samsung Tizen
  static bool get isTizen => true;

  /// Get platform name for display
  static String get platformName => 'Samsung Tizen';
}
