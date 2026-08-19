import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Attribution-required notices only (map data, fonts). Library packages
/// are omitted unless a license requires a visible notice.
class ThirdPartyLicensesScreen extends StatelessWidget {
  const ThirdPartyLicensesScreen({super.key});

  static const _notices = [
    _LicenseNotice(
      title: 'OpenStreetMap',
      license: 'Open Database License (ODbL)',
      body:
          'Map tiles and geographic data © OpenStreetMap contributors. '
          'This data is available under the Open Database License. '
          'Stop locations in the app are derived from OpenStreetMap.\n\n'
          'https://www.openstreetmap.org/copyright',
    ),
    _LicenseNotice(
      title: 'Plus Jakarta Sans',
      license: 'SIL Open Font License 1.1',
      body:
          'The app typeface is Plus Jakarta Sans, copyright Tokotype, '
          'used under the SIL Open Font License.\n\n'
          'https://openfontlicense.org',
    ),
  ];

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ThirdPartyLicensesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Third-party licenses')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const Text(
            'Notices for map data and other works that require attribution.',
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          for (final notice in _notices) ...[
            _LicenseCard(notice: notice),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _LicenseNotice {
  const _LicenseNotice({
    required this.title,
    required this.license,
    required this.body,
  });

  final String title;
  final String license;
  final String body;
}

class _LicenseCard extends StatelessWidget {
  const _LicenseCard({required this.notice});

  final _LicenseNotice notice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notice.title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notice.license,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              notice.body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
