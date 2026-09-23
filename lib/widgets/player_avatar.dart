import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/image_utils.dart';
import '../core/utils/text_utils.dart';

class PlayerAvatar extends StatelessWidget {
  final String? photoUrl;
  final String playerName;
  final double radius;

  const PlayerAvatar({
    super.key,
    this.photoUrl,
    required this.playerName,
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final initials = TextUtils.getInitials(playerName);
    final resolvedUrl = ImageUtils.resolveUrl(photoUrl);

    Widget buildFallback() {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primaryLight,
        child: initials.isNotEmpty
            ? Text(
                initials,
                style: TextStyle(
                  fontSize: radius * 0.7,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              )
            : Icon(
                Icons.person,
                size: radius * 1.2,
                color: AppColors.primary,
              ),
      );
    }

    if (resolvedUrl.isEmpty) {
      return buildFallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        resolvedUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => buildFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.primaryLight,
            child: SizedBox(
              width: radius * 0.8,
              height: radius * 0.8,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }
}
