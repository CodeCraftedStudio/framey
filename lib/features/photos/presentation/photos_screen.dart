import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/domain/media_item.dart';
import '../../../shared/data/media_store_service.dart';
import '../../../shared/data/permission_service.dart';

class PhotosScreen extends ConsumerStatefulWidget {
  const PhotosScreen({super.key});

  @override
  ConsumerState<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends ConsumerState<PhotosScreen> {
  final ScrollController _scrollController = ScrollController();
  List<MediaItem> _mediaItems = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMediaItems();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMediaItems() async {
    if (_isLoading || _isDisposed) return;

    debugPrint('Framey: PhotosScreen._loadMediaItems() called');

    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      debugPrint('Framey: Checking media permissions...');
      final hasPermission = await PermissionService.checkMediaPermissions();
      debugPrint('Framey: Media permissions result: $hasPermission');

      if (!hasPermission) {
        debugPrint('Framey: Requesting media permissions...');
        final granted = await PermissionService.requestMediaPermissions();
        if (!granted) {
          if (mounted && !_isDisposed) {
            setState(() {
              _hasError = true;
              _errorMessage =
                  'Media permissions are required to view photos. Please grant permissions in settings.';
              _isLoading = false;
            });
          }
          return;
        }
      }

      debugPrint('Framey: Permissions granted, loading media items...');
      final items = await MediaStoreService.getMediaItems(
        mediaType: 'image',
        limit: 50,
        offset: _currentPage * 50,
      );

      if (!mounted || _isDisposed) return;

      setState(() {
        if (_currentPage == 0) {
          _mediaItems = items;
        } else {
          _mediaItems.addAll(items);
        }
        _isLoading = false;
        _hasMore = items.length == 50;
        _currentPage++;
      });
    } catch (e) {
      debugPrint('Framey: Error loading media items: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load photos: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreItems() async {
    if (!_hasMore || _isLoading) return;
    await _loadMediaItems();
  }

  Future<void> _refresh() async {
    _currentPage = 0;
    _hasMore = true;
    await _loadMediaItems();
  }

  void _onMediaItemTap(MediaItem mediaItem) {
    Navigator.pushNamed(context, '/viewer', arguments: mediaItem.id.toString());
  }

  Map<String, List<MediaItem>> _groupMediaByDate() {
    final Map<String, List<MediaItem>> grouped = {};

    for (final item in _mediaItems) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final itemDate = DateTime(
        item.dateAdded.year,
        item.dateAdded.month,
        item.dateAdded.day,
      );

      String header;
      if (itemDate.isAtSameMomentAs(today)) {
        header = 'Today';
      } else if (itemDate.isAtSameMomentAs(yesterday)) {
        header = 'Yesterday';
      } else if (itemDate.year == now.year) {
        header = DateFormat('MMMM').format(itemDate);
      } else {
        header = DateFormat('MMMM yyyy').format(itemDate);
      }

      grouped.putIfAbsent(header, () => []).add(item);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            if (_errorMessage?.contains('permissions') == true)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () async {
                    await PermissionService.openAppSettings();
                  },
                  child: const Text('Open Settings'),
                ),
              ),
          ],
        ),
      );
    }

    if (_mediaItems.isEmpty && !_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No photos found',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groupedMedia = _groupMediaByDate();
    final headers = groupedMedia.keys.toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              title: Text(
                'Photos',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_outlined),
                  onPressed: () {
                    // TODO: Navigate to search
                  },
                ),
              ],
            ),
            ...headers
                .map((header) {
                  final items = groupedMedia[header]!;
                  return [
                    SliverPersistentHeader(
                      delegate: _StickyHeaderDelegate(
                        child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            header,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(2),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 2,
                              mainAxisSpacing: 2,
                              childAspectRatio: 1.0,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final mediaItem = items[index];
                          return GestureDetector(
                            onTap: () => _onMediaItemTap(mediaItem),
                            child: Hero(
                              tag: 'media_${mediaItem.id}',
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: mediaItem.thumbnailUri != null
                                    ? Image.file(
                                        File(mediaItem.thumbnailUri!),
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      )
                                    : Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            ),
                          );
                        }, childCount: items.length),
                      ),
                    ),
                  ];
                })
                .expand((element) => element),
            if (_isLoading)
              const SliverToBoxAdapter(
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

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
