import 'package:flutter/material.dart';

import '../../core/location/location_controller.dart';
import '../../core/location/location_scope.dart';
import '../../data/models/nearby_stop.dart';
import '../../data/models/stop.dart';
import '../../data/models/vehicle_filter.dart';
import '../../data/repositories/transit_repository.dart';
import '../widgets/expandable_preview.dart';
import '../widgets/section_header.dart';
import '../widgets/status_banner.dart';
import '../widgets/vehicle_tab_bar.dart';
import 'stop_card.dart';

class NearbyStopsSection extends StatefulWidget {
  const NearbyStopsSection({super.key, this.onStopTap});

  final ValueChanged<Stop>? onStopTap;

  @override
  State<NearbyStopsSection> createState() => _NearbyStopsSectionState();
}

class _NearbyStopsSectionState extends State<NearbyStopsSection>
    with SingleTickerProviderStateMixin {
  static const _repo = TransitRepository();
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: VehicleFilter.values.length, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  VehicleFilter get _filter => VehicleFilter.values[_tabs.index];

  List<NearbyStop> _nearby(LocationController? location) {
    final from = location?.position;
    if (from == null) return const [];
    return _repo.nearbyStopsMatching(from, _filter);
  }

  @override
  Widget build(BuildContext context) {
    final location = LocationScope.maybeOf(context);
    final searching = location?.status == LocationStatus.requesting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Nearby stops (<1km)',
          trailing: IconButton(
            tooltip: 'Refresh nearby stops',
            onPressed: searching || location == null
                ? null
                : location.requestAccess,
            icon: searching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ),
        VehicleTabBar(controller: _tabs),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: _body(location),
        ),
      ],
    );
  }

  Widget _body(LocationController? loc) {
    final nearby = _nearby(loc);
    if (loc == null) {
      return const StatusBanner(
        icon: Icons.near_me_rounded,
        title: 'See nearby stops',
        body: 'Allow location to see stops within 1 km.',
      );
    }

    if (loc.status == LocationStatus.granted && nearby.isNotEmpty) {
      return ExpandablePreview(
        itemCount: nearby.length,
        itemBuilder: (context, index) {
          final item = nearby[index];
          return StopCard(
            stop: item.stop,
            meters: item.meters,
            onTap: widget.onStopTap == null
                ? null
                : () => widget.onStopTap!(item.stop),
          );
        },
      );
    }

    if (loc.status == LocationStatus.granted && nearby.isEmpty) {
      return const StatusBanner(
        icon: Icons.near_me_disabled_rounded,
        title: 'No stops nearby',
        body: 'Nothing in this category is within 1 km.',
      );
    }

    if (loc.status == LocationStatus.requesting) {
      return const StatusBanner(
        icon: Icons.my_location_rounded,
        title: 'Finding nearby stops…',
        body: 'Using your location for the closest stops.',
      );
    }

    final deniedForever = loc.status == LocationStatus.deniedForever;
    final disabled = loc.status == LocationStatus.disabled;
    return StatusBanner(
      icon: Icons.near_me_rounded,
      title: disabled ? 'Turn on location' : 'See nearby stops',
      body: disabled
          ? 'Location services are off. Turn them on to see nearby stops.'
          : deniedForever
              ? 'Location is blocked. Enable it in settings to see nearby stops.'
              : 'Allow location to see stops within 1 km.',
      actionLabel: disabled || deniedForever ? 'Open settings' : 'Allow location',
      onAction: () {
        if (disabled || deniedForever) {
          loc.openSettings();
        } else {
          loc.requestAccess();
        }
      },
    );
  }
}
