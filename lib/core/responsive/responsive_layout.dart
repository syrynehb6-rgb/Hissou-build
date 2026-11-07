import 'package:flutter/material.dart';

class ResponsiveLayout {
  static const double compactBreakpoint = 640;
  static const double mediumBreakpoint = 1024;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactBreakpoint;

  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= compactBreakpoint && width < mediumBreakpoint;
  }

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mediumBreakpoint;

  static Widget constrainedContainer({
    required Widget child,
    double maxWidth = 800,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
