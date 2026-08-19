import 'package:flutter/material.dart';

import '../../data/repositories/transit_repository.dart';

class ExpandablePreview extends StatefulWidget {
  const ExpandablePreview({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.previewCount = TransitRepository.nearbyStopLimit,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int previewCount;

  @override
  State<ExpandablePreview> createState() => _ExpandablePreviewState();
}

class _ExpandablePreviewState extends State<ExpandablePreview> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final canExpand = widget.itemCount > widget.previewCount;
    final visibleCount = _expanded || !canExpand
        ? widget.itemCount
        : widget.previewCount;

    return Column(
      children: [
        for (var i = 0; i < visibleCount; i++) ...[
          widget.itemBuilder(context, i),
          if (i != visibleCount - 1) const SizedBox(height: 10),
        ],
        if (canExpand)
          TextButton.icon(
            onPressed: () => setState(() => _expanded = !_expanded),
            icon: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            ),
            label: Text(_expanded ? 'Show less' : 'Show more'),
          ),
      ],
    );
  }
}
