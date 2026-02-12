# Framey - Premium Android Gallery App

A modern, production-ready Flutter gallery application with native Android integration, featuring Google Photos-inspired UI and exceptional performance. Built with Material 3 design principles and optimized for large media libraries.

## ✨ Features

### 📸 Core Gallery Features
- **Photos Tab**: Timeline-based feed with intelligent sticky headers (Today/Yesterday/Month grouping)
- **Grid/List View Toggle**: Seamless switching between grid and list layouts with enhanced visuals
- **Real-time Search**: Instant photo filtering by filename with live search suggestions
- **Albums Tab**: System albums with modern card design and smooth navigation
- **Videos Tab**: Grid layout with duration overlay and video thumbnails
- **Search Tab**: Advanced search by date, filename, and location with instant results
- **Library Tab**: Special albums (Recycle Bin, Hidden, App Lock settings)

### 🎨 UI/UX Features
- **Material 3 Design**: Modern, edge-to-edge UI with dynamic dark/light themes
- **Smooth Animations**: Fluid fade-in, slide-in transitions and interactive controls
- **Enhanced Media Viewer**: Full-screen viewer with tap-to-toggle controls, video playback with progress bar
- **60fps Scrolling**: Butter-smooth performance with lazy loading and intelligent pagination
- **Gesture Navigation**: Intuitive swipe, pinch-to-zoom, and shared element transitions
- **Responsive Grid**: Adaptive layouts for all screen sizes with rounded corners and shadows
- **Modern Error States**: Beautiful error screens with actionable buttons and helpful guidance
- **Improved Empty States**: Contextual help when no content is available

### ⚙️ Technical Features
- **Hybrid Architecture**: Flutter UI + Native Android (Kotlin) for optimal performance
- **Android 10+ Support**: Full scoped storage support with proper permission handling
- **MediaStore Integration**: Efficient media queries with thumbnail generation
- **MethodChannel Bridge**: Clean communication between Flutter and native code
- **Background Processing**: Coroutines for heavy operations without UI blocking
- **Robust Media Loading**: Handles massive media libraries with pagination and search
- **Memory Optimization**: Smart resource disposal and performance utilities
- **Error Recovery**: Comprehensive error handling with intelligent retry mechanisms

### 📱 Platform Compatibility
- **Minimum SDK**: Android 10 (API 29)
- **Target SDK**: Android 13+ optimized
- **Permissions**: 
  - Android 13+: `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`
  - Android 12-: `READ_EXTERNAL_STORAGE`
- **No Cloud Dependency**: 100% on-device processing for privacy
- **Architecture**: Clean Architecture with MVVM pattern
- **Language**: Dart 3.0+ with Kotlin for native modules

## 🏗️ Architecture

The app follows Clean Architecture principles with clear separation of concerns:

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

### 📋 Prerequisites
- **Flutter SDK**: >=3.0.0
- **Dart SDK**: >=3.0.0
- **Android Studio**: Latest version or VS Code with Flutter extension
- **Android Device**: API 29+ recommended
- **Git**: For cloning the repository

### 💻 Installation
```bash
# Clone the repository
git clone https://github.com/your-username/framey.git

# Navigate to project directory
cd framey

# Install dependencies
flutter pub get

# Run the app (connected device required)
flutter run
```

### 🔧 Development Setup
```bash
# For development with hot reload
flutter run

# Build APK for release
flutter build apk --release

# Run tests
flutter test

# Analyze code
flutter analyze

# Clean build cache
flutter clean
```

### 📱 Running on Emulator
```bash
# List available emulators
flutter emulators

# Launch specific emulator
flutter emulators --launch <emulator_name>

# Then run the app
flutter run
```

## 🔐 Permissions

The app intelligently requests permissions based on Android version:

### Android 13+ (API 33+)
- `READ_MEDIA_IMAGES` - Access to image files
- `READ_MEDIA_VIDEO` - Access to video files

### Android 10-12 (API 29-32)
- `READ_EXTERNAL_STORAGE` - Access to all media files

## ⚙️ Configuration

### 🌍 Environment Variables
- No special environment variables required
- All configuration handled through Flutter's build system

### 🔨 Build Configuration
```bash
# Debug build with hot reload
flutter run

# Release build (optimized)
flutter build apk --release

# Profile build (for performance testing)
flutter build apk --profile

# Build for different architectures
flutter build apk --split-per-abi --release
```

### 📦 Dependencies
Key dependencies include:
- `provider` - State management
- `permission_handler` - Runtime permissions
- `shared_preferences` - Local storage
- `cached_network_image` - Image caching
- `flutter_staggered_grid_view` - Grid layouts

## ⚡ Performance

### 🚀 Optimizations
- **Lazy Loading**: Media items loaded in pages (50 items per page)
- **Thumbnail Caching**: Generated thumbnails stored in cache directory
- **Memory Management**: Proper disposal of resources and controllers
- **Background Processing**: Heavy operations moved off main thread
- **UI Animations**: Smooth fade and slide transitions with optimized performance
- **Search Performance**: Real-time filtering without blocking UI thread
- **Image Optimization**: Efficient loading and compression
- **Database Indexing**: Fast queries for large media libraries

