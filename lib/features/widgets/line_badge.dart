import 'package:flutter/material.dart';

import '../../data/models/transit_line.dart';

class LineBadge extends StatelessWidget {
  const LineBadge({
    super.key,
    required this.line,
    this.compact = false,
  });

  final TransitLine line;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 40.0;
    final fontSize = compact ? 12.0 : 14.0;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: line.color,
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
      ),
      child: Text(
        line.number,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          height: 1,
        ),
      ),
    );
  }
}
