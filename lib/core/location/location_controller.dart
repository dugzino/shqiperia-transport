import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationStatus {
  unknown,
  requesting,
  granted,
  denied,
  deniedForever,
  disabled,
  unavailable,
}

/// Requests and holds the device location used for nearby stops / schedules.
class LocationController extends ChangeNotifier {
  LocationStatus _status = LocationStatus.unknown;
  LatLng? _position;
  String? _error;

  LocationStatus get status => _status;
  LatLng? get position => _position;
  String? get error => _error;
  bool get hasFix => _position != null;
  bool get canAskAgain =>
      _status == LocationStatus.denied || _status == LocationStatus.unknown;
  bool get needsSettings =>
      _status == LocationStatus.deniedForever ||
      _status == LocationStatus.disabled;

  /// Checks current permission and, if needed, shows the system prompt.
  Future<void> requestAccess() async {
    if (_status == LocationStatus.requesting) return;
    _status = LocationStatus.requesting;
    _error = null;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _status = LocationStatus.disabled;
        _error = 'Location services are turned off.';
        notifyListeners();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _status = LocationStatus.denied;
        notifyListeners();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _status = LocationStatus.deniedForever;
        notifyListeners();
        return;
      }

      final fix = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      _position = LatLng(fix.latitude, fix.longitude);
      _status = LocationStatus.granted;
      notifyListeners();
    } on MissingPluginException {
      _status = LocationStatus.unavailable;
      notifyListeners();
    } on TimeoutException {
      _status = LocationStatus.unavailable;
      _error = 'Could not get a GPS fix in time.';
      notifyListeners();
    } catch (error) {
      _status = LocationStatus.unavailable;
      _error = error.toString();
      notifyListeners();
    }
  }

  Future<void> openSettings() async {
    if (_status == LocationStatus.disabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  @visibleForTesting
  void debugOverride({
    LocationStatus status = LocationStatus.denied,
    LatLng? position,
  }) {
    _status = status;
    _position = position;
    notifyListeners();
  }
}
