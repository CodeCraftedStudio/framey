import 'dart:io';
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
    if (uri.startsWith('content://')) {
      return FutureBuilder<Uint8List?>(
        future: MediaStoreService.getMediaThumbnail(
          uri,
          width: 400,
          height: 400,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return placeholder ?? _buildPlaceholder();
          }
          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: fit,
              width: width,
              height: height,
            );
          }
          return errorWidget ?? _buildError();
        },
      );
    }

    if (uri.startsWith('http')) {
      return Image.network(
        uri,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? _buildError(),
      );
    }

    // Default to File image
    return Image.file(
      File(uri),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) =>
          errorWidget ?? _buildError(),
    );
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
