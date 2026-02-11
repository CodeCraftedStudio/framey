import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  bool _isVideoInitialized = false;
  bool _isControlsVisible = true;
  late final AnimationController _controlsAnimationController;
  late final Animation<double> _controlsFadeAnimation;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _controlsFadeAnimation = CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _controlsAnimationController.forward();
    _fadeController.forward();

    _loadMediaItem();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _controlsAnimationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadMediaItem() async {
    if (widget.mediaId == null) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }

    try {
      // Try to find the media item by loading more items if needed
      _mediaItem = await _findMediaItemById(widget.mediaId!);

      if (_mediaItem == null) {
        throw Exception('Media item not found');
      }

      // Initialize video controller if needed
      if (_mediaItem!.type == MediaType.video && _mediaItem!.uri.isNotEmpty) {
        if (_mediaItem!.uri.startsWith('file://')) {
          _videoController = VideoPlayerController.file(File(_mediaItem!.uri));
        } else {
          _videoController = VideoPlayerController.networkUrl(
            Uri.parse(_mediaItem!.uri),
          );
        }
        await _videoController!.initialize();
        _isVideoInitialized = true;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Framey: Error loading media item: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<MediaItem?> _findMediaItemById(String mediaId) async {
    int offset = 0;
    const int limit = 100;

    while (true) {
      final items = await MediaStoreService.getMediaItems(
        limit: limit,
        offset: offset,
      );

      // Search in current batch
      for (final item in items) {
        if (item.id == mediaId) {
          return item;
        }
      }

      // If we got fewer items than the limit, we've reached the end
      if (items.length < limit) {
        break;
      }

      // Continue to next batch
      offset += limit;

      // Prevent infinite loop - safety check
      if (offset > 10000) {
        break;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildContent(),
          _buildTopControls(),
          if (_mediaItem?.type == MediaType.video) _buildVideoControls(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_hasError || _mediaItem == null) {
      return Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Error loading media',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    if (_mediaItem!.type == MediaType.video) {
      return GestureDetector(
        onTap: _toggleControls,
        child: _buildVideoViewer(),
      );
    } else {
      return GestureDetector(
        onTap: _toggleControls,
        child: _buildImageViewer(),
      );
    }
  }

  Widget _buildTopControls() {
    return FadeTransition(
      opacity: _controlsFadeAnimation,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
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
      ),
    );
  }

  Widget _buildVideoControls() {
    if (!_isVideoInitialized || _videoController == null) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _controlsFadeAnimation,
      child: Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  backgroundColor: Colors.white24,
                  bufferedColor: Colors.white54,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _videoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      _videoController!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.white,
                        backgroundColor: Colors.white24,
                        bufferedColor: Colors.white54,
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(_videoController!.value.position),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const Text(
                    ' / ',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    _formatDuration(_videoController!.value.duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
      if (_isControlsVisible) {
        _controlsAnimationController.forward();
      } else {
        _controlsAnimationController.reverse();
      }
    });
  }

  void _togglePlayPause() {
    if (_videoController != null && _isVideoInitialized) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inHours > 0 ? twoDigits(duration.inHours) + ':' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildImageViewer() {
    return PhotoView(
      imageProvider: _getImageProvider(),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4.0,
      heroAttributes: PhotoViewHeroAttributes(tag: 'media_${_mediaItem!.id}'),
      loadingBuilder: (context, event) => Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          value: event == null
              ? null
              : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
        ),
      ),
      errorBuilder: (context, error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load image',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: ${error.toString()}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoViewer() {
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

  ImageProvider _getImageProvider() {
    if (_mediaItem!.uri.startsWith('file://')) {
      return FileImage(File(_mediaItem!.uri));
    } else if (_mediaItem!.uri.startsWith('http')) {
      return CachedNetworkImageProvider(_mediaItem!.uri);
    } else {
      return FileImage(File(_mediaItem!.uri));
    }
  }

  void _deleteMedia() async {
    if (_mediaItem == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: Text(
          'Are you sure you want to delete this ${_mediaItem!.type.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await MediaStoreService.deleteMediaItem(
          int.parse(_mediaItem!.id),
        );
        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Media deleted successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete media')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  void _shareMedia() async {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }
}
