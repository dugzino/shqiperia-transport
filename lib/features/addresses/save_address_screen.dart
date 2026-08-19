import 'package:flutter/material.dart';

import '../../core/favorites/favorites_scope.dart';
import '../../core/location/location_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/saved_address.dart';
import '../../data/models/stop.dart';
import '../../data/repositories/transit_repository.dart';
import '../widgets/stop_mode_avatar.dart';

class SaveAddressScreen extends StatefulWidget {
  const SaveAddressScreen({super.key, this.existing});

  final SavedAddress? existing;

  static Future<void> open(BuildContext context, {SavedAddress? existing}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SaveAddressScreen(existing: existing),
      ),
    );
  }

  @override
  State<SaveAddressScreen> createState() => _SaveAddressScreenState();
}

class _SaveAddressScreenState extends State<SaveAddressScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _detailsController;
  late final String _id;
  late final bool _isPreset;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _isPreset = existing?.isPreset ?? false;
    _id = existing?.id ?? SavedAddress.newCustomId();
    _nameController = TextEditingController(
      text: existing?.name ?? '',
    );
    _detailsController = TextEditingController(
      text: existing?.details ?? '',
    );
    _lat = existing?.lat;
    _lng = existing?.lng;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.existing?.id == SavedAddress.homeId) return 'Home';
    if (widget.existing?.id == SavedAddress.workId) return 'Work';
    if (widget.existing != null) return 'Edit place';
    return 'New place';
  }

  Future<void> _useCurrentLocation() async {
    final location = LocationScope.maybeOf(context);
    if (location == null) {
      _toast('Location is not available.');
      return;
    }
    if (!location.hasFix) {
      await location.requestAccess();
    }
    if (!mounted) return;
    final pos = location.position;
    if (pos == null) {
      _toast('Could not get your current location.');
      return;
    }
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
    });
  }

  Future<void> _pickStop() async {
    final stop = await _PickStopScreen.open(context);
    if (stop == null || !mounted) return;
    setState(() {
      _lat = stop.location.latitude;
      _lng = stop.location.longitude;
      if (_detailsController.text.trim().isEmpty) {
        _detailsController.text = stop.name;
      }
    });
  }

  void _clearLocation() {
    setState(() {
      _lat = null;
      _lng = null;
    });
  }

  void _save() {
    final favorites = FavoritesScope.maybeOf(context);
    if (favorites == null) return;
    final navigator = Navigator.of(context);

    final name = _isPreset
        ? (widget.existing?.name ?? 'Place')
        : _nameController.text.trim();
    final details = _detailsController.text.trim();

    if (!_isPreset && name.isEmpty) {
      _toast('Give this place a name.');
      return;
    }
    if (details.isEmpty && _lat == null) {
      _toast('Add an address or a location.');
      return;
    }

    favorites.addAddress(
      SavedAddress(
        id: _id,
        name: name,
        details: details.isEmpty ? null : details,
        lat: _lat,
        lng: _lng,
      ),
    );
    navigator.pop();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _lat != null && _lng != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          TextButton(
            key: const Key('address-save'),
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (!_isPreset) ...[
            TextField(
              key: const Key('address-name-field'),
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Gym, Parents',
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            key: const Key('address-details-field'),
            controller: _detailsController,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Address',
              hintText: 'Street, neighbourhood, or landmark',
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Map location',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasLocation
                        ? 'Location saved. Transit can jump here on the map.'
                        : 'Optional. Use your GPS or a nearby stop.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: _useCurrentLocation,
                        child: const Text('Use current location'),
                      ),
                      OutlinedButton(
                        onPressed: _pickStop,
                        child: const Text('Choose a stop'),
                      ),
                      if (hasLocation)
                        TextButton(
                          onPressed: _clearLocation,
                          child: const Text('Clear location'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PickStopScreen extends StatefulWidget {
  const _PickStopScreen();

  static Future<Stop?> open(BuildContext context) {
    return Navigator.of(context).push<Stop>(
      MaterialPageRoute(builder: (_) => const _PickStopScreen()),
    );
  }

  @override
  State<_PickStopScreen> createState() => _PickStopScreenState();
}

class _PickStopScreenState extends State<_PickStopScreen> {
  static const _repo = TransitRepository();
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stops = _repo.searchStops(_query);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a stop')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search stops',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: stops.isEmpty
                ? const Center(
                    child: Text(
                      'No stops match that search.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: stops.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final stop = stops[index];
                      return Card(
                        child: ListTile(
                          leading: StopModeAvatar.forStop(stop),
                          title: Text(
                            stop.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text('${stop.lineIds.length} line(s)'),
                          onTap: () => Navigator.of(context).pop(stop),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
