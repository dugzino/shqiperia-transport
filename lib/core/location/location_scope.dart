import 'package:flutter/widgets.dart';

import 'location_controller.dart';

class LocationScope extends InheritedNotifier<LocationController> {
  const LocationScope({
    super.key,
    required LocationController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocationController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocationScope>();
    assert(scope != null, 'LocationScope not found in the widget tree');
    return scope!.notifier!;
  }

  static LocationController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<LocationScope>()
        ?.notifier;
  }
}
