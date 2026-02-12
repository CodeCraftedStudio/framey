import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../shared/domain/media_item.dart';
import '../../../shared/data/media_store_service.dart';
import '../../editor/presentation/image_editor_screen.dart';

class MediaViewerScreen extends ConsumerStatefulWidget {
  final String? mediaId;
  const MediaViewerScreen({super.key, this.mediaId});

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen>
    with TickerProviderStateMixin {
  MediaItem? _mediaItem;
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isControlsVisible = true;
  late final AnimationController _controlsController;

  @override
  void initState() {
    super.initState();
    _controlsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controlsController.forward();
    _loadMediaItem();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _controlsController.dispose();
    super.dispose();
  }

  Future<void> _loadMediaItem() async {
    if (widget.mediaId == null) return;
    try {
      final items = await MediaStoreService.getMediaItems(limit: 50);
      _mediaItem = items.firstWhere((e) => e.id == widget.mediaId);

      if (_mediaItem!.type == MediaType.video) {
        _videoController = VideoPlayerController.file(File(_mediaItem!.uri));
        await _videoController!.initialize();
        setState(() {});
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
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
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(onTap: _toggleControls, child: _buildMainContent()),
          _buildTopBar(),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    if (_hasError)
      return const Center(child: Icon(Icons.error, color: Colors.white));

    if (_mediaItem!.type == MediaType.video) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    final isFileExists = File(_mediaItem!.uri).existsSync();
    final imageProvider = isFileExists
        ? FileImage(File(_mediaItem!.uri))
        : (_mediaItem!.thumbnailUri != null
              ? FileImage(File(_mediaItem!.thumbnailUri!)) as ImageProvider
              : const AssetImage('assets/images/placeholder.png'));

    return PhotoView(
      imageProvider: imageProvider,
      heroAttributes: PhotoViewHeroAttributes(tag: 'media_${_mediaItem!.id}'),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
    );
  }

  Widget _buildTopBar() {
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
                onPressed: _showMediaDetails,
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

  void _showMediaDetails() {
    if (_mediaItem == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
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
              DateFormat('EEEE, MMM d, yyyy').format(_mediaItem!.dateAdded),
            ),
            _buildDetailRow(
              Icons.access_time_rounded,
              'Time',
              DateFormat('h:mm a').format(_mediaItem!.dateAdded),
            ),
            _buildDetailRow(
              Icons.description_rounded,
              'Filename',
              _mediaItem!.name,
            ),
            _buildDetailRow(
              Icons.data_usage_rounded,
              'Size',
              '${(_mediaItem!.size / 1024 / 1024).toStringAsFixed(2)} MB',
            ),
            if (_mediaItem!.width != null && _mediaItem!.height != null)
              _buildDetailRow(
                Icons.photo_size_select_large_rounded,
                'Resolution',
                '${_mediaItem!.width} x ${_mediaItem!.height}',
              ),
            _buildDetailRow(Icons.folder_open_rounded, 'Path', _mediaItem!.uri),
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
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 20, color: Colors.blue),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
                  if (_mediaItem != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) =>
                            ImageEditorScreen(mediaItem: _mediaItem!),
                      ),
                    );
                  }
                },
              ),
              _buildBarItem(
                Icons.delete_outline_rounded,
                'Delete',
                color: Colors.redAccent,
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