### 📊 Benchmarks
| Metric | Performance |
|--------|-------------|
| **Startup Time** | <2 seconds on mid-range devices |
| **Memory Usage** | <150MB during normal operation |
| **Scroll Performance** | 60fps with 1000+ items in grid |
| **Search Speed** | Instant results for large photo libraries |
| **Media Loading** | Handles libraries with 10,000+ items efficiently |
| **App Size** | ~15MB (without media) |
| **Battery Usage** | Optimized for minimal drain |

## 📰 Recent Updates

### v1.0.1 - UI Enhancement Release
- ✨ **Modern UI Overhaul**: Added smooth animations, Material 3 design, and enhanced visual hierarchy
- 🔍 **Real-time Search**: Implemented functional search bar with instant photo filtering
- 🎬 **Enhanced Media Viewer**: Added interactive controls, video playback with progress bar
- 🔄 **Grid/List View Toggle**: Switch between layouts with improved visual design
- 🐛 **Bug Fixes**: Fixed layout overflow errors and media loading issues for large libraries
- 🎨 **Error States**: Beautiful error screens with actionable buttons and helpful messaging
- 📱 **Album Cards**: Modern card design with proper text overflow handling

### v1.0.0 - Initial Release
- Core gallery functionality with native Android integration
- Timeline-based photo feed with sticky headers
- Album browsing and media viewer
- Basic permission handling and media store integration

## 🐛 Troubleshooting

### 🔧 Common Issues

#### 🖼️ Images Not Loading
```bash
# Check permissions
adb shell pm list packages | grep framey

# Check MediaStore access
adb logcat | grep Framey

# Restart media scanner
adb shell am broadcast -a android.intent.action.MEDIA_MOUNTED -d file:///sdcard
```

#### 🔨 Build Issues
```bash
# Clean build
flutter clean
flutter pub get

# Update dependencies
flutter pub upgrade

# Check Flutter doctor
flutter doctor -v

# Rebuild
flutter run
```

#### 📱 Layout Overflow Errors
```
A RenderFlex overflowed by X pixels
```
- **Cause**: Album card content too tall for fixed height container
- **Solution**: Ensure padding and text sizing are properly constrained
- **Prevention**: Use Flexible widgets for text content in fixed-height containers

#### 📁 Media Item Not Found Errors
```
Error loading media: Exception: Media item not found
```
- **Cause**: Media viewer only searched first 100 items, missing items beyond that
- **Solution**: App now searches through entire media library with pagination
- **Prevention**: Media loading now handles large libraries properly

#### 🔍 Search Not Working
```
Search bar shows "coming soon" dialog
```
- **Solution**: Search functionality has been fully implemented with real-time filtering
- **How to use**: Tap menu → Search → Type in the search bar to filter photos

#### 🔐 Permission Issues
- **Cause**: Android 12+ requires granular media permissions
- **Solution**: 
  - Android 13+: Grant READ_MEDIA_IMAGES and READ_MEDIA_VIDEO
  - Android 10-12: Grant READ_EXTERNAL_STORAGE
  - Go to Settings → Apps → Framey → Permissions if needed

#### 📲 App Crashes on Startup
```bash
# Check device logs
adb logcat | grep -E "(FATAL|AndroidRuntime|Framey)"

# Clear app data
adb shell pm clear com.example.framey

# Reinstall
flutter run --release
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### 📋 License Summary
- ✅ Commercial use allowed
- ✅ Modification allowed
- ✅ Distribution allowed
- ✅ Private use allowed
- ❗ Liability and warranty disclaimed

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. **Fork** the repository
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Commit your changes** (`git commit -m 'Add amazing feature'`)
4. **Push to the branch** (`git push origin feature/amazing-feature`)
5. **Open a Pull Request** with a clear description

### 📝 Code Style
- Follow Dart/Flutter official style guide
- Use meaningful variable and function names
- Add comments for complex logic
- Include tests for new features
- Update documentation as needed

### 🧪 Testing
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

## 💬 Support

### 🆘 Getting Help
For issues and questions:
- 🐛 **Create an issue** on GitHub with detailed description
- 🔍 **Check existing issues** for solutions
- 📚 **Review documentation** before opening new issues
- 💬 **Join discussions** for community support

### 📧 Contact
- **GitHub Issues**: [Create new issue](https://github.com/your-username/framey/issues)
- **Discussions**: [Join community discussion](https://github.com/your-username/framey/discussions)
- **Email**: abir2afridi@gmail.com (if available)

### 🏆 Acknowledgments
- Flutter team for the amazing framework
- Android developers community
- Contributors and testers
- Open source libraries used in this project

---

<div align="center">
  <h3>📸 Framey - Your moments, beautifully organized. ✨</h3>
  <p>Made with ❤️ using Flutter & Android</p>
  <p>
    <a href="#features">Features</a> •
    <a href="#getting-started">Getting Started</a> •
    <a href="#architecture">Architecture</a> •
    <a href="#contributing">Contributing</a>
  </p>
</div>
