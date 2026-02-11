import 'package:equatable/equatable.dart';

enum AlbumType { system, custom, hidden, recycle_bin }

class Album extends Equatable {
  final String id;
  final String name;
  final AlbumType type;
  final String? coverUri;
  final int mediaCount;
  final DateTime? lastModified;
  final Map<String, dynamic>? metadata;

  const Album({
    required this.id,
    required this.name,
    required this.type,
    this.coverUri,
    required this.mediaCount,
    this.lastModified,
    this.metadata,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as String,
      name: json['name'] as String,
      type: _parseAlbumType(json['type'] as String),
      coverUri: json['coverUri'] as String?,
      mediaCount: json['mediaCount'] as int,
      lastModified: json['lastModified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['lastModified'] as int) * 1000,
            )
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  static AlbumType _parseAlbumType(String typeString) {
    switch (typeString) {
      case 'system':
        return AlbumType.system;
      case 'custom':
        return AlbumType.custom;
      case 'hidden':
        return AlbumType.hidden;
      case 'recycle_bin':
        return AlbumType.recycle_bin;
      default:
        return AlbumType.system;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'coverUri': coverUri,
      'mediaCount': mediaCount,
      'lastModified': lastModified?.millisecondsSinceEpoch,
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    coverUri,
    mediaCount,
    lastModified,
    metadata,
  ];

  Album copyWith({
    String? id,
    String? name,
    AlbumType? type,
    String? coverUri,
    int? mediaCount,
    DateTime? lastModified,
    Map<String, dynamic>? metadata,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      coverUri: coverUri ?? this.coverUri,
      mediaCount: mediaCount ?? this.mediaCount,
      lastModified: lastModified ?? this.lastModified,
      metadata: metadata ?? this.metadata,
    );
  }
}
