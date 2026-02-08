import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../shared/domain/media_item.dart';
import '../../../shared/data/media_store_service.dart';
import '../../../shared/data/permission_service.dart';

class HiddenScreen extends ConsumerStatefulWidget {
  const HiddenScreen({super.key});

  @override
  ConsumerState<HiddenScreen> createState() => _HiddenScreenState();
}

class _HiddenScreenState extends ConsumerState<HiddenScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  List<MediaItem> _hiddenItems = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isUnlocked = false;
  bool _hasSetupSecurity = false;

  @override
  void initState() {
    super.initState();
    _checkSecuritySetup();
  }

  Future<void> _checkSecuritySetup() async {
    final hasPin = await _secureStorage.containsKey(key: 'hidden_pin');
    final hasBiometric = await _secureStorage.containsKey(
      key: 'biometric_enabled',
    );

    setState(() {
      _hasSetupSecurity = hasPin || hasBiometric;
    });

    if (_hasSetupSecurity) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    try {
      bool authenticated = false;
      final hasBiometric = await _secureStorage.containsKey(
        key: 'biometric_enabled',
      );

      if (hasBiometric) {
        authenticated = await _auth.authenticate(
          localizedReason: 'Authenticate to access hidden photos',
          options: const AuthenticationOptions(
            biometricOnly: true,
            useErrorDialogs: true,
            stickyAuth: true,
          ),
        );
      }

      if (!authenticated) {
        final pin = await _showPinDialog();
        authenticated = await _verifyPin(pin);
      }

      if (authenticated) {
        setState(() {
          _isUnlocked = true;
        });
        await _loadHiddenItems();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Authentication failed: ${e.toString()}';
      });
    }
  }

  Future<String?> _showPinDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter PIN'),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            hintText: '4-digit PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  Future<bool> _verifyPin(String? pin) async {
    if (pin == null || pin.length != 4) return false;

    final storedPin = await _secureStorage.read(key: 'hidden_pin');
    return pin == storedPin;
  }

  Future<void> _setupSecurity() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Setup Security'),
        content: const Text('Choose how to secure your hidden photos:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('pin'),
            child: const Text('PIN'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('biometric'),
            child: const Text('Biometric'),
          ),
        ],
      ),
    );

    if (result == 'pin') {
      await _setupPin();
    } else if (result == 'biometric') {
      await _setupBiometric();
    }
  }

  Future<void> _setupPin() async {
    final controller = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set PIN'),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(
            hintText: 'Enter 4-digit PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Set PIN'),
          ),
        ],
      ),
    );

    if (pin != null && pin.length == 4) {
      await _secureStorage.write(key: 'hidden_pin', value: pin);
      setState(() {
        _hasSetupSecurity = true;
      });
      _authenticate();
    }
  }

  Future<void> _setupBiometric() async {
    try {
      final canAuthenticate = await _auth.canCheckBiometrics;
      if (!canAuthenticate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication not available'),
          ),
        );
        return;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Setup biometric authentication',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        await _secureStorage.write(key: 'biometric_enabled', value: 'true');
        setState(() {
          _hasSetupSecurity = true;
        });
        _authenticate();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to setup biometric: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadHiddenItems() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // TODO: Load actual hidden items from secure storage
      await _simulateHiddenItems();

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

  Future<void> _simulateHiddenItems() async {
    // Simulate loading hidden items
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock hidden items
    _hiddenItems = [
      MediaItem(
        id: 'hidden_1',
        uri: 'content://media/external/images/1',
        name: 'private_photo.jpg',
        type: MediaType.image,
        size: 2048576,
        dateAdded: DateTime.now().subtract(const Duration(days: 1)),
        dateModified: DateTime.now().subtract(const Duration(days: 1)),
        width: 1920,
        height: 1080,
      ),
      MediaItem(
        id: 'hidden_2',
        uri: 'content://media/external/video/1',
        name: 'secret_video.mp4',
        type: MediaType.video,
        size: 10485760,
        dateAdded: DateTime.now().subtract(const Duration(days: 3)),
        dateModified: DateTime.now().subtract(const Duration(days: 3)),
        width: 1920,
        height: 1080,
        duration: 30,
      ),
    ];
  }

  Future<void> _refresh() async {
    await _loadHiddenItems();
  }

  Future<void> _unhideItem(MediaItem item) async {
    try {
      // TODO: Implement actual unhide logic
      setState(() {
        _hiddenItems.remove(item);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unhid ${item.name}'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                _hiddenItems.add(item);
              });
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unhide: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasSetupSecurity) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hidden')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Setup Security',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Protect your hidden photos with PIN or biometric',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _setupSecurity,
                icon: const Icon(Icons.security),
                label: const Text('Setup Security'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isUnlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hidden')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Locked',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Authenticate to access hidden photos',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hidden'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_open_outlined),
            onPressed: () {
              setState(() {
                _isUnlocked = false;
              });
            },
            tooltip: 'Lock',
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

    if (_hiddenItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hidden photos',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Long press on photos in the main gallery to hide them',
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
      child: GridView.builder(
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1.0,
        ),
        itemCount: _hiddenItems.length,
        itemBuilder: (context, index) {
          final item = _hiddenItems[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                // TODO: Navigate to viewer
              },
              onLongPress: () => _unhideItem(item),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.grey[300]),
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
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 16,
                      ),
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
}
