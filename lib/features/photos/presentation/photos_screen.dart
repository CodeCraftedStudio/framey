import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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
  List<MediaItem> _mediaItems = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;

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

  Future<void> _loadMediaItems() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
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

  void _onMediaItemTap(MediaItem mediaItem) {
    final index = _mediaItems.indexOf(mediaItem);
    Navigator.pushNamed(
      context,
      '/viewer',
      arguments: {'items': _mediaItems, 'index': index >= 0 ? index : 0},
    );
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
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _buildMemoriesGrid(),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ...headers.map((header) {
            final items = groupedMedia[header]!;
            if (items.isEmpty)
              return const SliverToBoxAdapter(child: SizedBox.shrink());

            return SliverMainAxisGroup(
              key: ValueKey('group_$header'),
              slivers: [
                _buildStickyHeader(header),
                _buildMediaGrid(items),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          }).toList(),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
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
          onPressed: () {},
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 20,
              color: Colors.redAccent,
            ),
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
              'U',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
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
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
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
          return GestureDetector(
            onTap: () => _onMediaItemTap(item),
            child: Hero(
              tag: 'media_${item.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildThumbnail(item),
              ),
            ),
          );
        }, childCount: items.length),
      ),
    );
  }

  Widget _buildThumbnail(MediaItem item) {
    if (item.thumbnailUri != null) {
      return Image.file(
        File(item.thumbnailUri!),
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) =>
            Container(color: Colors.grey.withOpacity(0.1)),
      );
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
          TextButton(onPressed: _loadMediaItems, child: const Text('Retry')),
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
