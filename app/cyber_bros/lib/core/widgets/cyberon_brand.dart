import 'package:flutter/material.dart';

import '../theme/palette.dart';

class RutealoBrand extends StatelessWidget {
  const RutealoBrand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 54.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            boxShadow: [
              BoxShadow(
                color: Palette.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            child: Image.asset(
              'assets/images/rutealo_logo.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: Palette.primary,
                alignment: Alignment.center,
                child: Icon(
                  Icons.alt_route_rounded,
                  color: Colors.white,
                  size: compact ? 22 : 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ruté',
                  style: TextStyle(
                    color: Palette.ink,
                    fontSize: compact ? 22 : 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                Text(
                  'alo',
                  style: TextStyle(
                    color: Palette.primary,
                    fontSize: compact ? 22 : 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
            if (!compact)
              const Text(
                'Llega con lo que tienes.',
                style: TextStyle(
                  color: Palette.inkMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Alias retrocompatible para imports existentes
typedef CyberonBrand = RutealoBrand;
