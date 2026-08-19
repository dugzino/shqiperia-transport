import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/favorites/favorites_scope.dart';
import '../../core/location/location_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/saved_address.dart';
import '../../data/models/stop.dart';
import '../../data/repositories/transit_repository.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _repo = TransitRepository();
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  String _query = '';
  bool _sheetOpen = false;
  bool _mapReady = false;
  LatLng? _centeredOn;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _moveTo(LatLng point, {double zoom = 16}) {
    if (!_mapReady) return;
    _mapController.move(point, zoom);
    _centeredOn = point;
  }

  void _maybeCenterOnUser() {
    final location = LocationScope.maybeOf(context);
    final pos = location?.position;
    if (pos == null || _centeredOn != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _moveTo(pos, zoom: 15);
    });
  }

  Future<void> _goToUser() async {
    final location = LocationScope.maybeOf(context);
    if (location == null) return;
    if (!location.hasFix) {
      await location.requestAccess();
    }
    if (!mounted) return;
    final pos = location.position;
    if (pos != null) _moveTo(pos, zoom: 15);
  }

  void _selectStop(Stop stop) {
    _searchFocus.unfocus();
    _searchController.clear();
    setState(() => _query = '');
    _moveTo(stop.location);
  }

  @override
  Widget build(BuildContext context) {
    _maybeCenterOnUser();

    final location = LocationScope.maybeOf(context);
    final userPosition = location?.position;
    final favorites = FavoritesScope.maybeOf(context);
    final addresses = favorites?.addresses ?? const <SavedAddress>[];
    final favouriteStops = <Stop>[
      for (final id in favorites?.stopIds ?? const <String>[])
        ?_repo.getStop(id),
    ];
    final results = _query.trim().isEmpty
        ? const <Stop>[]
        : _repo.searchStops(_query).take(8).toList();

    final markers = <Marker>[
      if (userPosition != null)
        Marker(
          point: userPosition,
          width: 22,
          height: 22,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        ),
    ];

    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: _sheetOpen ? 220 : 72),
        child: FloatingActionButton.small(
          onPressed: _goToUser,
          tooltip: 'My location',
          child: const Icon(Icons.my_location_rounded),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userPosition ?? const LatLng(42.6629, 21.1655),
              initialZoom: userPosition == null ? 13 : 15,
              minZoom: 7,
              maxZoom: 18,
              onMapReady: () => _mapReady = true,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dugzino.shqiperia_transport',
              ),
              MarkerLayer(markers: markers),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ColoredBox(
              color: AppColors.primary,
              child: SizedBox(height: MediaQuery.paddingOf(context).top),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WhereToBar(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: (value) => setState(() => _query = value),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
                  if (results.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final stop = results[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.hail_rounded,
                              color: AppColors.secondary,
                            ),
                            title: Text(
                              stop.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text('${stop.lineIds.length} line(s)'),
                            onTap: () => _selectStop(stop),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _TransitSheet(
              expanded: _sheetOpen,
              addresses: addresses,
              favouriteStops: favouriteStops,
              onToggle: () => setState(() => _sheetOpen = !_sheetOpen),
              onAddressTap: (address) {
                if (address.lat == null || address.lng == null) return;
                _moveTo(LatLng(address.lat!, address.lng!));
              },
              onStopTap: _selectStop,
            ),
          ),
        ],
      ),
    );
  }
}

class _WhereToBar extends StatelessWidget {
  const _WhereToBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(28),
      color: Colors.white,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Where to?',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  onPressed: onClear,
                  icon: const Icon(Icons.clear_rounded),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _TransitSheet extends StatelessWidget {
  const _TransitSheet({
    required this.expanded,
    required this.addresses,
    required this.favouriteStops,
    required this.onToggle,
    required this.onAddressTap,
    required this.onStopTap,
  });

  final bool expanded;
  final List<SavedAddress> addresses;
  final List<Stop> favouriteStops;
  final VoidCallback onToggle;
  final ValueChanged<SavedAddress> onAddressTap;
  final ValueChanged<Stop> onStopTap;

  @override
  Widget build(BuildContext context) {
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.36;

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            key: const Key('transit-sheet-handle'),
            onTap: onToggle,
            onVerticalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity < -180 && !expanded) onToggle();
              if (velocity > 180 && expanded) onToggle();
            },
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                addresses.isEmpty ? 14 : 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  if (addresses.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    for (final address in addresses)
                      Material(
                        color: Colors.transparent,
                        child: ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.16),
                            child: Icon(address.icon, color: Colors.white),
                          ),
                          title: Text(
                            address.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: address.details == null
                              ? null
                              : Text(
                                  address.details!,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                          onTap: () => onAddressTap(address),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (expanded)
            Material(
              color: const Color(0xFFE8EAED),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxListHeight),
                child: favouriteStops.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(20, 18, 20, 24),
                        child: Text(
                          'No favourite stops yet. Star a stop from Edit favourites.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                        itemCount: favouriteStops.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final stop = favouriteStops[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.hail_rounded,
                                color: AppColors.secondary,
                              ),
                            ),
                            title: Text(
                              stop.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text('${stop.lineIds.length} line(s)'),
                            onTap: () => onStopTap(stop),
                          );
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
