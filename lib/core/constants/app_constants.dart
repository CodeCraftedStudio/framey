class AppConstants {
  static const String appName = 'Framey';
  static const String appTagline = 'Your moments. Beautifully organized.';
  static const String packageName = 'com.framey.gallery';
  
  // Method Channel
  static const String mediaStoreChannel = 'com.framey.gallery/mediastore';
  
  // Pagination
  static const int defaultPageSize = 50;
  static const int thumbnailSize = 256;
  
  // Cache
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration cacheExpiration = Duration(days: 7);
  
  // Recycle Bin
  static const Duration recycleBinRetention = Duration(days: 30);
  
  // Animation
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
}
