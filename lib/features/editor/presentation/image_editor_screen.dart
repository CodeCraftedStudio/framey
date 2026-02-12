import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/domain/media_item.dart';

class ImageEditorScreen extends StatefulWidget {
  final MediaItem mediaItem;
  const ImageEditorScreen({super.key, required this.mediaItem});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  double _rotation = 0;
  double _brightness = 1.0;
  double _contrast = 1.0;
  String _activeTool = 'Crop';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildImagePreview()),
          _buildToolbar(),
          _buildToolOptions(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close_rounded, color: Colors.white),
      ),
      title: Text(
        'Edit',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {},
          child: const Text(
            'Save',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Transform.rotate(
          angle: _rotation,
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix([
              _contrast,
              0,
              0,
              0,
              (1 - _contrast) * 128 + (_brightness - 1) * 255,
              0,
              _contrast,
              0,
              0,
              (1 - _contrast) * 128 + (_brightness - 1) * 255,
              0,
              0,
              _contrast,
              0,
              (1 - _contrast) * 128 + (_brightness - 1) * 255,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(widget.mediaItem.uri),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildToolItem(Icons.crop_rounded, 'Crop'),
          _buildToolItem(Icons.tune_rounded, 'Adjust'),
          _buildToolItem(Icons.auto_awesome_rounded, 'Filters'),
          _buildToolItem(Icons.brush_rounded, 'Markup'),
        ],
      ),
    );
  }

  Widget _buildToolItem(IconData icon, String label) {
    final isSelected = _activeTool == label;
    return GestureDetector(
      onTap: () => setState(() => _activeTool = label),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.blue : Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.white.withOpacity(0.6),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolOptions() {
    if (_activeTool == 'Adjust') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            _buildSlider(
              'Brightness',
              _brightness,
              0.5,
              1.5,
              (v) => setState(() => _brightness = v),
            ),
            _buildSlider(
              'Contrast',
              _contrast,
              0.5,
              1.5,
              (v) => setState(() => _contrast = v),
            ),
          ],
        ),
      );
    }

    if (_activeTool == 'Crop') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOptionButton(Icons.rotate_left_rounded, 'Rotate', () {
            setState(() => _rotation -= 1.5708); // 90 degrees in radians
          }),
          const SizedBox(width: 32),
          _buildOptionButton(Icons.flip_rounded, 'Flip', () {}),
        ],
      );
    }

    return Container(
      height: 50,
      alignment: Alignment.center,
      child: const Text(
        'Tool options coming soon',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: Colors.blue,
            inactiveColor: Colors.white24,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white10,
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
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
