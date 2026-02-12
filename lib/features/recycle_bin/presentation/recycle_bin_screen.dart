import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/domain/media_item.dart';

class RecycleBinScreen extends ConsumerStatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  ConsumerState<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends ConsumerState<RecycleBinScreen> {
  List<MediaItem> _deletedItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDeletedItems();
  }

  Future<void> _loadDeletedItems() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    final now = DateTime.now();
    _deletedItems = [
      MediaItem(
        id: 'del1',
        uri: '/storage/emulated/0/DCIM/Camera/IMG_1.jpg',
        thumbnailUri: '/storage/emulated/0/DCIM/Camera/.thumbnails/IMG_1.jpg',
        name: 'Hill_Trip.jpg',
        type: MediaType.image,
        size: 1024 * 1024 * 2,
        dateAdded: now.subtract(const Duration(days: 5)),
        dateModified: now.subtract(const Duration(days: 5)),
      ),
      MediaItem(
        id: 'del2',
        uri: '/storage/emulated/0/DCIM/Camera/IMG_2.jpg',
        thumbnailUri: '/storage/emulated/0/DCIM/Camera/.thumbnails/IMG_2.jpg',
        name: 'Beach_Fun.jpg',
        type: MediaType.image,
        size: 1024 * 1024 * 3,
        dateAdded: now.subtract(const Duration(days: 12)),
        dateModified: now.subtract(const Duration(days: 12)),
      ),
    ];
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Recycle Bin',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -1,
          ),
        ),
        actions: [
          if (_deletedItems.isNotEmpty)
            TextButton(
              onPressed: () {},
              child: const Text(
                'Empty',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deletedItems.isEmpty
          ? _buildEmptyState()
          : _buildList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline_rounded,
            size: 80,
            color: Colors.grey.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Recycle bin is empty',
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

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: _deletedItems.length,
      itemBuilder: (context, index) {
        final item = _deletedItems[index];
        final daysPassed = DateTime.now().difference(item.dateAdded).inDays;
        final progress = (30 - daysPassed) / 30;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 60,
                height: 60,
                child:
                    item.thumbnailUri != null &&
                        File(item.thumbnailUri!).existsSync()
                    ? Image.file(File(item.thumbnailUri!), fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.withOpacity(0.1),
                        child: const Icon(Icons.image),
                      ),
              ),
            ),
            title: Text(
              item.name,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.withOpacity(0.1),
                        color: progress < 0.2
                            ? Colors.redAccent
                            : Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${30 - daysPassed}d left',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert_rounded),
              itemBuilder: (context) => [
                const PopupMenuItem(child: Text('Restore')),
                const PopupMenuItem(
                  child: Text(
                    'Delete Forever',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
