import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/domain/album.dart';
import '../../../shared/data/permission_service.dart';

enum AIAlbumType { faces, locations, similar_photos }

class AIAlbumsScreen extends ConsumerStatefulWidget {
  const AIAlbumsScreen({super.key});

  @override
  ConsumerState<AIAlbumsScreen> createState() => _AIAlbumsScreenState();
}

class _AIAlbumsScreenState extends ConsumerState<AIAlbumsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Album> _faceAlbums = [];
  List<Album> _locationAlbums = [];
  List<Album> _similarAlbums = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAIAlbums();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAIAlbums() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final hasPermission = await PermissionService.checkMediaPermissions();
      if (!hasPermission) {
        final granted = await PermissionService.requestMediaPermissions();
        if (!granted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Media permissions are required for AI albums';
            _isLoading = false;
          });
          return;
        }
      }

      // TODO: Implement actual AI processing
      await _simulateAIProcessing();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _simulateAIProcessing() async {
    // Simulate AI processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock face albums
    _faceAlbums = [
      Album(
        id: 'face_1',
        name: 'John',
        type: AlbumType.ai_faces,
        coverUri: null,
        mediaCount: 45,
        lastModified: DateTime.now(),
      ),
      Album(
        id: 'face_2',
        name: 'Sarah',
        type: AlbumType.ai_faces,
        coverUri: null,
        mediaCount: 32,
        lastModified: DateTime.now(),
      ),
      Album(
        id: 'face_3',
        name: 'Unknown Person',
        type: AlbumType.ai_faces,
        coverUri: null,
        mediaCount: 18,
        lastModified: DateTime.now(),
      ),
    ];

    // Mock location albums
    _locationAlbums = [
      Album(
        id: 'loc_1',
        name: 'New York',
        type: AlbumType.ai_locations,
        coverUri: null,
        mediaCount: 67,
        lastModified: DateTime.now(),
      ),
      Album(
        id: 'loc_2',
        name: 'Paris',
        type: AlbumType.ai_locations,
        coverUri: null,
        mediaCount: 41,
        lastModified: DateTime.now(),
      ),
      Album(
        id: 'loc_3',
        name: 'Tokyo',
        type: AlbumType.ai_locations,
        coverUri: null,
        mediaCount: 28,
        lastModified: DateTime.now(),
      ),
    ];

    // Mock similar photo albums
    _similarAlbums = [
      Album(
        id: 'sim_1',
        name: 'Sunsets',
        type: AlbumType.custom,
        coverUri: null,
        mediaCount: 23,
        lastModified: DateTime.now(),
      ),
      Album(
        id: 'sim_2',
        name: 'Food',
        type: AlbumType.custom,
        coverUri: null,
        mediaCount: 56,
        lastModified: DateTime.now(),
      ),
    ];
  }

  Future<void> _refresh() async {
    await _loadAIAlbums();
  }

  void _onAlbumTap(Album album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIAlbumDetailScreen(album: album),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.face_outlined), text: 'Faces'),
              Tab(icon: Icon(Icons.location_on_outlined), text: 'Places'),
              Tab(icon: Icon(Icons.photo_library_outlined), text: 'Similar'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.6),
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAlbumsGrid(_faceAlbums, 'faces'),
                _buildAlbumsGrid(_locationAlbums, 'places'),
                _buildAlbumsGrid(_similarAlbums, 'similar photos'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsGrid(List<Album> albums, String albumType) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing your photos...'),
          ],
        ),
      );
    }

    if (albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No $albumType found',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: albums.length,
        itemBuilder: (context, index) {
          final album = albums[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _onAlbumTap(album),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.3),
                          ],
                        ),
                      ),
                      child: album.coverUri != null
                          ? Image.network(
                              album.coverUri!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  _getAlbumIcon(album.type),
                                  size: 48,
                                  color: Theme.of(context).colorScheme.primary,
                                );
                              },
                            )
                          : Icon(
                              _getAlbumIcon(album.type),
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              album.name,
                              style: Theme.of(context).textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${album.mediaCount} items',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getAlbumIcon(AlbumType type) {
    switch (type) {
      case AlbumType.ai_faces:
        return Icons.face_outlined;
      case AlbumType.ai_locations:
        return Icons.location_on_outlined;
      case AlbumType.custom:
        return Icons.photo_library_outlined;
      default:
        return Icons.folder_outlined;
    }
  }
}

class AIAlbumDetailScreen extends StatelessWidget {
  final Album album;

  const AIAlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(album.name)),
      body: const Center(
        child: Text(
          'AI Album Detail\n(TODO: Implement media grid)',
          style: TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
