import 'dart:convert';
import 'package:flutter/material.dart';

import '../core/utils/image_utils.dart';
import '../core/utils/text_utils.dart';
import 'public_partido_row.dart';

class TeamLogoAvatar extends StatelessWidget {
  final String? logoUrl;
  final String teamName;
  final String? sigla;
  final Color? teamColor;
  final double size;
  final double borderRadius;
  final bool isCircle;
  final Color? backgroundColor;
  final double? padding;

  const TeamLogoAvatar({
    super.key,
    this.logoUrl,
    required this.teamName,
    this.sigla,
    this.teamColor,
    this.size = 56,
    this.borderRadius = 12,
    this.isCircle = false,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final siglaValida = sigla?.trim() ?? '';
    final fallbackText = siglaValida.isNotEmpty
        ? siglaValida.toUpperCase()
        : TextUtils.getInitials(teamName, sigla: sigla);
    final effectiveColor = teamColor ?? PublicPartidoRow.getClubColor(teamName, sigla);
    final effectiveLogo = ImageUtils.resolveTeamLogo(logoUrl, teamName: teamName, sigla: sigla);

    Widget buildFallback() {
      final textLength = fallbackText.length;
      final scaleFactor = textLength <= 2 ? 0.36 : (textLength == 3 ? 0.30 : 0.24);
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: effectiveColor,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: effectiveColor.withAlpha(50),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          fallbackText,
          style: TextStyle(
            fontSize: size * scaleFactor,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: textLength <= 2 ? 0.5 : 0.0,
          ),
          maxLines: 1,
          overflow: TextOverflow.clip,
        ),
      );
    }

    if (effectiveLogo == null || effectiveLogo.isEmpty) {
      return buildFallback();
    }

    Widget imageWidget;

    if (effectiveLogo.startsWith('assets/')) {
      imageWidget = Image.asset(
        effectiveLogo,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => buildFallback(),
      );
    } else if (effectiveLogo.startsWith('data:image') || effectiveLogo.contains(';base64,')) {
      try {
        final commaIdx = effectiveLogo.indexOf(',');
        final base64String = commaIdx != -1 ? effectiveLogo.substring(commaIdx + 1) : effectiveLogo;
        final bytes = base64Decode(base64String.trim().replaceAll(RegExp(r'\s+'), ''));
        imageWidget = Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => buildFallback(),
        );
      } catch (_) {
        return buildFallback();
      }
    } else {
      final resolvedUrl = ImageUtils.resolveUrl(effectiveLogo);
      if (resolvedUrl.isEmpty) {
        return buildFallback();
      }
      imageWidget = Image.network(
        resolvedUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => buildFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
            ),
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    final effectivePadding = padding ?? (size * 0.08);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.all(effectivePadding),
      child: Center(child: imageWidget),
    );
  }
}
