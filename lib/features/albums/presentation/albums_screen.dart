import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _buildAISection(),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
          _buildAlbumsHeader(),
          if (_hasError)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  _errorMessage ?? 'An error occurred',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            )
          else if (_isLoading && _albums.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildAlbumsGrid(),
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
      centerTitle: false,
      title: Text(
        'Albums',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
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
            child: const Icon(Icons.add_rounded, size: 20),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAISection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Smart Collections'),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _buildAICard(
                  'People',
                  Icons.face_rounded,
                  Colors.blue,
                  'faces',
                ),
                _buildAICard(
                  'Places',
                  Icons.location_on_rounded,
                  Colors.green,
                  'places',
                ),
                _buildAICard(
                  'Selfies',
                  Icons.portrait_rounded,
                  Colors.orange,
                  'selfies',
                ),
                _buildAICard(
                  'Nature',
                  Icons.landscape_rounded,
                  Colors.teal,
                  'nature',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAICard(String title, IconData icon, Color color, String type) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildAlbumsHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Albums',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              '${_albums.length} Total',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumsGrid() {
    if (_albums.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No albums found')),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 24,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final album = _albums[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/album_details',
              arguments: album,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (album.coverUri != null)
                            Image.file(File(album.coverUri!), fit: BoxFit.cover)
                          else
                            Container(color: Colors.grey.withOpacity(0.05)),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${album.mediaCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    album.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }, childCount: _albums.length),
      ),
    );
  }
}
