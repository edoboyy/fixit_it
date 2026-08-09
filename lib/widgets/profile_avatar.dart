import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// Circular profile icon used in headers and app bars across all roles.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 22,
    this.onTap,
    this.showRing = true,
  });

  final String name;
  final String? photoUrl;
  final double radius;
  final VoidCallback? onTap;
  final bool showRing;

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppConstants.accentGold.withValues(alpha: 0.25),
      backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              _initial,
              style: TextStyle(
                fontSize: radius * 0.85,
                fontWeight: FontWeight.w700,
                color: AppConstants.primaryGreen,
              ),
            ),
    );

    final ring = showRing
        ? Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppConstants.accentGold,
                  AppConstants.primaryGreen.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: avatar,
          )
        : avatar;

    if (onTap == null) return ring;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: ring,
      ),
    );
  }
}
