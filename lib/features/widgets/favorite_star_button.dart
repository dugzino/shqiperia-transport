import 'package:flutter/material.dart';

import '../../core/favorites/favorites_scope.dart';
import '../../core/theme/app_colors.dart';

class FavoriteStarButton extends StatelessWidget {
  const FavoriteStarButton({
    super.key,
    this.lineId,
    this.stopId,
    this.color,
    this.selectedColor = AppColors.secondary,
  }) : assert(
          (lineId == null) != (stopId == null),
          'Provide either lineId or stopId',
        );

  final String? lineId;
  final String? stopId;
  final Color? color;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesScope.maybeOf(context);
    if (favorites == null) return const SizedBox.shrink();

    final starred = stopId != null
        ? favorites.containsStop(stopId!)
        : favorites.contains(lineId!);
    return IconButton(
      tooltip: starred ? 'Remove from favourites' : 'Add to favourites',
      onPressed: () => stopId != null
          ? favorites.toggleStop(stopId!)
          : favorites.toggle(lineId!),
      icon: Icon(
        starred ? Icons.star_rounded : Icons.star_outline_rounded,
        color: starred
            ? selectedColor
            : color ??
                IconTheme.of(context).color ??
                AppColors.textSecondary,
      ),
    );
  }
}
