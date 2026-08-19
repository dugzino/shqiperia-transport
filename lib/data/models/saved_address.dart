import 'package:flutter/material.dart';

class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.name,
    this.details,
    this.lat,
    this.lng,
  });

  static const homeId = 'home';
  static const workId = 'work';

  static const emptyPresets = [
    SavedAddress(id: homeId, name: 'Home'),
    SavedAddress(id: workId, name: 'Work'),
  ];

  final String id;
  final String name;
  final String? details;
  final double? lat;
  final double? lng;

  bool get isPreset => id == homeId || id == workId;

  bool get hasCoordinates => lat != null && lng != null;

  bool get isSet {
    final text = details?.trim() ?? '';
    return text.isNotEmpty || hasCoordinates;
  }

  String get subtitle {
    final text = details?.trim() ?? '';
    if (text.isNotEmpty) return text;
    if (hasCoordinates) return 'Saved location';
    return 'Set address';
  }

  IconData get icon => switch (id) {
        homeId => Icons.home_rounded,
        workId => Icons.work_rounded,
        _ => Icons.place_rounded,
      };

  static String newCustomId() =>
      'place-${DateTime.now().microsecondsSinceEpoch}';

  SavedAddress copyWith({
    String? id,
    String? name,
    String? details,
    double? lat,
    double? lng,
    bool clearDetails = false,
    bool clearLocation = false,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      name: name ?? this.name,
      details: clearDetails ? null : details ?? this.details,
      lat: clearLocation ? null : lat ?? this.lat,
      lng: clearLocation ? null : lng ?? this.lng,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'details': details,
        'lat': lat,
        'lng': lng,
      };

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: json['id'] as String,
      name: json['name'] as String,
      details: json['details'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }
}
