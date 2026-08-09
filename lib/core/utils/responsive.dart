import 'package:flutter/material.dart';

/// Simple breakpoints and padding helpers for responsive layout.
class Responsive {
  Responsive._();

  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 900;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return 48;
    if (width >= tabletBreakpoint) return 28;
    return 16;
  }

  static int gridColumns(
    BuildContext context, {
    int phone = 2,
    int tablet = 3,
    int desktop = 4,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return desktop;
    if (width >= tabletBreakpoint) return tablet;
    return phone;
  }

  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return 960;
    if (width >= tabletBreakpoint) return 720;
    return width;
  }
}
