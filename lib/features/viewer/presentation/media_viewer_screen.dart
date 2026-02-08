import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import '../../../shared/domain/media_item.dart';

class MediaViewerScreen extends ConsumerStatefulWidget {
  final String? mediaId;

  const MediaViewerScreen({super.key, this.mediaId});

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  MediaItem? _mediaItem;
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadMediaItem();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadMediaItem() async {
    try {
      // TODO: Load specific media item
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _deleteMedia,
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareMedia,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_hasError || _mediaItem == null) {
      return const Center(
        child: Text(
          'Error loading media',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (_mediaItem!.type == MediaType.video) {
      return _buildVideoViewer();
    } else {
      return _buildImageViewer();
    }
  }

  Widget _buildImageViewer() {
    return PhotoView(
      imageProvider: NetworkImage(_mediaItem!.uri),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4.0,
      heroAttributes: PhotoViewHeroAttributes(tag: 'media_${_mediaItem!.id}'),
    );
  }

  Widget _buildVideoViewer() {
    return Center(
      child: AspectRatio(
        aspectRatio: _mediaItem!.width != null && _mediaItem!.height != null
            ? _mediaItem!.width! / _mediaItem!.height!
            : 16 / 9,
        child: VideoPlayer(_videoController!),
      ),
    );
  }

  void _deleteMedia() async {
    // TODO: Implement delete functionality
  }

  void _shareMedia() async {
    // TODO: Implement share functionality
  }
}
