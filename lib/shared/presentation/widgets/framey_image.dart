import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../data/media_store_service.dart';

class FrameyImage extends StatelessWidget {
  final String uri;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const FrameyImage({
    super.key,
    required this.uri,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // If the widget is large (viewer), load high res.
    final isLarge = (width ?? 1000) > 600 || (height ?? 1000) > 600;
    final targetWidth = isLarge ? 1024 : 400;
    final targetHeight = isLarge ? 1024 : 400;

    return Image(
      image: provider(uri, width: targetWidth, height: targetHeight),
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? _buildPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildError();
      },
    );
  }

  static ImageProvider provider(String uri, {int? width, int? height}) {
    if (uri.startsWith('content://')) {
      // Since we have to load bytes for content://, we use a custom provider approach
      // or simply use the memory provider pattern but wrapped.
      // However, Image.memory needs bytes. ImageProvider needs to be synchronous return.
      // The best way to use existing logic is creating a custom ImageProvider,
      // but for simplicity and to reuse MediaStoreService, we can't easily make a standard ImageProvider
      // without a new class.

      // BUT, to solve the User's "Blurry" issue in PhotoView, we need an ImageProvider.
      // Let's implement a `MediaStoreImageProvider`!

      // For now, let's assume we can use MemoryImage if we preload, but we can't here.
      // So we will stick to the previous FutureBuilder approach in `build`
      // BUT return a `ResizeImage` or similar for `provider` if possible.

      // Actually, there's no built-in "ContentUriImageProvider" in Flutter.
      // We should return a `FileImage` if possible (it works for some content uris on newer android if path is resolved?? No.)

      // Wait, `FrameyImage` in `build` is using `FutureBuilder`. That works for Widgets.
      // `MediaViewer` needs an `ImageProvider`.

      // Let's define `MediaStoreImageProvider` in this file or helper.
      return MediaStoreImageProvider(uri, width: width, height: height);
    }

    if (uri.startsWith('http')) {
      return NetworkImage(uri);
    }

    return FileImage(File(uri));
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.withOpacity(0.1),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.withOpacity(0.1),
      child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
    );
  }
}

class MediaStoreImageProvider extends ImageProvider<MediaStoreImageProvider> {
  final String uri;
  final int? width;
  final int? height;

  const MediaStoreImageProvider(this.uri, {this.width, this.height});

  @override
  Future<MediaStoreImageProvider> obtainKey(ImageConfiguration configuration) {
    return Future.value(this);
  }

  @override
  ImageStreamCompleter loadBuffer(
    MediaStoreImageProvider key,
    DecoderBufferCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      debugLabel: uri,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<MediaStoreImageProvider>('Image key', key),
      ],
    );
  }

  @override
  ImageStreamCompleter loadImage(
    MediaStoreImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, (buffer) => decode(buffer)),
      scale: 1.0,
      debugLabel: uri,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<MediaStoreImageProvider>('Image key', key),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    MediaStoreImageProvider key,
    Future<ui.Codec> Function(ui.ImmutableBuffer) decode,
  ) async {
    try {
      final isLarge = (key.width ?? 0) > 600 || (key.height ?? 0) > 600;
      Uint8List? bytes;

      if (isLarge) {
        // For large images (viewer), load original bytes to avoid native re-compression overhead
        // and ensure full quality (no blur).
        debugPrint(
          'Framey: Loading original bytes for ${key.uri} (Viewer Mode)',
        );
        bytes = await MediaStoreService.getMediaBytes(key.uri);
      }

      if (bytes == null || bytes.isEmpty) {
        if (isLarge)
          debugPrint('Framey: getMediaBytes failed, falling back to thumbnail');
        final int size = isLarge ? 1024 : (key.width ?? 512);
        bytes = await MediaStoreService.getMediaThumbnail(
          key.uri,
          width: size,
          height: size,
        );
      }

      if (bytes == null || bytes.isEmpty) {
        throw StateError('Failed to load image bytes for ${key.uri}');
      }

      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    } catch (e) {
      // Fallback: Return empty/transparent 1x1 image instead of crashing
      // 1x1 transparent pixel
      final transparentBytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0B,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x60,
        0x00,
        0x00,
        0x00,
        0x02,
        0x00,
        0x01,
        0xE2,
        0x21,
        0xBC,
        0x33,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);
      final buffer = await ui.ImmutableBuffer.fromUint8List(transparentBytes);
      return decode(buffer);
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is MediaStoreImageProvider &&
        other.uri == uri &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(uri, width, height);
}
