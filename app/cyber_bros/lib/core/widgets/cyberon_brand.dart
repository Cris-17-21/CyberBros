import 'package:flutter/material.dart';

import '../theme/palette.dart';

class CyberonBrand extends StatelessWidget {
  const CyberonBrand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 42 : 52,
          height: compact ? 42 : 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Palette.primary, Color(0xFF0EA5E9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Palette.primary.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.route_rounded,
            color: Colors.white,
            size: compact ? 22 : 28,
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
                  'cyber',
                  style: TextStyle(
                    color: Palette.ink,
                    fontSize: compact ? 22 : 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'on',
                  style: TextStyle(
                    color: Palette.primary,
                    fontSize: compact ? 22 : 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
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
