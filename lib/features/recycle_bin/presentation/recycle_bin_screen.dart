import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/domain/media_item.dart';
import '../../../shared/data/media_store_service.dart';

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
    try {
      final items = await MediaStoreService.getMediaItems(
        includeTrashed: true,
        limit: 100,
      );
      setState(() {
        _deletedItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading trashed items: $e')),
        );
      }
    }
  }

  Future<void> _restoreItem(MediaItem item) async {
    try {
      final success = await MediaStoreService.restoreFromRecycleBin(
        int.parse(item.id),
      );
      if (success) {
        _loadDeletedItems();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Item restored')));
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

  Future<void> _deletePermanently(MediaItem item) async {
    try {
      final success = await MediaStoreService.deletePermanently(
        int.parse(item.id),
      );
      if (success) {
        _loadDeletedItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted permanently')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _emptyBin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Empty Recycle Bin?'),
        content: const Text(
          'This will permanently delete all items in the bin. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Empty Bin', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await MediaStoreService.emptyRecycleBin();
        _loadDeletedItems();
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to empty bin: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
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
              onPressed: _emptyBin,
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

        final deletedAtMillis =
            item.metadata?['deletedAt'] as int? ??
            DateTime.now().millisecondsSinceEpoch;
        final deletedAt = DateTime.fromMillisecondsSinceEpoch(deletedAtMillis);
        final daysSinceDeletion = DateTime.now().difference(deletedAt).inDays;
        final daysLeft = 30 - daysSinceDeletion;
        final progress = (daysLeft.clamp(0, 30)) / 30;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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
                        child: Icon(
                          item.type == MediaType.video
                              ? Icons.play_circle_outline
                              : Icons.image,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            title: Text(
              item.name,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                            : Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${daysLeft}d left',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: progress < 0.2 ? Colors.redAccent : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () => _restoreItem(item),
                  child: const Row(
                    children: [
                      Icon(Icons.restore_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Restore'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () => _deletePermanently(item),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.delete_forever_rounded,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Delete Forever',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ],
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
