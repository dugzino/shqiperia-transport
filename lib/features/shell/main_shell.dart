import 'package:flutter/material.dart';

import '../../core/location/location_controller.dart';
import '../../core/location/location_scope.dart';
import '../../core/theme/app_colors.dart';
import '../lines/lines_screen.dart';
import '../map/map_screen.dart';
import '../settings/settings_screen.dart';
import '../stops/stops_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.location});

  final LocationController? location;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const _ticketsIndex = 3;

  /// Transit, Lines, Stops, Tickets, Settings — Lines is the landing tab.
  int _index = 1;
  late final LocationController _location;
  late final bool _ownsLocation;

  @override
  void initState() {
    super.initState();
    _ownsLocation = widget.location == null;
    _location = widget.location ?? LocationController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _location.requestAccess();
    });
  }

  @override
  void dispose() {
    if (_ownsLocation) _location.dispose();
    super.dispose();
  }

  void _onDestinationSelected(int value) {
    if (value == _ticketsIndex) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Tickets are not available yet.')),
        );
      return;
    }
    setState(() => _index = value);
  }

  @override
  Widget build(BuildContext context) {
    final pageIndex = _index > _ticketsIndex ? _index - 1 : _index;

    return LocationScope(
      controller: _location,
      child: Scaffold(
        body: IndexedStack(
          index: pageIndex,
          children: const [
            MapScreen(),
            LinesScreen(),
            StopsScreen(),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.directions_transit_outlined),
              selectedIcon: Icon(Icons.directions_transit_rounded),
              label: 'Transit',
            ),
            const NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route_rounded),
              label: 'Lines',
            ),
            const NavigationDestination(
              icon: Icon(Icons.pin_drop_outlined),
              selectedIcon: Icon(Icons.pin_drop_rounded),
              label: 'Stops',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.confirmation_number_outlined,
                color: AppColors.textSecondary.withValues(alpha: 0.38),
              ),
              selectedIcon: Icon(
                Icons.confirmation_number_outlined,
                color: AppColors.textSecondary.withValues(alpha: 0.38),
              ),
              label: 'Tickets',
            ),
            const NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
          onDestinationSelected: _onDestinationSelected,
        ),
      ),
    );
  }
}
