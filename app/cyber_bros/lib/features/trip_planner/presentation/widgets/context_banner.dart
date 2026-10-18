import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/palette.dart';
import '../../data/weather_service.dart';
import '../../domain/context_advisor.dart';
import '../../domain/routing_engine.dart';

/// Muestra el clima real del punto de partida (Open-Meteo) y, según la lluvia
/// y la hora de Lima, sugiere reducir la caminata. La sugerencia solo se aplica
/// si la persona la acepta.
class ContextBanner extends StatefulWidget {
  const ContextBanner({
    super.key,
    required this.point,
    required this.limits,
    required this.onApply,
  });

  final LatLng point;

  /// Límites actuales de los controles, para calcular la sugerencia.
  final PlanLimits limits;

  final ValueChanged<ContextSuggestion> onApply;

  @override
  State<ContextBanner> createState() => _ContextBannerState();
}

class _ContextBannerState extends State<ContextBanner> {
  late final Future<WeatherContext?> _weather = WeatherService.shared
      .currentFor(widget.point);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WeatherContext?>(
      future: _weather,
      builder: (context, snapshot) {
        final weather = snapshot.data;
        final suggestions = ContextAdvisor.suggest(
          limits: widget.limits,
          nowUtc: DateTime.now().toUtc(),
          weather: weather,
        );
        if (weather == null && suggestions.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (weather != null) _WeatherLine(weather: weather),
              for (final suggestion in suggestions)
                _SuggestionCard(
                  suggestion: suggestion,
                  onApply: () => widget.onApply(suggestion),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WeatherLine extends StatelessWidget {
  const _WeatherLine({required this.weather});

  final WeatherContext weather;

  @override
  Widget build(BuildContext context) {
    final chance = weather.rainChancePercent;
    final text = [
      if (weather.description != null) weather.description!,
      if (chance != null) '$chance% de lluvia en las próximas horas',
    ].join(' · ');
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(
            weather.isRaining
                ? Icons.water_drop_outlined
                : Icons.wb_cloudy_outlined,
            size: 16,
            color: Palette.inkMuted,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Clima en tu punto de partida: $text',
              style: const TextStyle(color: Palette.inkMuted, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.onApply});

  final ContextSuggestion suggestion;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final rain = suggestion.kind == ContextKind.rain;
    final color = rain ? Palette.accent : Palette.inferred;
    final background = rain ? Palette.primaryLight : Palette.inferredBg;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                rain ? Icons.umbrella_rounded : Icons.nights_stay_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                suggestion.title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            suggestion.message,
            style: const TextStyle(color: Palette.ink, height: 1.3, fontSize: 13.5),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onApply,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(42),
              foregroundColor: color,
              side: BorderSide(color: color.withValues(alpha: 0.5)),
              backgroundColor: Colors.white,
            ),
            child: Text('Aplicar ${suggestion.limits.maxContinuousWalkMetres} m'),
          ),
        ],
      ),
    );
  }
}
