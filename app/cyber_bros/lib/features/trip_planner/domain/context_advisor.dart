/// Sugerencias según el contexto del momento: clima y hora de Lima.
///
/// Caminar 600 m bajo la lluvia o de noche no pesa igual que a mediodía.
/// Este módulo propone **límites de caminata más bajos** en esos casos. Es
/// puro (recibe el clima y la hora), no depende de la red y **nunca cambia
/// los límites por su cuenta**: solo sugiere y la persona decide.
library;

import 'routing_engine.dart';

/// Lo que se sabe del clima en el punto de partida.
final class WeatherContext {
  const WeatherContext({
    required this.precipitationMm,
    this.rainChancePercent,
    this.description,
  });

  /// Lluvia actual en milímetros.
  final double precipitationMm;

  /// Probabilidad de lluvia en las próximas horas (0 a 100), si se conoce.
  final int? rainChancePercent;

  final String? description;

  bool get isRaining => precipitationMm >= 0.2;
  bool get rainLikely => (rainChancePercent ?? 0) >= 60;
}

enum ContextKind { rain, night }

/// Un cambio sugerido, con su motivo y los límites resultantes.
final class ContextSuggestion {
  const ContextSuggestion({
    required this.kind,
    required this.title,
    required this.message,
    required this.limits,
  });

  final ContextKind kind;
  final String title;
  final String message;

  /// Límites que quedarían si la persona acepta.
  final PlanLimits limits;
}

abstract final class ContextAdvisor {
  /// Lima está en UTC-5 todo el año (no usa horario de verano).
  static const limaOffset = Duration(hours: -5);

  /// Cuánto se reduce la caminata en cada caso.
  static const rainFactor = 0.6;
  static const nightFactor = 0.7;

  /// Hora local de Lima para un instante en UTC.
  static DateTime limaTime(DateTime utc) => utc.toUtc().add(limaOffset);

  /// De noche: de 19:30 a 05:00, hora de Lima.
  static bool isNight(DateTime utc) {
    final lima = limaTime(utc);
    final minutes = lima.hour * 60 + lima.minute;
    return minutes >= 19 * 60 + 30 || minutes < 5 * 60;
  }

  static List<ContextSuggestion> suggest({
    required PlanLimits limits,
    required DateTime nowUtc,
    WeatherContext? weather,
  }) {
    final suggestions = <ContextSuggestion>[];

    if (weather != null && (weather.isRaining || weather.rainLikely)) {
      final reduced = _reduce(limits, rainFactor);
      if (reduced != null) {
        suggestions.add(
          ContextSuggestion(
            kind: ContextKind.rain,
            title: weather.isRaining ? 'Está lloviendo' : 'Puede llover pronto',
            message:
                '${weather.isRaining ? 'Hay lluvia ahora' : 'Hay ${weather.rainChancePercent}% de probabilidad de lluvia'}: '
                'te sugerimos caminar como máximo ${reduced.maxContinuousWalkMetres} m seguidos (ahora ${limits.maxContinuousWalkMetres} m).',
            limits: reduced,
          ),
        );
      }
    }

    if (isNight(nowUtc)) {
      final reduced = _reduce(limits, nightFactor);
      if (reduced != null) {
        suggestions.add(
          ContextSuggestion(
            kind: ContextKind.night,
            title: 'Es de noche',
            message:
                'Por seguridad te sugerimos caminar como máximo ${reduced.maxContinuousWalkMetres} m seguidos (ahora ${limits.maxContinuousWalkMetres} m) y preferir avenidas con movimiento.',
            limits: reduced,
          ),
        );
      }
    }
    return suggestions;
  }

  /// Aplica un factor a la caminata. `null` si no cambia nada (ya es el mínimo).
  static PlanLimits? _reduce(PlanLimits limits, double factor) {
    int snap(int metres) => ((metres * factor) / 50).round() * 50;
    final continuous = snap(limits.maxContinuousWalkMetres).clamp(100, 100000);
    final total = snap(limits.maxTotalWalkMetres).clamp(continuous, 100000);
    if (continuous >= limits.maxContinuousWalkMetres) return null;
    return PlanLimits(
      budgetCents: limits.budgetCents,
      maxContinuousWalkMetres: continuous,
      maxTotalWalkMetres: total,
      allowTaxiBridge: limits.allowTaxiBridge,
      priority: limits.priority,
    );
  }
}
