import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
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

void main() {
  runApp(const ProviderScope(child: FrameyApp()));
}

class FrameyApp extends ConsumerWidget {
  const FrameyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/viewer': (context) {
          final mediaId = ModalRoute.of(context)?.settings.arguments as String?;
          return MediaViewerScreen(mediaId: mediaId);
        },
        '/album_details': (context) {
          return const AlbumDetailsScreen();
        },
        '/videos': (context) => const VideoScreen(),
        '/recycle_bin': (context) => const RecycleBinScreen(),
        '/hidden': (context) => const HiddenScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/about': (context) => const AboutScreen(),
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
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          elevation: 0,
          backgroundColor: Colors.transparent,
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.photo_library_outlined, size: 24),
              selectedIcon: Icon(Icons.photo_library, size: 24),
              label: 'Photos',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_rounded, size: 24),
              selectedIcon: Icon(Icons.search_rounded, size: 24),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.album_outlined, size: 24),
              selectedIcon: Icon(Icons.album, size: 24),
              label: 'Albums',
            ),
            NavigationDestination(
              icon: Icon(Icons.window_rounded, size: 24),
              selectedIcon: Icon(Icons.window_rounded, size: 24),
              label: 'Library',
            ),
          ],
        ),
      ),
    );
  }
}
