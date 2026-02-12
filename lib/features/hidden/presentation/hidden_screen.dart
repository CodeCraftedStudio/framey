import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import '../../../shared/domain/media_item.dart';
import '../../../shared/data/media_store_service.dart';

class HiddenScreen extends ConsumerStatefulWidget {
  const HiddenScreen({super.key});

  @override
  ConsumerState<HiddenScreen> createState() => _HiddenScreenState();
}

class _HiddenScreenState extends ConsumerState<HiddenScreen> {
  bool _isAuthenticated = false;
  List<MediaItem> _hiddenItems = [];
  bool _isLoading = false;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (canAuthenticate) {
        final bool didAuthenticate = await _auth.authenticate(
          localizedReason: 'Please authenticate to access your hidden locker',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );
        if (didAuthenticate) {
          setState(() => _isAuthenticated = true);
          _loadHiddenItems();
        }
      } else {
        // Fallback or show message
        setState(
          () => _isAuthenticated = true,
        ); // For now just bypass if not supported
        _loadHiddenItems();
      }
    } catch (e) {
      debugPrint('Auth error: $e');
    }
  }

  Future<void> _loadHiddenItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await MediaStoreService.getMediaItems(
        includeHidden: true,
        limit: 100,
      );
      setState(() {
        _hiddenItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unhideItem(MediaItem item) async {
    try {
      final success = await MediaStoreService.unhideMediaItem(
        int.parse(item.id),
      );
      if (success) {
        _loadHiddenItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item restored to gallery')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
      }
    }
  }

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hiddenItems.isEmpty
          ? _buildEmptyState()
          : _buildGrid(),
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
                onPressed: _authenticate,
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
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/viewer',
              arguments: {'items': _hiddenItems, 'index': index},
            );
          },
          onLongPress: () {
            showModalBottomSheet(
              context: context,
              builder: (c) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.visibility_rounded),
                      title: const Text('Restore to Gallery'),
                      onTap: () {
                        Navigator.pop(c);
                        _unhideItem(item);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Delete Forever',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        Navigator.pop(c);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (d) => AlertDialog(
                            title: const Text('Delete Permanently?'),
                            content: const Text(
                              'This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(d, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(d, true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await MediaStoreService.deletePermanently(
                            int.parse(item.id),
                          );
                          _loadHiddenItems();
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Hero(
              tag: 'media_${item.id}',
              child: item.thumbnailUri != null
                  ? Image.file(File(item.thumbnailUri!), fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey.withOpacity(0.1),
                      child: const Icon(Icons.image),
                    ),
            ),
          ),
        );
      },
    );
  }
}
