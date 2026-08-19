import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/favorites/favorites_scope.dart';
import '../../core/location/location_scope.dart';
import '../../data/models/stop.dart';
import '../../data/models/vehicle_filter.dart';
import '../../data/repositories/transit_repository.dart';
import '../home/edit_favourites_screen.dart';
import '../widgets/expandable_preview.dart';
import '../widgets/section_header.dart';
import '../widgets/status_banner.dart';
import 'stop_card.dart';

class FavouriteStopsSection extends StatelessWidget {
  const FavouriteStopsSection({super.key, this.onStopTap});

  final ValueChanged<Stop>? onStopTap;

  static const _repo = TransitRepository();
  static const _distance = Distance();

  @override
  Widget build(BuildContext context) {
    final location = LocationScope.maybeOf(context);
    final favorites = FavoritesScope.maybeOf(context);
    final from = location?.position;
    final favourite = _repo.favouriteStopsMatching(
      favorites?.stopIds ?? const [],
      VehicleFilter.all,
      from: from,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Favourite stops',
          trailing: IconButton(
            tooltip: 'Edit favourites',
            onPressed: () => EditFavouritesScreen.open(
              context,
              initialTab: FavouritesTab.stops,
            ),
            icon: const Icon(Icons.edit_rounded),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: favourite.isEmpty
              ? const StatusBanner(
                  icon: Icons.star_outline_rounded,
                  title: 'No favourite stops yet',
                  body: 'Tap edit to pin the stops you use often.',
                )
              : ExpandablePreview(
                  itemCount: favourite.length,
                  itemBuilder: (context, index) {
                    final stop = favourite[index];
                    final meters = from == null
                        ? null
                        : _distance.as(LengthUnit.Meter, from, stop.location);
                    return StopCard(
                      stop: stop,
                      meters: meters,
                      onTap: onStopTap == null ? null : () => onStopTap!(stop),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
