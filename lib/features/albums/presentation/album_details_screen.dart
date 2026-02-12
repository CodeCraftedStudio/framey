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
      expandedHeight: 250,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          album.name,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Colors.white,
            shadows: [const Shadow(color: Colors.black45, blurRadius: 10)],
          ),
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildMediaGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final item = _mediaItems[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/viewer',
              arguments: item.id.toString(),
            ),
            child: Hero(
              tag: 'media_${item.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.grey.withOpacity(0.1),
                  child: item.thumbnailUri != null
                      ? Image.file(File(item.thumbnailUri!), fit: BoxFit.cover)
                      : const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
          );
        }, childCount: _mediaItems.length),
      ),
    );
  }
}
