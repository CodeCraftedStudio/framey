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
          return AlbumDetailsScreen();
        },
      },
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: const [PhotosScreen(), AlbumsScreen(), LibraryScreen()],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: const [
          Tab(icon: Icon(Icons.photo_library_outlined), text: 'Photos'),
          Tab(icon: Icon(Icons.album_outlined), text: 'Albums'),
          Tab(icon: Icon(Icons.folder_outlined), text: 'Library'),
        ],
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(
          context,
        ).colorScheme.onSurface.withOpacity(0.6),
        indicatorColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.video_library_outlined),
          title: const Text('Videos'),
          subtitle: const Text('All video files'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VideoScreen()),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Recycle Bin'),
          subtitle: const Text('Recently deleted items'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RecycleBinScreen()),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Hidden'),
          subtitle: const Text('Private photos and videos'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HiddenScreen()),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Settings'),
          subtitle: const Text('App preferences and security'),
          onTap: () {
            // TODO: Navigate to settings
          },
        ),
      ],
    );
  }
}
