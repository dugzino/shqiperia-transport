import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/favorites/favorites_scope.dart';
import '../../core/location/location_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/saved_address.dart';
import '../../data/models/stop.dart';
import '../../data/models/trip_plan.dart';
import '../../data/repositories/transit_repository.dart';
import '../../data/schedule.dart';
import '../home/edit_favourites_screen.dart';
import '../stops/favourite_stops_section.dart';
import '../stops/nearby_stops_section.dart';
import '../widgets/line_badge.dart';
import '../widgets/stop_mode_avatar.dart';

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
  bool _mapReady = false;
  LatLng? _centeredOn;
  TripPlan? _trip;
  double? _sheetExtent;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _moveTo(
    LatLng point, {
    double zoom = 16,
    double bottomCoveredFraction = 0,
  }) {
    if (!_mapReady) return;
    final offsetY = bottomCoveredFraction <= 0
        ? 0.0
        : -MediaQuery.sizeOf(context).height * bottomCoveredFraction / 2;
    _mapController.move(point, zoom, offset: Offset(0, offsetY));
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
    _moveTo(stop.location, bottomCoveredFraction: 0.5);
  }

  LatLng? _pointFor(SavedAddress address) {
    if (address.hasCoordinates) return LatLng(address.lat!, address.lng!);
    final query = address.details?.trim() ?? '';
    if (query.isEmpty) return null;
    final matches = _repo.searchStops(query);
    return matches.isEmpty ? null : matches.first.location;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _fitTrip(TripPlan trip) {
    if (!_mapReady) return;
    final points = trip.path;
    if (points.length < 2) {
      _moveTo(trip.destination);
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.fromLTRB(40, 180, 40, 160),
      ),
    );
  }

  Future<void> _routeToAddress(SavedAddress address) async {
    final destination = _pointFor(address);
    if (destination == null) {
      _toast('This place has no map location yet.');
      return;
    }

    final location = LocationScope.maybeOf(context);
    if (location != null && !location.hasFix) {
      await location.requestAccess();
    }
    if (!mounted) return;
    final origin = location?.position;
    if (origin == null) {
      _toast('Turn on location to plan a route.');
      return;
    }

    final trip = _repo.planTrip(
      from: origin,
      to: destination,
      destinationLabel: address.name,
    );
    _searchFocus.unfocus();
    _searchController.text = address.name;
    setState(() {
      _query = '';
      _trip = trip;
    });
    _fitTrip(trip);
  }

  void _clearTrip() {
    _searchController.clear();
    setState(() {
      _query = '';
      _trip = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybeCenterOnUser();

    final location = LocationScope.maybeOf(context);
    final userPosition = location?.position;
    final favorites = FavoritesScope.maybeOf(context);
    final addresses = (favorites?.displayAddresses ?? SavedAddress.emptyPresets)
        .where((address) => address.isSet)
        .toList();
    final results = _query.trim().isEmpty
        ? const <Stop>[]
        : _repo.searchStops(_query).take(8).toList();
    final trip = _trip;

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
      if (trip != null)
        Marker(
          point: trip.destination,
          width: 36,
          height: 36,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 8)],
            ),
            child: Icon(Icons.place_rounded, color: Colors.white, size: 20),
          ),
        ),
    ];

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final headerHeight = addresses.isEmpty ? 132.0 : 108.0;
          final minExtent = constraints.maxHeight <= 0
              ? 0.2
              : (headerHeight / constraints.maxHeight).clamp(0.14, 0.34);
          final extent = _sheetExtent ?? minExtent;
          final sheetHeight = constraints.maxHeight * extent;
          return Stack(
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.dugzino.shqiperia_transport',
                  ),
                  if (trip != null)
                    PolylineLayer(
                      polylines: [
                        for (final leg in trip.legs)
                          Polyline(
                            points: leg.points,
                            color: leg.line?.color ?? AppColors.secondary,
                            strokeWidth: leg.isTransit ? 6 : 4,
                          ),
                      ],
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
                        onChanged: (value) => setState(() {
                          _query = value;
                          if (_trip != null) _trip = null;
                        }),
                        onClear: () {
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _trip = null;
                          });
                        },
                      ),
                      if (trip != null) ...[
                        const SizedBox(height: 8),
                        _TripCard(trip: trip, onClose: _clearTrip),
                      ],
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
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final stop = results[index];
                              return ListTile(
                                leading: StopModeAvatar.forStop(stop),
                                title: Text(
                                  stop.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  '${stop.lineIds.length} line(s)',
                                ),
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
              _TransitSheet(
                addresses: addresses,
                minSize: minExtent,
                onExtent: (extent) {
                  if (_sheetExtent != null &&
                      (extent - _sheetExtent!).abs() < 0.01) {
                    return;
                  }
                  setState(() => _sheetExtent = extent);
                },
                onAddressTap: _routeToAddress,
                onAddAddress: () => EditFavouritesScreen.open(
                  context,
                  initialTab: FavouritesTab.places,
                ),
                onStopTap: _selectStop,
              ),
              if (extent < 0.9)
                Positioned(
                  right: 50,
                  bottom: sheetHeight + 50,
                  child: FloatingActionButton.small(
                    onPressed: _goToUser,
                    tooltip: 'My location',
                    child: const Icon(Icons.my_location_rounded),
                  ),
                ),
            ],
          );
        },
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

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onClose});

  final TripPlan trip;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('trip-card'),
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'To ${trip.destinationLabel}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Clear route',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 32, bottom: 8),
              child: Text(
                'Your location',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            for (final leg in trip.legs)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 8, 8),
                child: Row(
                  children: [
                    if (leg.line != null)
                      LineBadge(line: leg.line!, compact: true)
                    else
                      const Icon(
                        Icons.directions_walk_rounded,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        [
                          leg.label,
                          if (leg.meters != null)
                            TransitSchedule.distanceLabel(leg.meters!),
                        ].join(' · '),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TransitSheet extends StatefulWidget {
  const _TransitSheet({
    required this.addresses,
    required this.minSize,
    required this.onExtent,
    required this.onAddressTap,
    required this.onAddAddress,
    required this.onStopTap,
  });

  final List<SavedAddress> addresses;
  final double minSize;
  final ValueChanged<double> onExtent;
  final ValueChanged<SavedAddress> onAddressTap;
  final VoidCallback onAddAddress;
  final ValueChanged<Stop> onStopTap;

  @override
  State<_TransitSheet> createState() => _TransitSheetState();
}

class _TransitSheetState extends State<_TransitSheet> {
  final _controller = DraggableScrollableController();

  double get _headerHeight => widget.addresses.isEmpty ? 132 : 108;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.isAttached) return;
      widget.onExtent(_controller.size);
    });
  }

  Future<void> _animateTo(double size) async {
    if (!_controller.isAttached) return;
    await _controller.animateTo(
      size,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _toggle() async {
    final min = widget.minSize;
    final target = !_controller.isAttached || _controller.size <= min + 0.08
        ? 1.0
        : min;
    await _animateTo(target);
  }

  Future<void> _collapseAndSelect(Stop stop) async {
    widget.onStopTap(stop);
    await _animateTo(0.5);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final min = widget.minSize;
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        widget.onExtent(notification.extent);
        return false;
      },
      child: DraggableScrollableSheet(
        controller: _controller,
        initialChildSize: min,
        minChildSize: min,
        maxChildSize: 1,
        snap: true,
        snapSizes: const [0.5],
        builder: (context, scrollController) {
          return Material(
            color: AppColors.surface,
            elevation: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            clipBehavior: Clip.antiAlias,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SheetHeaderDelegate(
                    height: _headerHeight,
                    child: _SheetHeader(
                      addresses: widget.addresses,
                      onToggle: _toggle,
                      onAddressTap: widget.onAddressTap,
                      onAddAddress: widget.onAddAddress,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FavouriteStopsSection(onStopTap: _collapseAndSelect),
                ),
                SliverToBoxAdapter(
                  child: NearbyStopsSection(onStopTap: _collapseAndSelect),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SheetHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SheetHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.addresses,
    required this.onToggle,
    required this.onAddressTap,
    required this.onAddAddress,
  });

  final List<SavedAddress> addresses;
  final VoidCallback onToggle;
  final ValueChanged<SavedAddress> onAddressTap;
  final VoidCallback onAddAddress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              key: const Key('transit-sheet-handle'),
              behavior: HitTestBehavior.opaque,
              onTap: onToggle,
              child: SizedBox(
                height: 24,
                width: double.infinity,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (addresses.isEmpty)
              Column(
                children: [
                  const Text(
                    'No addresses saved yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('add-place'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    onPressed: onAddAddress,
                    child: const Text('Add a place'),
                  ),
                ],
              )
            else
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 8),
                  itemCount: addresses.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return _SavedAddressChip(
                      address: address,
                      onTap: () => onAddressTap(address),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SavedAddressChip extends StatelessWidget {
  const _SavedAddressChip({required this.address, required this.onTap});

  final SavedAddress address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (address.isPreset) {
      return Tooltip(
        message: address.name,
        child: Material(
          color: Colors.white.withValues(alpha: 0.16),
          shape: const CircleBorder(),
          child: InkWell(
            key: Key('saved-address-${address.id}'),
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(address.icon, color: Colors.white),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        key: Key('saved-address-${address.id}'),
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            address.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
