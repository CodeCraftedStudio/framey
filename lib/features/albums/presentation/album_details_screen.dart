import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../shared/domain/album.dart';
import '../../../shared/domain/media_item.dart';
import '../../../shared/data/media_store_service.dart';

class AlbumDetailsScreen extends ConsumerStatefulWidget {
  const AlbumDetailsScreen({super.key});

  @override
  ConsumerState<AlbumDetailsScreen> createState() => _AlbumDetailsScreenState();
}

class _AlbumDetailsScreenState extends ConsumerState<AlbumDetailsScreen> {
  List<MediaItem> _mediaItems = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMediaItems();
      }
    });
  }

  Future<void> _loadMediaItems() async {
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final album = ModalRoute.of(context)?.settings.arguments as Album?;
      if (album == null) {
        debugPrint('Framey: AlbumDetailsScreen - No album provided');
        return;
      }

      debugPrint('Framey: AlbumDetailsScreen - Loading album: ${album.name}');

      // Load media items for this album
      final items = await MediaStoreService.getMediaItems(
        albumId: album.id,
        limit: 50,
        offset: _currentPage * 50,
      );

      if (!mounted) return;

      setState(() {
        if (_currentPage == 0) {
          _mediaItems = items;
        } else {
          _mediaItems.addAll(items);
        }
        _isLoading = false;
        _hasMore = items.length == 50;
        _currentPage++;
        debugPrint(
          'Framey: AlbumDetailsScreen - Loaded ${items.length} items for album ${album.name}',
        );
      });
    } catch (e) {
      debugPrint('Framey: AlbumDetailsScreen - Error loading album: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load album: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    _currentPage = 0;
    _hasMore = true;
    await _loadMediaItems();
  }

  @override
  Widget build(BuildContext context) {
    final album = ModalRoute.of(context)?.settings.arguments as Album?;

    if (album == null) {
      return const Scaffold(body: Center(child: Text('Album not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(album.name),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: RefreshIndicator(onRefresh: _refresh, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_mediaItems.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text('No media in this album'),
          ],
        ),
      );
    }

    if (_isLoading && _mediaItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(onRefresh: _refresh, child: _buildMediaGrid());
  }

  Widget _buildMediaGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: _mediaItems.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _mediaItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final mediaItem = _mediaItems[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/viewer',
              arguments: mediaItem.id.toString(),
            );
          },
          child: Hero(
            tag: 'media_${mediaItem.id}',
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
              child: mediaItem.thumbnailUri != null
                  ? Image.network(
                      mediaItem.thumbnailUri!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
            ),
          ),
        );
      },
    );
  }
}
