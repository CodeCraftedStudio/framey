import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../shared/domain/media_item.dart';
import '../../../core/constants/app_constants.dart';

class RecycleBinScreen extends ConsumerStatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  ConsumerState<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends ConsumerState<RecycleBinScreen> {
  List<MediaItem> _deletedItems = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeletedItems();
  }

  Future<void> _loadDeletedItems() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // TODO: Load actual deleted items from database
      await _simulateDeletedItems();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _simulateDeletedItems() async {
    // Simulate loading deleted items
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock deleted items with timestamps
    final now = DateTime.now();
    _deletedItems = [
      MediaItem(
        id: 'deleted_1',
        uri: 'content://media/external/images/1',
        name: 'IMG_001.jpg',
        type: MediaType.image,
        size: 2048576,
        dateAdded: now.subtract(const Duration(days: 5)),
        dateModified: now.subtract(const Duration(days: 5)),
        width: 1920,
        height: 1080,
      ),
      MediaItem(
        id: 'deleted_2',
        uri: 'content://media/external/video/1',
        name: 'VID_001.mp4',
        type: MediaType.video,
        size: 10485760,
        dateAdded: now.subtract(const Duration(days: 10)),
        dateModified: now.subtract(const Duration(days: 10)),
        width: 1920,
        height: 1080,
        duration: 30,
      ),
      MediaItem(
        id: 'deleted_3',
        uri: 'content://media/external/images/2',
        name: 'IMG_002.jpg',
        type: MediaType.image,
        size: 1536000,
        dateAdded: now.subtract(const Duration(days: 15)),
        dateModified: now.subtract(const Duration(days: 15)),
        width: 1280,
        height: 720,
      ),
    ];
  }

  Future<void> _refresh() async {
    await _loadDeletedItems();
  }

  Future<void> _restoreItem(MediaItem item) async {
    try {
      // TODO: Implement actual restore logic
      setState(() {
        _deletedItems.remove(item);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restored ${item.name}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                _deletedItems.add(item);
              });
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to restore: ${e.toString()}')),
      );
    }
  }

  Future<void> _permanentDeleteItem(MediaItem item) async {
    try {
      // TODO: Implement actual permanent delete
      setState(() {
        _deletedItems.remove(item);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permanently deleted ${item.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: ${e.toString()}')),
      );
    }
  }

  Future<void> _emptyRecycleBin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Recycle Bin?'),
        content: const Text(
          'This will permanently delete all items. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implement actual empty recycle bin
        setState(() {
          _deletedItems.clear();
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Recycle bin emptied')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to empty: ${e.toString()}')),
        );
      }
    }
  }

  String _getDaysRemaining(DateTime deletedDate) {
    final daysSinceDeletion = DateTime.now().difference(deletedDate).inDays;
    final daysRemaining =
        AppConstants.recycleBinRetention.inDays - daysSinceDeletion;

    if (daysRemaining <= 0) {
      return 'Expires today';
    } else if (daysRemaining == 1) {
      return 'Expires tomorrow';
    } else {
      return 'Expires in $daysRemaining days';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recycle Bin'),
        actions: [
          if (_deletedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _emptyRecycleBin,
              tooltip: 'Empty Recycle Bin',
            ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_deletedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Recycle bin is empty',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deleted items will appear here for ${AppConstants.recycleBinRetention.inDays} days',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _deletedItems.length,
        itemBuilder: (context, index) {
          final item = _deletedItems[index];
          return _buildDeletedItemCard(item);
        },
      ),
    );
  }

  Widget _buildDeletedItemCard(MediaItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: item.thumbnailUri != null
              ? Image.network(
                  item.thumbnailUri!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      item.type == MediaType.video
                          ? Icons.videocam_outlined
                          : Icons.image_outlined,
                      color: Colors.grey[600],
                    );
                  },
                )
              : Icon(
                  item.type == MediaType.video
                      ? Icons.videocam_outlined
                      : Icons.image_outlined,
                  color: Colors.grey[600],
                ),
        ),
        title: Text(item.name, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getDaysRemaining(item.dateAdded),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Deleted ${DateFormat('MMM d, yyyy').format(item.dateAdded)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'restore':
                _restoreItem(item);
                break;
              case 'delete':
                _permanentDeleteItem(item);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'restore',
              child: Row(
                children: [
                  Icon(Icons.restore_outlined),
                  SizedBox(width: 8),
                  Text('Restore'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_forever_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Forever', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
