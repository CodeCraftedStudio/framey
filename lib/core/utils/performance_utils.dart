import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

class PerformanceUtils {
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static const Duration _throttleDelay = Duration(milliseconds: 100);

  static VoidCallback debounce(
    VoidCallback callback, [
    Duration delay = _debounceDelay,
  ]) {
    Timer? timer;
    return () {
      timer?.cancel();
      timer = Timer(delay, callback);
    };
  }

  static VoidCallback throttle(
    VoidCallback callback, [
    Duration delay = _throttleDelay,
  ]) {
    bool isThrottled = false;
    return () {
      if (isThrottled) return;
      isThrottled = true;
      callback();
      Timer(delay, () => isThrottled = false);
    };
  }

  static void optimizeScrollPerformance(ScrollController controller) {
    controller.addListener(
      throttle(() {
        final position = controller.position;
        // Check if scrolling is active by monitoring pixels
        if (position.pixels != position.minScrollExtent &&
            position.pixels != position.maxScrollExtent) {
          // Reduce image quality during fast scrolling
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              systemNavigationBarColor: Colors.transparent,
            ),
          );
        }
      }),
    );
  }

  static Widget buildOptimizedImage({
    required Widget child,
    bool enableCache = true,
    Duration cacheDuration = const Duration(hours: 1),
  }) {
    if (!enableCache) return child;

    return RepaintBoundary(
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
        child: child,
      ),
    );
  }

  static Future<void> preloadImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    if (imageUrls.isEmpty) return;

    final futures = imageUrls.map((url) {
      return precacheImage(NetworkImage(url), context);
    }).toList();

    await Future.wait(futures);
  }

  static Widget buildSkeletonLoader({
    required double width,
    required double height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
      child: _ShimmerEffect(),
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  @override
  State<_ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!],
              stops: [0.0, _animation.value.clamp(0.0, 1.0), 1.0],
            ),
          ),
        );
      },
    );
  }
}
