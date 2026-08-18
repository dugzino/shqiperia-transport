import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/city.dart';
import '../../data/models/transit_line.dart';
import '../../data/repositories/transit_repository.dart';
import '../lines/line_detail_screen.dart';
import '../widgets/line_badge.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _repo = TransitRepository();
  final _mapController = MapController();

  late City _city;
  TransitLine? _selectedLine;

  @override
  void initState() {
    super.initState();
    _city = _repo.getCities().first;
  }

  List<TransitLine> get _lines => _repo.getLines(cityId: _city.id);

  void _focusCity(City city) {
    setState(() {
      _city = city;
      _selectedLine = null;
    });
    _mapController.move(city.center, 13);
  }

  void _selectLine(TransitLine? line) {
    setState(() => _selectedLine = line);
    if (line != null && line.stops.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(line.stops);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final polylines = <Polyline>[];
    final markers = <Marker>[];

    final activeLines = _selectedLine != null ? [_selectedLine!] : _lines;

    for (final line in activeLines) {
      if (line.stops.length >= 2) {
        polylines.add(
          Polyline(
            points: line.stops,
            color: line.color.withValues(alpha: 0.9),
            strokeWidth: _selectedLine == null ? 4 : 6,
          ),
        );
      }
      for (var i = 0; i < line.stops.length; i++) {
        final isEndpoint = i == 0 || i == line.stops.length - 1;
        markers.add(
          Marker(
            point: line.stops[i],
            width: isEndpoint ? 18 : 12,
            height: isEndpoint ? 18 : 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isEndpoint ? line.color : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: line.color, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    // City center pin when nothing selected
    markers.add(
      Marker(
        point: _city.center,
        width: 40,
        height: 40,
        child: const Icon(
          Icons.location_city_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _city.center,
              initialZoom: 13,
              minZoom: 7,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.dugzino.kosova_transit',
              ),
              PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).cardColor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_rounded, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_city.name} · ${_lines.length} lines',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          PopupMenuButton<String>(
                            tooltip: 'Switch city',
                            onSelected: (id) {
                              final city = _repo.getCity(id);
                              if (city != null) _focusCity(city);
                            },
                            itemBuilder: (context) => _repo
                                .getCities()
                                .map(
                                  (c) => PopupMenuItem(
                                    value: c.id,
                                    child: Text('${c.flag} ${c.name}'),
                                  ),
                                )
                                .toList(),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.unfold_more_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                if (_lines.isNotEmpty)
                  SizedBox(
                    height: 108,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _lines.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final allSelected = _selectedLine == null;
                          return _MapLineChip(
                            label: 'All',
                            selected: allSelected,
                            color: AppColors.primary,
                            onTap: () => _selectLine(null),
                          );
                        }
                        final line = _lines[index - 1];
                        return _MapLineChip(
                          label: line.number,
                          subtitle: line.destination ?? line.name,
                          selected: _selectedLine?.id == line.id,
                          color: line.color,
                          badge: LineBadge(line: line, compact: true),
                          onTap: () => _selectLine(line),
                          onOpen: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    LineDetailScreen(lineId: line.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLineChip extends StatelessWidget {
  const _MapLineChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.badge,
    this.onOpen,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final Color color;
  final Widget? badge;
  final VoidCallback onTap;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: selected ? 4 : 1,
      borderRadius: BorderRadius.circular(16),
      color: selected ? color : Colors.white,
      child: InkWell(
        onTap: onTap,
        onLongPress: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: subtitle == null ? 72 : 140,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badge != null)
                Opacity(
                  opacity: selected ? 1 : 1,
                  child: badge,
                )
              else
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              const Spacer(),
              Text(
                subtitle ?? label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
