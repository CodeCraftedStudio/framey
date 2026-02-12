import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMediaItems());
  }

  Future<void> _loadMediaItems() async {
    final album = ModalRoute.of(context)?.settings.arguments as Album?;
    if (album == null) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final items = await MediaStoreService.getMediaItems(
        albumId: album.id,
        limit: 100,
      );
      setState(() {
        _mediaItems = items;
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
    final album = ModalRoute.of(context)?.settings.arguments as Album?;
    if (album == null)
      return const Scaffold(body: Center(child: Text('Album not found')));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(album),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_hasError)
            SliverToBoxAdapter(
              child: Center(child: Text(_errorMessage ?? 'Error')),
            )
          else
            _buildMediaGrid(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Album album) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.3),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              album.name,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              '${album.mediaCount} items',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (album.coverUri != null)
              Image.file(File(album.coverUri!), fit: BoxFit.cover)
            else
              Container(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.4, 1.0],
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid() {
    if (_mediaItems.isEmpty && !_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: Text('No media found in this album')),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = _mediaItems[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/viewer',
                arguments: {'items': _mediaItems, 'index': index},
              );
            },
            child: Hero(
              tag: 'media_${item.id}',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      item.thumbnailUri != null
                          ? Image.file(
                              File(item.thumbnailUri!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.grey.withOpacity(0.1),
                                  ),
                            )
                          : Container(
                              color: Colors.grey.withOpacity(0.1),
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
                            ),
                      if (item.type == MediaType.video)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }, childCount: _mediaItems.length),
      ),
    );
  }
}
