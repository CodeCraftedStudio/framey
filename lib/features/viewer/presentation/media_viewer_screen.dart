import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../shared/domain/media_item.dart';
import '../../../shared/data/media_store_service.dart';

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

    return PhotoView(
      imageProvider: FileImage(File(_mediaItem!.uri)),
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
              if (_mediaItem != null)
                Text(
                  DateFormat(
                    'MMM d, yyyy h:mm a',
                  ).format(_mediaItem!.dateAdded),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const Spacer(),
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
              _buildBarItem(Icons.edit_rounded, 'Edit'),
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
  }) {
    return Column(
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
    );
  }
}
