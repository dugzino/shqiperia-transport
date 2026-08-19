import 'package:flutter/material.dart';

import 'favourite_stops_section.dart';
import 'nearby_stops_section.dart';

class StopsScreen extends StatelessWidget {
  const StopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stops')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: const [
          FavouriteStopsSection(),
          NearbyStopsSection(),
        ],
      ),
    );
  }
}
