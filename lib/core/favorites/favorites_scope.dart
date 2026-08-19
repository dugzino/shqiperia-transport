import 'package:flutter/widgets.dart';

import 'favorites_controller.dart';

class FavoritesScope extends InheritedNotifier<FavoritesController> {
  const FavoritesScope({
    super.key,
    required FavoritesController controller,
    required super.child,
  }) : super(notifier: controller);

  static FavoritesController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FavoritesScope>();
    assert(scope != null, 'FavoritesScope not found in the widget tree');
    return scope!.notifier!;
  }

  static FavoritesController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FavoritesScope>()
        ?.notifier;
  }
}
