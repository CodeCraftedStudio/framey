import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/errors/exceptions.dart';
import '../../core/constants/app_constants.dart';
import '../domain/media_item.dart';
import '../domain/album.dart';

class MediaStoreService {
  static const MethodChannel _channel = MethodChannel(
    AppConstants.mediaStoreChannel,
  );

  static Future<List<MediaItem>> getMediaItems({
    String? albumId,
    String? mediaType,
    int limit = AppConstants.defaultPageSize,
    int offset = 0,
    bool includeTrashed = false,
    bool includeHidden = false,
    String? searchQuery,
  }) async {
    debugPrint(
      'Framey: Flutter calling getMediaItems - albumId: $albumId, mediaType: $mediaType, limit: $limit, offset: $offset',
    );
    try {
      final result = await _channel
          .invokeMethod<List<dynamic>>('getMediaItems', {
            'albumId': albumId,
            'mediaType': mediaType,
            'limit': limit,
            'offset': offset,
            'includeTrashed': includeTrashed,
            'includeHidden': includeHidden,
            'searchQuery': searchQuery,
          });

      debugPrint(
        'Framey: Flutter received result from getMediaItems: ${result?.length ?? 0} items',
      );
      if (result == null) {
        debugPrint('Framey: Error - MediaStore returned null result');
        throw Exception('Failed to get media items: null result');
      }

      debugPrint('Framey: Processing ${result.length} media items...');
      return result.map((jsonString) {
        try {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          return MediaItem.fromJson(json);
        } catch (e) {
          debugPrint('Framey: Error parsing media item: $e');
          debugPrint('Framey: Invalid JSON: $jsonString');
          rethrow;
        }
      }).toList();
    } catch (e) {
      debugPrint('Framey: Error in getMediaItems: $e');
      throw Exception('Failed to get media items: ${e.toString()}');
    }
  }

  static Future<List<Album>> getAlbums() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getAlbums');

      if (result == null) {
        throw const MediaStoreException('Failed to get albums: null result');
      }

      return result.map((jsonString) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return Album.fromJson(json);
      }).toList();
    } on PlatformException catch (e) {
      throw MediaStoreException(
        e.message ?? 'Unknown platform error',
        code: e.code,
      );
    } catch (e) {
      throw MediaStoreException('Unexpected error: ${e.toString()}');
    }
  }

  static Future<bool> deleteMediaItem(int mediaId) async {
    try {
      final result = await _channel.invokeMethod<bool>('deleteMediaItem', {
        'mediaId': mediaId,
      });

      return result ?? false;
    } on PlatformException catch (e) {
      throw MediaStoreException(
        e.message ?? 'Unknown platform error',
        code: e.code,
      );
    } catch (e) {
      throw MediaStoreException('Unexpected error: ${e.toString()}');
    }
  }

  static Future<bool> moveToRecycleBin(int mediaId) async {
    try {
      final result = await _channel.invokeMethod<bool>('moveToRecycleBin', {
        'mediaId': mediaId,
      });

      return result ?? false;
    } on PlatformException catch (e) {
      throw MediaStoreException(
        e.message ?? 'Unknown platform error',
        code: e.code,
      );
    } catch (e) {
      throw MediaStoreException('Unexpected error: ${e.toString()}');
    }
  }

  static Future<bool> restoreFromRecycleBin(int mediaId) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'restoreFromRecycleBin',
        {'mediaId': mediaId},
      );

      return result ?? false;
    } on PlatformException catch (e) {
      throw MediaStoreException(
        e.message ?? 'Unknown platform error',
        code: e.code,
      );
    } catch (e) {
      throw MediaStoreException('Unexpected error: ${e.toString()}');
    }
  }

  static Future<Map<String, bool>> checkPermissions() async {
    try {
      final result = await _channel.invokeMethod<Map<String, dynamic>>(
        'checkPermissions',
      );
      return result?.cast<String, bool>() ?? {};
    } on PlatformException catch (e) {
      throw MediaStoreException(
        e.message ?? 'Unknown platform error',
        code: e.code,
      );
    } catch (e) {
      throw MediaStoreException('Unexpected error: ${e.toString()}');
    }
  }

  static Future<bool> requestPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermissions');
      return result ?? false;
    } on PlatformException catch (e) {
      throw MediaStoreException(
        e.message ?? 'Unknown platform error',
        code: e.code,
      );
    } catch (e) {
      throw MediaStoreException('Unexpected error: ${e.toString()}');
    }
  }

  static Future<bool> deletePermanently(int mediaId) async {
    try {
      final result = await _channel.invokeMethod<bool>('deletePermanently', {
        'mediaId': mediaId,
      });

      return result ?? false;
    } on PlatformException catch (e) {
      throw MediaStoreException(
        e.message ?? 'Unknown platform error',
        code: e.code,
      );
    } catch (e) {
      throw MediaStoreException('Unexpected error: ${e.toString()}');
    }
  }

  static Future<bool> emptyRecycleBin() async {
    try {
      final result = await _channel.invokeMethod<bool>('emptyRecycleBin');
      return result ?? false;
    } on PlatformException catch (e) {
      throw MediaStoreException(
        e.message ?? 'Unknown platform error',
        code: e.code,
      );
    } catch (e) {
      throw MediaStoreException('Unexpected error: ${e.toString()}');
    }
  }

  static Future<bool> hideMediaItem(int mediaId) async {
    try {
      final result = await _channel.invokeMethod<bool>('hideMediaItem', {
        'mediaId': mediaId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw MediaStoreException(
        e.message ?? 'Unknown platform error',
        code: e.code,
      );
    } catch (e) {
      throw MediaStoreException('Unexpected error: ${e.toString()}');
    }
  }

  static Future<bool> unhideMediaItem(int mediaId) async {
    try {
      final result = await _channel.invokeMethod<bool>('unhideMediaItem', {
        'mediaId': mediaId,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw MediaStoreException(
        e.message ?? 'Unknown platform error',
        code: e.code,
      );
    } catch (e) {
      throw MediaStoreException('Unexpected error: ${e.toString()}');
    }
  }
}
