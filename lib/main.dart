import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/theme_provider.dart';
import 'features/photos/presentation/photos_screen.dart';
import 'features/albums/presentation/albums_screen.dart';
import 'features/albums/presentation/album_details_screen.dart';
import 'features/videos/presentation/video_screen.dart';
import 'features/recycle_bin/presentation/recycle_bin_screen.dart';
import 'features/hidden/presentation/hidden_screen.dart';
import 'features/viewer/presentation/media_viewer_screen.dart';
import 'features/search/presentation/search_screen.dart';
import 'features/library/presentation/library_screen.dart';
import 'features/library/presentation/settings_screen.dart';
import 'features/library/presentation/about_screen.dart';
import 'features/library/presentation/developer_screen.dart';
import 'shared/domain/media_item.dart';

void main() {
  runApp(const ProviderScope(child: FrameyApp()));
}

class FrameyApp extends ConsumerWidget {
  const FrameyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.getLightTheme(themeSettings.primaryColor),
      darkTheme: AppTheme.getDarkTheme(themeSettings.primaryColor),
      themeMode: themeSettings.themeMode,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/viewer': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          return MediaViewerScreen(
            initialItems: args?['items'] as List<MediaItem>?,
            initialIndex: args?['index'] as int? ?? 0,
          );
        },
        '/album_details': (context) {
          return const AlbumDetailsScreen();
        },
        '/videos': (context) => const VideoScreen(),
        '/recycle_bin': (context) => const RecycleBinScreen(),
        '/hidden': (context) => const HiddenScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/about': (context) => const AboutScreen(),
        '/developer': (context) => const DeveloperScreen(),
        '/search': (context) => const SearchScreen(),
      },
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    PhotosScreen(),
    SearchScreen(),
    AlbumsScreen(),
    LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          _screens[_selectedIndex],
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A1C1E).withOpacity(0.9)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.photo_library_rounded, 'PHOTOS'),
                    _buildNavItem(1, Icons.search_rounded, 'SEARCH'),
                    _buildNavItem(2, Icons.album_rounded, 'ALBUMS'),
                    _buildNavItem(3, Icons.window_rounded, 'LIBRARY'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withOpacity(0.4);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
