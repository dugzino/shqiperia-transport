import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/vehicle_filter.dart';

class VehicleTabBar extends StatelessWidget {
  const VehicleTabBar({super.key, required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.primary,
      indicatorWeight: 3,
      dividerColor: AppColors.border,
      tabs: [
        for (final filter in VehicleFilter.values) Tab(text: filter.label),
      ],
    );
  }
}
