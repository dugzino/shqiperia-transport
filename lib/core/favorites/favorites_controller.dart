import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/saved_address.dart';

/// Persists starred transit lines, stops, and saved addresses.
class FavoritesController extends ChangeNotifier {
  FavoritesController();

  static const _linePrefsKey = 'favourite_line_ids';
  static const _stopPrefsKey = 'favourite_stop_ids';
  static const _addressPrefsKey = 'saved_addresses';

  final LinkedHashSet<String> _lineIds = LinkedHashSet();
  final LinkedHashSet<String> _stopIds = LinkedHashSet();
  final List<SavedAddress> _addresses = [];
  bool _loaded = false;

  UnmodifiableListView<String> get lineIds => UnmodifiableListView(_lineIds);
  UnmodifiableListView<String> get stopIds => UnmodifiableListView(_stopIds);
  UnmodifiableListView<SavedAddress> get addresses =>
      UnmodifiableListView(_addresses);
  bool get isLoaded => _loaded;

  bool contains(String lineId) => _lineIds.contains(lineId);
  bool containsStop(String stopId) => _stopIds.contains(stopId);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lineIds
        ..clear()
        ..addAll(prefs.getStringList(_linePrefsKey) ?? const <String>[]);
      _stopIds
        ..clear()
        ..addAll(prefs.getStringList(_stopPrefsKey) ?? const <String>[]);
      _addresses
        ..clear()
        ..addAll(
          (prefs.getStringList(_addressPrefsKey) ?? const <String>[])
              .map((raw) {
            try {
              return SavedAddress.fromJson(
                jsonDecode(raw) as Map<String, dynamic>,
              );
            } catch (_) {
              return null;
            }
          }).whereType<SavedAddress>(),
        );
    } catch (_) {
      // Tests and platforms without the plugin keep an in-memory set.
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> toggle(String lineId) async {
    if (!_lineIds.remove(lineId)) {
      _lineIds.add(lineId);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> addLine(String lineId) async {
    if (!_lineIds.add(lineId)) return;
    notifyListeners();
    await _persist();
  }

  Future<void> removeLine(String lineId) async {
    if (!_lineIds.remove(lineId)) return;
    notifyListeners();
    await _persist();
  }

  Future<void> addStop(String stopId) async {
    if (!_stopIds.add(stopId)) return;
    notifyListeners();
    await _persist();
  }

  Future<void> toggleStop(String stopId) async {
    if (!_stopIds.remove(stopId)) {
      _stopIds.add(stopId);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> removeStop(String stopId) async {
    if (!_stopIds.remove(stopId)) return;
    notifyListeners();
    await _persist();
  }

  Future<void> addAddress(SavedAddress address) async {
    _addresses.removeWhere((item) => item.id == address.id);
    _addresses.add(address);
    notifyListeners();
    await _persist();
  }

  Future<void> removeAddress(String id) async {
    final before = _addresses.length;
    _addresses.removeWhere((item) => item.id == id);
    if (_addresses.length == before) return;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_linePrefsKey, _lineIds.toList());
      await prefs.setStringList(_stopPrefsKey, _stopIds.toList());
      await prefs.setStringList(
        _addressPrefsKey,
        [for (final address in _addresses) jsonEncode(address.toJson())],
      );
    } catch (_) {}
  }

  @visibleForTesting
  void debugSet(Iterable<String> ids) {
    _lineIds
      ..clear()
      ..addAll(ids);
    _loaded = true;
    notifyListeners();
  }

  @visibleForTesting
  void debugSetStops(Iterable<String> ids) {
    _stopIds
      ..clear()
      ..addAll(ids);
    _loaded = true;
    notifyListeners();
  }

  @visibleForTesting
  void debugSetAddresses(Iterable<SavedAddress> addresses) {
    _addresses
      ..clear()
      ..addAll(addresses);
    _loaded = true;
    notifyListeners();
  }
}
