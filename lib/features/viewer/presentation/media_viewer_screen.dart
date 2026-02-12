import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../shared/domain/media_item.dart';
import '../../../shared/data/media_store_service.dart';
import '../../../shared/data/media_provider.dart';
import '../../editor/presentation/image_editor_screen.dart';

class MediaViewerScreen extends ConsumerStatefulWidget {
  final List<MediaItem>? initialItems;
  final int initialIndex;

  const MediaViewerScreen({
    super.key,
    this.initialItems,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late List<MediaItem> _items;
  VideoPlayerController? _videoController;
  bool _isControlsVisible = true;
  late final AnimationController _controlsController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _items = widget.initialItems ?? ref.read(mediaItemsProvider).items;
    _pageController = PageController(initialPage: _currentIndex);

    _controlsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controlsController.forward();

    if (_items.isNotEmpty && _items[_currentIndex].type == MediaType.video) {
      _initVideo(_items[_currentIndex].uri);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    _controlsController.dispose();
    super.dispose();
  }

  Future<void> _initVideo(String uri) async {
    _videoController?.dispose();
    setState(() => _isVideoInitialized = false);
    _videoController = VideoPlayerController.file(File(uri));
    try {
      await _videoController!.initialize();
      setState(() => _isVideoInitialized = true);
      _videoController!.play();
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (_items[index].type == MediaType.video) {
      _initVideo(_items[index].uri);
    } else {
      _videoController?.pause();
    }
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
      _isControlsVisible
          ? _controlsController.forward()
          : _controlsController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Scaffold(body: Center(child: Text('No media items')));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: _toggleControls,
            child: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                final item = _items[index];
                if (item.type == MediaType.video) {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: _buildVideoPlayer(),
                    initialScale: PhotoViewComputedScale.contained,
                  );
                }
                return PhotoViewGalleryPageOptions(
                  imageProvider: _buildImageProvider(item),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 4,
                  heroAttributes: PhotoViewHeroAttributes(
                    tag: 'media_${item.id}',
                  ),
                );
              },
              itemCount: _items.length,
              loadingBuilder: (context, event) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              pageController: _pageController,
              onPageChanged: _onPageChanged,
            ),
          ),
          _buildTopBar(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  ImageProvider _buildImageProvider(MediaItem item) {
    if (File(item.uri).existsSync()) {
      return FileImage(File(item.uri));
    } else if (item.thumbnailUri != null &&
        File(item.thumbnailUri!).existsSync()) {
      return FileImage(File(item.thumbnailUri!));
    }
    return const AssetImage('assets/images/placeholder.png');
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  Widget _buildTopBar() {
    final currentItem = _items[_currentIndex];
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _controlsController,
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: 20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showMediaDetails(currentItem),
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMediaDetails(MediaItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Details',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      Icons.calendar_month_rounded,
                      'Date',
                      DateFormat('EEEE, MMM d, yyyy').format(item.dateAdded),
                    ),
                    _buildDetailRow(
                      Icons.access_time_rounded,
                      'Time',
                      DateFormat('h:mm a').format(item.dateAdded),
                    ),
                    _buildDetailRow(
                      Icons.description_rounded,
                      'Filename',
                      item.name,
                    ),
                    _buildDetailRow(
                      Icons.data_usage_rounded,
                      'Size',
                      '${(item.size / 1024 / 1024).toStringAsFixed(2)} MB',
                    ),
                    if (item.width != null && item.height != null)
                      _buildDetailRow(
                        Icons.photo_size_select_large_rounded,
                        'Resolution',
                        '${item.width} x ${item.height}',
                      ),
                    _buildDetailRow(
                      Icons.folder_open_rounded,
                      'Path',
                      item.uri,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final currentItem = _items[_currentIndex];
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _controlsController,
        child: Container(
          padding: const EdgeInsets.only(bottom: 40, top: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.8), Colors.transparent],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBarItem(Icons.share_rounded, 'Share'),
              _buildBarItem(Icons.favorite_border_rounded, 'Favorite'),
              _buildBarItem(
                Icons.edit_rounded,
                'Edit',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => ImageEditorScreen(mediaItem: currentItem),
                    ),
                  );
                },
              ),
              _buildBarItem(
                Icons.delete_outline_rounded,
                'Delete',
                color: Colors.redAccent,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Move to Recycle Bin?'),
                      content: const Text(
                        'Item will be kept for 30 days before permanent deletion.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    final success = await MediaStoreService.moveToRecycleBin(
                      int.parse(currentItem.id),
                    );
                    if (success && mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Moved to Recycle Bin')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarItem(
    IconData icon,
    String label, {
    Color color = Colors.white,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: color.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
