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
            color: Palette.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.route_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'cyberon',
              style: TextStyle(
                color: Palette.ink,
                fontSize: compact ? 23 : 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            if (!compact)
              const Text(
                'Llega con lo que tienes.',
                style: TextStyle(color: Palette.inkMuted, fontSize: 13),
              ),
          ],
        ),
      ],
    );
  }
}
