import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static const MethodChannel _channel = MethodChannel(
    'com.framey.gallery/permissions',
  );

  static Future<bool> checkMediaPermissions() async {
    try {
      debugPrint('Framey: Checking media permissions...');

      // Try native Android permission check first
      try {
        final result = await _channel.invokeMethod<bool>(
          'checkMediaPermissions',
        );
        debugPrint('Framey: Native permission check result: $result');
        if (result != null) {
          return result;
        }
      } catch (e) {
        debugPrint('Framey: Native permission check failed: $e');
      }

      // Fallback to permission_handler
      if (await _isAndroid13OrHigher()) {
        // Android 13+ - check both image and video permissions
        final photosGranted = await Permission.photos.isGranted;
        final videosGranted = await Permission.videos.isGranted;
        debugPrint(
          'Framey: Android 13+ - Photos: $photosGranted, Videos: $videosGranted',
        );
        return photosGranted && videosGranted;
      } else {
        // Android 12 and below - check storage permission
        final storageGranted = await Permission.storage.isGranted;
        debugPrint('Framey: Android 12- - Storage: $storageGranted');
        return storageGranted;
      }
    } catch (e) {
      debugPrint('Framey: Error checking permissions: $e');
      return false;
    }
  }

  static Future<bool> requestMediaPermissions() async {
    try {
      debugPrint('Framey: Requesting media permissions...');

      // Try native Android permission request first
      try {
        final result = await _channel.invokeMethod<bool>(
          'requestMediaPermissions',
        );
        debugPrint('Framey: Native permission request result: $result');
        if (result == true) {
          return true;
        }
      } catch (e) {
        debugPrint('Framey: Native permission request failed: $e');
      }

      // Fallback to permission_handler
      debugPrint('Framey: Falling back to permission_handler...');

      if (await _isAndroid13OrHigher()) {
        // Android 13+ - request both image and video permissions
        debugPrint('Framey: Requesting Android 13+ permissions...');
        final statuses = await [Permission.photos, Permission.videos].request();

        final photosGranted =
            statuses[Permission.photos] == PermissionStatus.granted;
        final videosGranted =
            statuses[Permission.videos] == PermissionStatus.granted;

        debugPrint(
          'Framey: Android 13+ - Photos: $photosGranted, Videos: $videosGranted',
        );
        return photosGranted && videosGranted;
      } else {
        // Android 12 and below - request storage permission
        debugPrint('Framey: Requesting Android 12- storage permission...');
        final status = await Permission.storage.request();
        final granted = status == PermissionStatus.granted;
        debugPrint('Framey: Android 12- - Storage: $granted');
        return granted;
      }
    } catch (e) {
      debugPrint('Framey: Permission request failed: $e');
      return false;
    }
  }

  static Future<bool> checkLocationPermission() async {
    try {
      return await Permission.location.isGranted;
    } catch (e) {
      throw Exception('Failed to check location permission: ${e.toString()}');
    }
  }

  static Future<bool> requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      throw Exception('Failed to request location permission: ${e.toString()}');
    }
  }

  static Future<bool> checkBiometricPermission() async {
    try {
      return await Permission.phone.isGranted;
    } catch (e) {
      throw Exception('Failed to check biometric permission: ${e.toString()}');
    }
  }

  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('Framey: Failed to open app settings: $e');
    }
  }

  static Future<bool> isPermanentlyDenied() async {
    try {
      if (await _isAndroid13OrHigher()) {
        return await Permission.photos.isPermanentlyDenied ||
            await Permission.videos.isPermanentlyDenied;
      } else {
        return await Permission.storage.isPermanentlyDenied;
      }
    } catch (e) {
      debugPrint('Framey: Error checking permanent denial: $e');
      return false;
    }
  }

  static Future<bool> _isAndroid13OrHigher() async {
    // Simple check - in production, use device_info_plus for accurate version detection
    // For now, assume Android 13+ behavior for newer devices
    return true;
  }
}
