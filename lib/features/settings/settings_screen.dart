import 'package:flutter/material.dart';

import '../../core/location/location_scope.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final location = LocationScope.maybeOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.my_location_rounded),
                  title: const Text('Location'),
                  subtitle: const Text('Used for nearby stops and Transit'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => location?.openSettings(),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('About'),
                  subtitle: Text('Soar Albania · buses across Kosova and Albania'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tickets and more settings will land here later.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.35),
          ),
        ],
      ),
    );
  }
}
