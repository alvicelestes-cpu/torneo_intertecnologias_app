import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/image_utils.dart';
import '../core/utils/text_utils.dart';

class TeamLogoAvatar extends StatelessWidget {
  final String? logoUrl;
  final String teamName;
  final String? sigla;
  final double size;
  final double borderRadius;

  const TeamLogoAvatar({
    super.key,
    this.logoUrl,
    required this.teamName,
    this.sigla,
    this.size = 56,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final initials = TextUtils.getInitials(teamName, sigla: sigla);
    final resolvedUrl = ImageUtils.resolveUrl(logoUrl);

    Widget buildInitials() {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (resolvedUrl.isEmpty) {
      return buildInitials();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        resolvedUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => buildInitials(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }
}
