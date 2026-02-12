import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/domain/media_item.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MediaItem> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      if (_isSearching) {
        setState(() {
          _isSearching = false;
          _searchResults.clear();
        });
      }
    } else {
      if (!_isSearching) {
        setState(() => _isSearching = true);
      }
      // TODO: Implement debounced search
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
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          if (!_isSearching) ...[
            _buildSectionHeader('People & Pets', 'Manage faces'),
            _buildPeopleHorizontalScroll(),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            _buildSectionHeader('Places', 'Your travels'),
            _buildPlacesHorizontalScroll(),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            _buildSectionHeader('Categories', 'Auto-labeled'),
            _buildCategoriesGrid(),
          ] else ...[
            _buildSearchResultsGrid(),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
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
            TextButton(
              onPressed: () {},
              child: Text(
                'View all',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleHorizontalScroll() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 110,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: 8,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Container(
                        color: Colors.blue.withOpacity(0.1),
                        child: Icon(
                          Icons.person_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.5),
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlacesHorizontalScroll() {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 160,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          itemBuilder: (context, index) {
            return Container(
              width: 220,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        color: Colors.green.withOpacity(0.1),
                        child: Center(
                          child: Icon(
                            Icons.map_rounded,
                            color: Colors.green.withOpacity(0.2),
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                      ),
                      child: Text(
                        'San Francisco',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      {'name': 'Nature', 'icon': Icons.landscape_rounded, 'color': Colors.teal},
      {
        'name': 'Food',
        'icon': Icons.restaurant_rounded,
        'color': Colors.orange,
      },
      {
        'name': 'Sports',
        'icon': Icons.sports_basketball_rounded,
        'color': Colors.red,
      },
      {
        'name': 'Documents',
        'icon': Icons.description_outlined,
        'color': Colors.blue,
      },
      {'name': 'Night', 'icon': Icons.nightlight_round, 'color': Colors.indigo},
      {
        'name': 'Videos',
        'icon': Icons.play_circle_fill_rounded,
        'color': Colors.purple,
      },
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final cat = categories[index];
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (cat['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }, childCount: categories.length),
      ),
    );
  }

  Widget _buildSearchResultsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverToBoxAdapter(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 100),
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
              const SizedBox(height: 16),
              Text(
                'No results for "${_searchController.text}"',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
