import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/domain/media_item.dart';
import '../../../shared/data/media_store_service.dart';
import '../../../shared/data/permission_service.dart';
import '../../../core/utils/performance_utils.dart';
import '../../../shared/presentation/widgets/framey_image.dart';
import '../../../shared/data/media_provider.dart';

class PhotosScreen extends ConsumerStatefulWidget {
  const PhotosScreen({super.key});

  @override
  ConsumerState<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends ConsumerState<PhotosScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController = ScrollController();
  List<MediaItem> _mediaItems = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;

  // Selection Mode State
  bool _isSelectionMode = false;
  final Set<MediaItem> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    PerformanceUtils.optimizeScrollPerformance(_scrollController);
    _loadMediaItems();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMediaItems({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
      if (refresh) {
        _mediaItems.clear();
        _currentPage = 0;
        _hasMore = true;
      }
    });

    try {
      final hasPermission = await PermissionService.checkMediaPermissions();
      if (!hasPermission) {
        final granted = await PermissionService.requestMediaPermissions();
        if (!granted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Permission Denied';
            _isLoading = false;
          });
          return;
        }
      }

      final items = await MediaStoreService.getMediaItems(
        limit: 100,
        offset: _currentPage * 100,
      );

      setState(() {
        if (_currentPage == 0) {
          _mediaItems = items;
        } else {
          _mediaItems.addAll(items);
        }
        _isLoading = false;
        _hasMore = items.length == 100;
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreItems() async {
    if (!_hasMore || _isLoading) return;
    await _loadMediaItems();
  }

  Future<void> _onMediaItemTap(MediaItem mediaItem) async {
    if (_isSelectionMode) {
      _toggleSelection(mediaItem);
    } else {
      final index = _mediaItems.indexOf(mediaItem);
      await Navigator.pushNamed(
        context,
        '/viewer',
        arguments: {'items': _mediaItems, 'index': index >= 0 ? index : 0},
      );
      // Refresh UI to reflect any deletions made in viewer
      _loadMediaItems(refresh: true);
    }
  }

  void _onMediaItemLongPress(MediaItem mediaItem) {
    setState(() {
      _isSelectionMode = true;
      _toggleSelection(mediaItem);
    });
  }

  void _toggleSelection(MediaItem item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
        if (_selectedItems.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedItems.add(item);
        _isSelectionMode = true;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedItems.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _deleteSelectedItems() async {
    if (_selectedItems.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete ${_selectedItems.length} items?'),
        content: const Text('Items will be moved to Recycle Bin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      int successCount = 0;
      final itemsToDelete = _selectedItems.toList();

      for (final item in itemsToDelete) {
        final success = await MediaStoreService.moveToRecycleBin(
          int.parse(item.id),
        );
        if (success) successCount++;
      }

      if (mounted) {
        setState(() {
          _mediaItems.removeWhere((item) => _selectedItems.contains(item));
          _exitSelectionMode();
        });

        // Refresh global provider too
        ref.read(mediaItemsProvider.notifier).refresh();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Moved $successCount items to Recycle Bin')),
        );
      }
    }
  }

  Future<void> _shareSelectedItems() async {
    if (_selectedItems.isEmpty) return;

    final uris = _selectedItems.map((e) => e.uri).toList();

    String mimeType = 'image/*';
    final hasVideo = _selectedItems.any((e) => e.type == MediaType.video);
    final hasImage = _selectedItems.any((e) => e.type == MediaType.image);

    if (hasVideo && hasImage) {
      mimeType = '*/*';
    } else if (hasVideo) {
      mimeType = 'video/*';
    }

    await MediaStoreService.shareMediaItems(uris, type: mimeType);
    if (mounted) _exitSelectionMode();
  }

  Map<String, List<MediaItem>> _groupMediaByDate(List<MediaItem> items) {
    final Map<String, List<MediaItem>> grouped = {};
    for (final item in items) {
      final header = _getFormattedDate(item.dateAdded);
      grouped.putIfAbsent(header, () => []).add(item);
    }
    return grouped;
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate.isAtSameMomentAs(today)) return 'Today';
    if (itemDate.isAtSameMomentAs(yesterday)) return 'Yesterday';
    if (date.year == now.year) return DateFormat('EEEE, MMM d').format(date);
    return DateFormat('MMMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return _buildErrorState();

    final groupedMedia = _groupMediaByDate(_mediaItems);
    final headers = groupedMedia.keys.toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PopScope(
        canPop: !_isSelectionMode,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_isSelectionMode) {
            _exitSelectionMode();
          }
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(),
            if (!_isSelectionMode) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              _buildMemoriesGrid(),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
            ...headers
                .map((header) {
                  final items = groupedMedia[header]!;
                  if (items.isEmpty)
                    return [const SliverToBoxAdapter(child: SizedBox.shrink())];

                  return [
                    _buildStickyHeader(header),
                    _buildMediaGrid(items),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ];
                })
                .expand((e) => e)
                .toList(),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    if (_isSelectionMode) {
      return SliverAppBar(
        pinned: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode,
        ),
        title: Text(
          '${_selectedItems.length}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareSelectedItems,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _deleteSelectedItems,
          ),
        ],
      );
    }

    return SliverAppBar(
      floating: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      centerTitle: false,
      title: Text(
        'Framey',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/search');
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_rounded, size: 20),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {},
          icon: CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withOpacity(0.1),
            child: Text(
              'A',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) {
            if (value == 'select') {
              setState(() {
                _isSelectionMode = true;
              });
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(value: 'select', child: Text('Select')),
          ],
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildMemoriesGrid() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Recent Memories'),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_mediaItems.length > index)
                          _buildThumbnail(_mediaItems[index]),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: 16,
                          right: 16,
                          child: Text(
                            'Moments from last week',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildStickyHeader(String title) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _DateHeaderDelegate(
        child: Container(
          height: 48,
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              if (_isSelectionMode)
                // Select all button could go here
                const SizedBox.shrink()
              else
                const Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaGrid(List<MediaItem> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = items[index];
          final isSelected = _selectedItems.contains(item);

          return GestureDetector(
            onTap: () => _onMediaItemTap(item),
            onLongPress: () => _onMediaItemLongPress(item),
            child: Hero(
              tag: _isSelectionMode ? 'no_hero_${item.id}' : 'media_${item.id}',
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 3,
                            )
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(isSelected ? 13 : 16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _buildThumbnail(item),
                          if (item.type == MediaType.video)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_isSelectionMode)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
          );
        }, childCount: items.length),
      ),
    );
  }

  bool get isSelectionMode => _isSelectionMode;

  Widget _buildThumbnail(MediaItem item) {
    if (item.thumbnailUri != null) {
      return FrameyImage(uri: item.thumbnailUri!);
    }
    return Container(
      color: Colors.grey.withOpacity(0.1),
      child: const Icon(Icons.image_rounded, color: Colors.grey),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'Error loading photos'),
          TextButton(
            onPressed: () => _loadMediaItems(refresh: true),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _DateHeaderDelegate({required this.child});

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;
  @override
  Widget build(BuildContext c, double s, bool o) => child;
  @override
  bool shouldRebuild(_DateHeaderDelegate old) => false;
}
