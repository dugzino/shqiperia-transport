import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/location/location_scope.dart';
import '../../core/theme/app_colors.dart';
import '../home/edit_favourites_screen.dart';
import '../widgets/section_header.dart';
import 'third_party_licenses_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.appVersion});

  /// When set, skips reading the installed package version (used in tests).
  final String? appVersion;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final injected = widget.appVersion;
    if (injected != null) {
      setState(() => _version = injected);
      return;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = info.version);
    } catch (_) {
      // Tests and platforms without the plugin keep an empty version.
    }
  }

  void _notAvailableYet(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature is not available yet.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final location = LocationScope.maybeOf(context);
    final copyright = _version.isEmpty
        ? 'Copyright Soar Albania @ 2026'
        : 'Copyright Soar Albania @ 2026 v$_version';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const SectionHeader(title: 'My account settings'),
          _SettingsGroupCard(
            items: [
              _SettingsRow(
                icon: Icons.person_outline_rounded,
                title: 'Edit my profile',
                onTap: () => _notAvailableYet('Profile editing'),
              ),
            ],
          ),
          const SectionHeader(title: 'App Settings'),
          _SettingsGroupCard(
            items: [
              _SettingsRow(
                icon: Icons.tune_rounded,
                title: 'Preferences',
                onTap: () => _notAvailableYet('Preferences'),
              ),
              _SettingsRow(
                icon: Icons.star_outline_rounded,
                title: 'Manage my favourites',
                onTap: () => EditFavouritesScreen.open(context),
              ),
              _SettingsRow(
                icon: Icons.shield_outlined,
                title: 'Permissions',
                onTap: () => location?.openSettings(),
              ),
            ],
          ),
          const SectionHeader(title: 'Support'),
          _SettingsGroupCard(
            items: [
              _SettingsRow(
                icon: Icons.auto_awesome_outlined,
                title: 'Features overview',
                onTap: () => _notAvailableYet('Features overview'),
              ),
              _SettingsRow(
                icon: Icons.menu_book_outlined,
                title: 'How to use the app',
                onTap: () => _notAvailableYet('How to use the app'),
              ),
              _SettingsRow(
                icon: Icons.accessible_rounded,
                title: 'Accessibility for PRM',
                onTap: () => _notAvailableYet('Accessibility for PRM'),
              ),
              _SettingsRow(
                icon: Icons.flag_outlined,
                title: 'Report a problem',
                onTap: () => _notAvailableYet('Report a problem'),
              ),
              _SettingsRow(
                icon: Icons.thumb_up_outlined,
                title: 'Rate the app',
                onTap: () => _notAvailableYet('Rate the app'),
              ),
            ],
          ),
          const SectionHeader(title: 'About'),
          _SettingsGroupCard(
            items: [
              _SettingsRow(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy policy',
                onTap: () => _notAvailableYet('Privacy policy'),
              ),
              _SettingsRow(
                icon: Icons.description_outlined,
                title: 'Terms of use',
                onTap: () => _notAvailableYet('Terms of use'),
              ),
              _SettingsRow(
                icon: Icons.accessibility_new_rounded,
                title: 'Accessibility compliance statement',
                onTap: () =>
                    _notAvailableYet('Accessibility compliance statement'),
              ),
              _SettingsRow(
                icon: Icons.code_rounded,
                title: 'Third-party licenses',
                onTap: () => ThirdPartyLicensesScreen.open(context),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => _notAvailableYet('Sign-in'),
                child: const Text('Log in'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              copyright,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroupCard extends StatelessWidget {
  const _SettingsGroupCard({required this.items});

  final List<_SettingsRow> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              items[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
