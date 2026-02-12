import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/media_item.dart';
import 'media_store_service.dart';

final mediaItemsProvider =
    StateNotifierProvider<MediaItemsNotifier, MediaItemsState>((ref) {
      return MediaItemsNotifier();
    });

class MediaItemsState {
  final List<MediaItem> items;
  final bool isLoading;
  final String? errorMessage;

  MediaItemsState({
    required this.items,
    this.isLoading = false,
    this.errorMessage,
  });

  MediaItemsState copyWith({
    List<MediaItem>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MediaItemsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class MediaItemsNotifier extends StateNotifier<MediaItemsState> {
  MediaItemsNotifier() : super(MediaItemsState(items: []));

  Future<void> loadMediaItems({
    String? albumId,
    int limit = 100,
    int offset = 0,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await MediaStoreService.getMediaItems(
        albumId: albumId,
        limit: limit,
        offset: offset,
      );
      if (offset == 0) {
        state = state.copyWith(items: items, isLoading: false);
      } else {
        state = state.copyWith(
          items: [...state.items, ...items],
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}
