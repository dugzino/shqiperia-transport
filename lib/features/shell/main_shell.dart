import 'package:flutter/material.dart';

import '../../core/location/location_controller.dart';
import '../../core/location/location_scope.dart';
import '../home/home_screen.dart';
import '../lines/lines_screen.dart';
import '../map/map_screen.dart';
import '../search/search_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, this.location});

  final LocationController? location;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
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

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map_rounded),
      label: 'Map',
    ),
    NavigationDestination(
      icon: Icon(Icons.route_outlined),
      selectedIcon: Icon(Icons.route_rounded),
      label: 'Lines',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_rounded),
      selectedIcon: Icon(Icons.search_rounded),
      label: 'Search',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LocationScope(
      controller: _location,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [
            HomeScreen(),
            MapScreen(),
            LinesScreen(),
            SearchScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          destinations: _destinations,
          onDestinationSelected: (value) => setState(() => _index = value),
        ),
      ),
    );
  }
}
