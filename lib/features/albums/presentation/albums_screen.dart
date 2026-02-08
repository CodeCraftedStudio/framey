import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/domain/album.dart';
import '../../../shared/data/media_store_service.dart';
import '../../../shared/data/permission_service.dart';

class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({super.key});

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen> {
  List<Album> _albums = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
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
            _errorMessage = 'Media permissions are required to view albums';
            _isLoading = false;
          });
          return;
        }
      }

      final albums = await MediaStoreService.getAlbums();

      setState(() {
        _albums = albums;
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

  Future<void> _refresh() async {
    await _loadAlbums();
  }

  void _onAlbumTap(Album album) {
    Navigator.pushNamed(context, '/album_details', arguments: album);
  }

  IconData _getAlbumIcon(AlbumType type) {
    switch (type) {
      case AlbumType.system:
        return Icons.folder_outlined;
      case AlbumType.custom:
        return Icons.create_new_folder_outlined;
      case AlbumType.ai_faces:
        return Icons.face_outlined;
      case AlbumType.ai_locations:
        return Icons.location_on_outlined;
      case AlbumType.hidden:
        return Icons.lock_outline;
      case AlbumType.recycle_bin:
        return Icons.delete_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(
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
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              title: Text(
                'Albums',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.create_outlined),
                  onPressed: () {
                    // TODO: Create new album
                  },
                ),
              ],
            ),
            if (_albums.isEmpty && !_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.album_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No albums found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final album = _albums[index];
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
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Icon(
                                                _getAlbumIcon(album.type),
                                                size: 48,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              );
                                            },
                                      )
                                    : Icon(
                                        _getAlbumIcon(album.type),
                                        size: 48,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      album.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: _albums.length),
                ),
              ),
            if (_isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
