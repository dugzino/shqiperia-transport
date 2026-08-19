import 'package:flutter/material.dart';

class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.name,
    this.details,
    this.lat,
    this.lng,
  });

  final String id;
  final String name;
  final String? details;
  final double? lat;
  final double? lng;

  IconData get icon => switch (id) {
        'home' => Icons.home_rounded,
        'work' => Icons.work_rounded,
        _ => Icons.place_rounded,
      };

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
