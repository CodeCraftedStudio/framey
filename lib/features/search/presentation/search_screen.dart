import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/domain/media_item.dart';
import '../../../shared/data/media_store_service.dart';
import '../../../shared/presentation/widgets/framey_image.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MediaItem> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  Timer? _debounce;
  String _selectedSearchType = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      if (_isSearching) {
        // If we are clearing text but still have a type filter, we should re-search with empty query
        if (_selectedSearchType != 'all') {
          _performSearch('');
        } else {
          setState(() {
            _isSearching = false;
            _searchResults.clear();
          });
        }
      }
    } else {
      if (!_isSearching) {
        setState(() => _isSearching = true);
      }

      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _performSearch(query);
      });
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      // Determine media type filter
      String? mediaType;
      if (_selectedSearchType == 'photos') {
        mediaType = 'image';
      } else if (_selectedSearchType == 'videos') {
        mediaType = 'video';
      }

      final items = await MediaStoreService.getMediaItems(
        searchQuery: query,
        mediaType: mediaType,
      );

      setState(() {
        _searchResults = items;
        _isLoading = false;
        // Ensure we are in searching mode if we have results or if we specifically requested a search
        _isSearching = true;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchTypeChanged(String type) {
    setState(() {
      _selectedSearchType = type;
    });
    // Re-run search
    // If text is not empty, use it. If it is empty, pass empty string to find all by type.
    final query = _searchController.text.trim();

    // If we are purely browsing by category (e.g. videos) without text, we want to trigger search
    if (query.isEmpty && type != 'all') {
      _performSearch('');
    } else if (query.isNotEmpty) {
      _performSearch(query);
    } else if (query.isEmpty && type == 'all') {
      // Back to default view
      setState(() {
        _isSearching = false;
        _searchResults.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          if (_isSearching) _buildFilterChips(),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          if (!_isSearching) ...[
            _buildSectionHeader('Quick Access', 'Common folders & types'),
            _buildCategoriesGrid(),
          ] else ...[
            _buildSearchResultsGrid(),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _buildFilterChip('All', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Photos', 'photos'),
            const SizedBox(width: 8),
            _buildFilterChip('Videos', 'videos'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedSearchType == value;
    return GestureDetector(
      onTap: () => _onSearchTypeChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      toolbarHeight: 90,
      title: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search photos, people, places...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    onPressed: () => _searchController.clear(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  )
                : Icon(
                    Icons.mic_none_rounded,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.4),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      {
        'name': 'Screenshots',
        'icon': Icons.screenshot_rounded,
        'color': Colors.blue,
        'query': 'Screenshot',
      },
      {
        'name': 'Videos',
        'icon': Icons.play_circle_fill_rounded,
        'color': Colors.red,
        'type': 'videos',
      },
      {
        'name': 'Camera',
        'icon': Icons.camera_alt_rounded,
        'color': Colors.purple,
        'query': 'Camera',
      },
      {
        'name': 'Downloads',
        'icon': Icons.download_rounded,
        'color': Colors.green,
        'query': 'Download',
      },
      {
        'name': 'WhatsApp',
        'icon': Icons.chat_bubble_rounded,
        'color': Colors.teal,
        'query': 'WhatsApp',
      },
      {
        'name': 'Instagram',
        'icon': Icons.camera_enhance_rounded,
        'color': Colors.pink,
        'query': 'Instagram',
      },
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.5,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final cat = categories[index];
          return GestureDetector(
            onTap: () {
              if (cat['type'] == 'videos') {
                _onSearchTypeChanged('videos');
              } else if (cat['query'] != null) {
                _searchController.text = cat['query'] as String;
                // Manually trigger performSearch because the listener might be debounced or we want instant feedback
                // Note: setting text triggers listener.
                // But listener has logic: if query is not empty ...
                // Let's force it.
                _performSearch(cat['query'] as String);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (cat['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      cat['icon'] as IconData,
                      color: cat['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    cat['name'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: categories.length),
      ),
    );
  }

  Widget _buildSearchResultsGrid() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_searchResults.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
              const SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty
                    ? 'No items found'
                    : 'No results for "${_searchController.text}"',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = _searchResults[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/viewer',
                arguments: {'items': _searchResults, 'index': index},
              );
            },
            child: Hero(
              tag: 'media_${item.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FrameyImage(
                  uri: item.thumbnailUri ?? item.uri,
                  fit: BoxFit.cover,
                  width: 200,
                  height: 200,
                  placeholder: Container(
                    color: Colors.grey.withOpacity(0.1),
                    child: const Center(
                      child: Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                  errorWidget: Container(
                    color: Colors.grey.withOpacity(0.1),
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          );
        }, childCount: _searchResults.length),
      ),
    );
  }
}
