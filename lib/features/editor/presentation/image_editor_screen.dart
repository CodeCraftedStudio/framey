import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/services.dart';
import '../../../shared/domain/media_item.dart';
import '../../../shared/data/media_store_service.dart';

class ImageEditorScreen extends StatefulWidget {
  final MediaItem mediaItem;
  const ImageEditorScreen({super.key, required this.mediaItem});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isSaving = false;
  double _rotation = 0;
  double _brightness = 1.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  String _activeTool = 'Adjust';
  final _cropController = CropController();
  Uint8List? _imageBytes;
  bool _isCropping = false;
  bool _isLoadingBytes = true;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    try {
      final bytes = await MediaStoreService.getMediaBytes(widget.mediaItem.uri);
      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoadingBytes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBytes = false);
      }
    }
  }

  final List<Map<String, dynamic>> _filters = [
    {'name': 'Original', 'matrix': null},
    {
      'name': 'Vivid',
      'matrix': <double>[
        1.2,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.2,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.2,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ],
    },
    {
      'name': 'Mono',
      'matrix': <double>[
        0.33,
        0.59,
        0.11,
        0.0,
        0.0,
        0.33,
        0.59,
        0.11,
        0.0,
        0.0,
        0.33,
        0.59,
        0.11,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ],
    },
    {
      'name': 'Cool',
      'matrix': <double>[
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.2,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ],
    },
    {
      'name': 'Warm',
      'matrix': <double>[
        1.2,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.8,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ],
    },
    {
      'name': 'Sepia',
      'matrix': <double>[
        0.393,
        0.769,
        0.189,
        0.0,
        0.0,
        0.349,
        0.686,
        0.168,
        0.0,
        0.0,
        0.272,
        0.534,
        0.131,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        1.0,
        0.0,
      ],
    },
  ];

  List<double>? _activeFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildImagePreview()),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
          Text(
            'Edit',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          TextButton(
            onPressed: _isSaving ? null : _saveImage,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_isLoadingBytes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_isCropping && _imageBytes != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Crop(
            image: _imageBytes!,
            controller: _cropController,
            onCropped: (result) {
              if (result is CropSuccess) {
                setState(() {
                  _imageBytes = result.croppedImage;
                  _isCropping = false;
                });
              }
            },
            aspectRatio: null,
            initialRectBuilder: InitialRectBuilder.withSizeAndRatio(size: 0.8),
            baseColor: Colors.black,
            maskColor: Colors.black.withOpacity(0.5),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Hero(
          tag: 'media_${widget.mediaItem.id}',
          child: RepaintBoundary(
            key: _repaintKey,
            child: Transform.rotate(
              angle: _rotation,
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(_getMatrix()),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.contain)
                      : Image.file(
                          File(widget.mediaItem.uri),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.broken_image,
                                color: Colors.white,
                                size: 64,
                              ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveImage() async {
    setState(() => _isSaving = true);
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(buffer);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image saved to $filePath')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<double> _getMatrix() {
    // Basic brightness/contrast matrix
    double b = (_brightness - 1.0) * 255;
    double c = _contrast;

    List<double> matrix = [
      c,
      0,
      0,
      0,
      b,
      0,
      c,
      0,
      0,
      b,
      0,
      0,
      c,
      0,
      b,
      0,
      0,
      0,
      1,
      0,
    ];

    // Combine with filter if any
    if (_activeFilter != null) {
      // Simple combination (multiplication)
      for (int i = 0; i < 20; i++) {
        if (i % 5 != 4) {
          // Don't multiply offset columns too simply
          matrix[i] *= _activeFilter![i];
        }
      }
    }

    return matrix;
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToolSettings(),
          const SizedBox(height: 24),
          _buildToolSelector(),
        ],
      ),
    );
  }

  Widget _buildToolSettings() {
    if (_activeTool == 'Adjust') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            _buildAdjustSlider(
              Icons.wb_sunny_rounded,
              'Brightness',
              _brightness,
              0.5,
              1.5,
              (v) => setState(() => _brightness = v),
            ),
            _buildAdjustSlider(
              Icons.contrast_rounded,
              'Contrast',
              _contrast,
              0.5,
              1.5,
              (v) => setState(() => _contrast = v),
            ),
            _buildAdjustSlider(
              Icons.palette_rounded,
              'Saturation',
              _saturation,
              0.0,
              2.0,
              (v) => setState(() => _saturation = v),
            ),
          ],
        ),
      );
    }

    if (_activeTool == 'Filters') {
      return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final isSelected = _activeFilter == filter['matrix'];
            return GestureDetector(
              onTap: () => setState(
                () => _activeFilter = filter['matrix'] as List<double>?,
              ),
              child: Container(
                width: 70,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: Colors.blue, width: 2)
                            : null,
                        image: DecorationImage(
                          image: FileImage(File(widget.mediaItem.uri)),
                          fit: BoxFit.cover,
                          colorFilter: filter['matrix'] != null
                              ? ColorFilter.matrix(
                                  filter['matrix'] as List<double>? ?? [],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      filter['name'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.blue : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    if (_activeTool == 'Crop') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildActionButton(
            Icons.crop_rounded,
            _isCropping ? 'Apply' : 'Crop',
            () {
              if (_isCropping) {
                _cropController.crop();
              } else {
                setState(() => _isCropping = true);
              }
            },
          ),
          const SizedBox(width: 16),
          _buildActionButton(Icons.rotate_left_rounded, '90°', () {
            setState(() => _rotation -= 1.5708);
          }),
          const SizedBox(width: 16),
          _buildActionButton(Icons.aspect_ratio_rounded, 'Reset', () {
            setState(() {
              _isCropping = false;
              _rotation = 0;
            });
          }),
        ],
      );
    }

    return Container(
      height: 80,
      alignment: Alignment.center,
      child: Text(
        '${_activeTool} options coming soon',
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildAdjustSlider(
    IconData icon,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 16),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
                activeColor: Colors.blue,
                inactiveColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildToolItem(Icons.crop_rounded, 'Crop'),
          _buildToolItem(Icons.tune_rounded, 'Adjust'),
          _buildToolItem(Icons.auto_awesome_rounded, 'Filters'),
          _buildToolItem(Icons.brush_rounded, 'Markup'),
          _buildToolItem(Icons.more_horiz_rounded, 'More'),
        ],
      ),
    );
  }

  Widget _buildToolItem(IconData icon, String label) {
    final isSelected = _activeTool == label;
    return GestureDetector(
      onTap: () => setState(() => _activeTool = label),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white60,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
