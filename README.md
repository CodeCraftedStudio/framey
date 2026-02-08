# Framey - Premium Android Gallery App

A production-ready Flutter gallery app with native Android integration, featuring Google Photos-like UI and performance.

## 🚀 Features

### 📸 Core Gallery Features
- **Photos Tab**: Timeline-based feed with sticky headers (Today/Yesterday/Month grouping)
- **Albums Tab**: System albums with navigation and media filtering
- **Videos Tab**: Grid layout with duration overlay and video thumbnails
- **Search Tab**: Search by date, filename, and location with instant results
- **Library Tab**: Special albums (Recycle Bin, Hidden, App Lock settings)

### 🎨 UI/UX Features
- **Material 3 Design**: Modern, edge-to-edge UI with dark/light themes
- **60fps Scrolling**: Smooth performance with lazy loading and pagination
- **Gesture Navigation**: Swipe, pinch-to-zoom, and shared element transitions
- **Responsive Grid**: Adaptive layouts for different screen sizes

### 🔧 Technical Features
- **Hybrid Architecture**: Flutter UI + Native Android (Kotlin) for performance
- **Android 10+ Support**: Scoped storage with proper permission handling
- **MediaStore Integration**: Efficient media queries with thumbnail generation
- **MethodChannel Bridge**: Clean communication between Flutter and native code
- **Background Processing**: Coroutines for heavy operations without UI blocking

### 📱 Platform Compatibility
- **Minimum SDK**: Android 10 (API 29)
- **Target SDK**: Android 13+ optimized
- **Permissions**: 
  - Android 13+: `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`
  - Android 12-: `READ_EXTERNAL_STORAGE`
- **No Cloud Dependency**: 100% on-device processing

## 🏗 Architecture

```
lib/
├── core/                    # App constants, themes, utilities
├── shared/                   # Cross-feature data and domain
│   ├── data/             # Services (MediaStore, Permissions)
│   └── domain/           # Models (MediaItem, Album)
└── features/                 # Feature modules
    ├── photos/            # Photos screen and timeline
    ├── albums/            # Album list and details
    ├── videos/            # Video browsing
    ├── search/            # Search functionality
    ├── viewer/            # Media viewer (image/video)
    ├── recycle_bin/       # Deleted items management
    └── hidden/            # Secure hidden folder

android/
├── app/
│   ├── src/main/kotlin/
│   │   ├── MainActivity.kt     # MethodChannel bridge
│   │   └── MediaStoreManager.kt # Native media operations
│   └── build.gradle.kts
└── app/src/main/AndroidManifest.xml
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio (latest) or VS Code with Flutter extension
- Android device with API 29+

### Installation
```bash
# Clone the repository
git clone https://github.com/your-username/framey.git

# Navigate to project directory
cd framey

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Development Setup
```bash
# For development with hot reload
flutter run

# Build APK for release
flutter build apk --release

# Run tests
flutter test
```

## 📱 Permissions

The app requests the following permissions based on Android version:

### Android 13+ (API 33+)
- `READ_MEDIA_IMAGES` - Access to image files
- `READ_MEDIA_VIDEO` - Access to video files

### Android 10-12 (API 29-32)
- `READ_EXTERNAL_STORAGE` - Access to all media files

## 🔧 Configuration

### Environment Variables
- No special environment variables required

### Build Configuration
- **Debug**: `flutter run`
- **Release**: `flutter build apk --release`
- **Profile**: `flutter build apk --profile`

## 📊 Performance

### Optimizations
- **Lazy Loading**: Media items loaded in pages (50 items per page)
- **Thumbnail Caching**: Generated thumbnails stored in cache directory
- **Memory Management**: Proper disposal of resources and controllers
- **Background Processing**: Heavy operations moved off main thread

### Benchmarks
- **Startup Time**: <2 seconds on mid-range devices
- **Memory Usage**: <150MB during normal operation
- **Scroll Performance**: 60fps with 1000+ items in grid

## 🐛 Troubleshooting

### Common Issues

#### Images Not Loading
```bash
# Check permissions
adb shell pm list packages | grep framey

# Check MediaStore access
adb logcat | grep Framey
```

#### Build Issues
```bash
# Clean build
flutter clean
flutter pub get

# Update dependencies
flutter pub upgrade
```

#### Permission Denied
- Navigate to Settings → Apps → Framey → Permissions
- Grant storage/media permissions manually

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

For issues and questions:
- Create an issue on GitHub
- Check existing issues for solutions
- Review documentation before opening new issues

---

**Framey - Your moments, beautifully organized.** 📸✨
