import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/domain/media_item.dart';
import '../../../shared/data/media_store_service.dart';
import '../../../shared/data/permission_service.dart';

enum SearchType { all, photos, videos, date, filename, location }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<MediaItem> _searchResults = [];
  SearchType _searchType = SearchType.all;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMore = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreResults();
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _currentPage = 0;
      _hasMore = true;
    });

    try {
      final hasPermission = await PermissionService.checkMediaPermissions();
      if (!hasPermission) {
        final granted = await PermissionService.requestMediaPermissions();
        if (!granted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'Media permissions are required to search';
            _isLoading = false;
          });
          return;
        }
      }

      final results = await _searchMedia(query, _searchType);

      setState(() {
        _searchResults = results;
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

  Future<List<MediaItem>> _searchMedia(String query, SearchType type) async {
    // For now, we'll implement basic filename search
    // TODO: Implement advanced search by date, location, etc.
    switch (type) {
      case SearchType.all:
      case SearchType.photos:
      case SearchType.videos:
      case SearchType.filename:
        return await MediaStoreService.getMediaItems(
          limit: 50,
          offset: _currentPage * 50,
        );
      case SearchType.date:
        // TODO: Implement date-based search
        return [];
      case SearchType.location:
        // TODO: Implement location-based search
        return [];
    }
  }

  Future<void> _loadMoreResults() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _currentPage++;
    });

    try {
      final query = _searchController.text.trim();
      final results = await _searchMedia(query, _searchType);

      setState(() {
        _searchResults.addAll(results);
        _hasMore = results.length == 50;
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

  void _onSearchTypeChanged(SearchType? type) {
    if (type != null) {
      setState(() {
        _searchType = type;
      });
      _performSearch();
    }
  }

  void _onMediaItemTap(MediaItem mediaItem) {
    Navigator.pushNamed(
      context,
      '/viewer',
      arguments: {'mediaId': mediaItem.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search photos, videos, albums...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
                const SizedBox(height: 12),

                // Search Type Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSearchChip('All', SearchType.all),
                      _buildSearchChip('Photos', SearchType.photos),
                      _buildSearchChip('Videos', SearchType.videos),
                      _buildSearchChip('Date', SearchType.date),
                      _buildSearchChip('Location', SearchType.location),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Results
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchChip(String label, SearchType type) {
    final isSelected = _searchType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onSearchTypeChanged(type),
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : null,
        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      ),
    );
  }

  Widget _buildSearchResults() {
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
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Start typing to search',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _performSearch,
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1.0,
        ),
        itemCount: _searchResults.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _searchResults.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final mediaItem = _searchResults[index];
          return GestureDetector(
            onTap: () => _onMediaItemTap(mediaItem),
            child: Hero(
              tag: 'search_${mediaItem.id}',
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
                            child: Icon(
                              mediaItem.type == MediaType.video
                                  ? Icons.videocam_outlined
                                  : Icons.image_outlined,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      )
                    : Icon(
                        mediaItem.type == MediaType.video
                            ? Icons.videocam_outlined
                            : Icons.image_outlined,
                        color: Colors.grey[600],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
