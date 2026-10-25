import 'package:flutter/material.dart';

import '../theme/one_dark_pro.dart';
import '../theme/ui_tokens.dart';

/// Icono decorativo para estados vacíos: mismo patrón que el tile del
/// encabezado de vista (tinte azul translúcido, sin gris plano).
class EmptyIconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;

  const EmptyIconTile({
    super.key,
    required this.icon,
    this.size = UiTokens.sizeTileEmpty,
    this.iconSize = UiTokens.iconTileEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: OneDarkPro.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(UiTokens.radiusCard),
      ),
      child: Icon(icon, color: OneDarkPro.blueText, size: iconSize),
    );
  }
}
