import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/domain/media_item.dart';

class HiddenScreen extends ConsumerStatefulWidget {
  const HiddenScreen({super.key});

  @override
  ConsumerState<HiddenScreen> createState() => _HiddenScreenState();
}

class _HiddenScreenState extends ConsumerState<HiddenScreen> {
  bool _isAuthenticated = false;
  List<MediaItem> _hiddenItems = [];

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) return _buildAuthScreen();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Hidden Locker',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -1,
          ),
        ),
      ),
      body: _hiddenItems.isEmpty ? _buildEmptyState() : _buildGrid(),
    );
  }

  Widget _buildAuthScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Secure Access',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please enter your PIN or use biometrics to access hidden media',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 48),
            _buildPinField(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => setState(() => _isAuthenticated = true),
                child: const Text('Unlock with Biometrics'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        4,
        (index) => Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_off_rounded,
            size: 80,
            color: Colors.grey.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No hidden items yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: _hiddenItems.length,
      itemBuilder: (context, index) {
        final item = _hiddenItems[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: item.thumbnailUri != null
              ? Image.file(File(item.thumbnailUri!), fit: BoxFit.cover)
              : Container(
                  color: Colors.grey.withOpacity(0.1),
                  child: const Icon(Icons.image),
                ),
        );
      },
    );
  }
}
