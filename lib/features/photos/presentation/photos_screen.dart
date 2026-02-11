import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../shared/domain/media_item.dart';
import '../../../shared/data/media_store_service.dart';
import '../../../shared/data/permission_service.dart';
import '../../../core/utils/performance_utils.dart';

class PhotosScreen extends ConsumerStatefulWidget {
  const PhotosScreen({super.key});

  @override
  ConsumerState<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends ConsumerState<PhotosScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isSearching = false;
  List<MediaItem> _mediaItems = [];
  List<MediaItem> _filteredMediaItems = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isDisposed = false;
  String _selectedView = 'grid'; // 'grid' or 'list'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    PerformanceUtils.optimizeScrollPerformance(_scrollController);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
    _searchController.addListener(_onSearchChanged);
    _loadMediaItems();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchController.clear();
        _filteredMediaItems = _mediaItems;
      } else {
        _filteredMediaItems.clear();
      }
    });
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
        _filteredMediaItems = _mediaItems;
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

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _filteredMediaItems = _mediaItems;
      });
    } else {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredMediaItems = _mediaItems.where((item) {
          return item.name.toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  void _onMediaItemTap(MediaItem mediaItem) {
    Navigator.pushNamed(context, '/viewer', arguments: mediaItem.id.toString());
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Search Photos'),
          content: SizedBox(
            height: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Search functionality coming soon!'),
                const SizedBox(height: 16),
                const Text('You will be able to search by:'),
                const SizedBox(height: 8),
                const Text('• Date'),
                const Text('• Filename'),
                const Text('• Location'),
                const SizedBox(height: 16),
                const Text('Filter options will also be available.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Map<String, List<MediaItem>> _groupMediaByDate(List<MediaItem> items) {
    final Map<String, List<MediaItem>> grouped = {};

    for (final item in items) {
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
      return Scaffold(
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Oops!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? 'An error occurred',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_errorMessage?.contains('permissions') == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextButton.icon(
                        onPressed: () async {
                          await PermissionService.openAppSettings();
                        },
                        icon: const Icon(Icons.settings_outlined),
                        label: const Text('Open Settings'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_mediaItems.isEmpty && !_isLoading) {
      return Scaffold(
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No photos yet',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your photos will appear here once you grant permissions',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final groupedMedia = _groupMediaByDate(
      _isSearching ? _filteredMediaItems : _mediaItems,
    );
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
              surfaceTintColor: Theme.of(context).colorScheme.primary,
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search photos...',
                        hintStyle: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                        border: InputBorder.none,
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                    )
                  : const Text('Photos'),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'search') {
                      _toggleSearch();
                    } else if (value == 'view_toggle') {
                      setState(() {
                        _selectedView = _selectedView == 'grid'
                            ? 'list'
                            : 'grid';
                      });
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'search',
                      child: Row(
                        children: [
                          Icon(Icons.search_outlined),
                          SizedBox(width: 8),
                          Text('Search'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'view_toggle',
                      child: Row(
                        children: [
                          Icon(
                            _selectedView == 'grid'
                                ? Icons.view_list
                                : Icons.grid_view,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedView == 'grid' ? 'List View' : 'Grid View',
                          ),
                        ],
                      ),
                    ),
                  ],
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
                      padding: const EdgeInsets.all(8),
                      sliver: _selectedView == 'grid'
                          ? _buildGridView(items)
                          : _buildListView(items),
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

  Widget _buildMediaThumbnail(MediaItem mediaItem) {
    if (mediaItem.thumbnailUri != null &&
        mediaItem.thumbnailUri!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: mediaItem.thumbnailUri!,
        fit: BoxFit.cover,
        memCacheWidth: 150,
        memCacheHeight: 150,
        placeholder: (context, url) => PerformanceUtils.buildSkeletonLoader(
          width: double.infinity,
          height: double.infinity,
        ),
        errorWidget: (context, url, error) => Container(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Icon(
            mediaItem.type == MediaType.video ? Icons.videocam : Icons.image,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      );
    } else if (mediaItem.thumbnailUri != null) {
      return Image.file(
        File(mediaItem.thumbnailUri!),
        fit: BoxFit.cover,
        width: 150,
        height: 150,
        cacheWidth: 150,
        cacheHeight: 150,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Icon(
            mediaItem.type == MediaType.video ? Icons.videocam : Icons.image,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      );
    } else {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Icon(
          mediaItem.type == MediaType.video ? Icons.videocam : Icons.image,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
      );
    }
  }

  Widget _buildGridView(List<MediaItem> items) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
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
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildMediaThumbnail(mediaItem),
              ),
            ),
          ),
        );
      }, childCount: items.length),
    );
  }

  Widget _buildListView(List<MediaItem> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final mediaItem = items[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildMediaThumbnail(mediaItem),
              ),
            ),
            title: Text(
              mediaItem.name,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  DateFormat(
                    'MMM dd, yyyy • hh:mm a',
                  ).format(mediaItem.dateAdded),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                if (mediaItem.type == MediaType.video)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.videocam,
                          size: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Video',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _onMediaItemTap(mediaItem),
          ),
        );
      }, childCount: items.length),
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
