import 'package:equatable/equatable.dart';

enum MediaType { image, video }

class MediaItem extends Equatable {
  final String id;
  final String uri;
  final String name;
  final MediaType type;
  final int size;
  final DateTime dateAdded;
  final DateTime dateModified;
  final int? width;
  final int? height;
  final int? duration; // in seconds for videos
  final String? thumbnailUri;
  final Map<String, dynamic>? metadata;

  const MediaItem({
    required this.id,
    required this.uri,
    required this.name,
    required this.type,
    required this.size,
    required this.dateAdded,
    required this.dateModified,
    this.width,
    this.height,
    this.duration,
    this.thumbnailUri,
    this.metadata,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'].toString(),
      uri: json['uri'] as String,
      name: json['name'] as String,
      type: json['type'] == 'image' ? MediaType.image : MediaType.video,
      size: json['size'] as int,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(
        (json['dateAdded'] as int) * 1000,
      ),
      dateModified: DateTime.fromMillisecondsSinceEpoch(
        (json['dateModified'] as int) * 1000,
      ),
      width: json['width'] as int?,
      height: json['height'] as int?,
      duration: json['duration'] as int?,
      thumbnailUri: json['thumbnailUri'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uri': uri,
      'name': name,
      'type': type.name,
      'size': size,
      'dateAdded': dateAdded.millisecondsSinceEpoch ~/ 1000,
      'dateModified': dateModified.millisecondsSinceEpoch ~/ 1000,
      'width': width,
      'height': height,
      'duration': duration,
      'thumbnailUri': thumbnailUri,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
    id,
    uri,
    name,
    type,
    size,
    dateAdded,
    dateModified,
    width,
    height,
    duration,
    thumbnailUri,
    metadata,
  ];

  MediaItem copyWith({
    String? id,
    String? uri,
    String? name,
    MediaType? type,
    int? size,
    DateTime? dateAdded,
    DateTime? dateModified,
    int? width,
    int? height,
    int? duration,
    String? thumbnailUri,
    Map<String, dynamic>? metadata,
  }) {
    return MediaItem(
      id: id ?? this.id,
      uri: uri ?? this.uri,
      name: name ?? this.name,
      type: type ?? this.type,
      size: size ?? this.size,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      width: width ?? this.width,
      height: height ?? this.height,
      duration: duration ?? this.duration,
      thumbnailUri: thumbnailUri ?? this.thumbnailUri,
      metadata: metadata ?? this.metadata,
    );
  }
}
