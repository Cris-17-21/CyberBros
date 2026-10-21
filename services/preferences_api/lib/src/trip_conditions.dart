/// Condiciones de viaje que la persona decidió recordar. Son las mismas que
/// fija en la pantalla "Tus Condiciones"; los rangos coinciden con sus
/// controles para que un valor recordado nunca quede fuera de ellos.
final class TripConditions {
  const TripConditions({
    required this.budgetCents,
    required this.maxContinuousWalkMetres,
    required this.maxTotalWalkMetres,
    required this.allowTaxiBridge,
    required this.priority,
  });

  static const priorities = {
    'savings': 'ahorro',
    'lessWalking': 'menos caminata',
    'time': 'tiempo',
    'fewerTransfers': 'menos transbordos',
    'balanced': 'equilibrada',
  };

  final int budgetCents;
  final int maxContinuousWalkMetres;
  final int maxTotalWalkMetres;
  final bool allowTaxiBridge;
  final String priority;

  /// Valida lo que llega del cliente o de la memoria. Devuelve `null` si algo
  /// falta o está fuera de rango: nunca se guarda ni se devuelve a medias.
  static TripConditions? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final budget = raw['budgetCents'];
    final continuous = raw['maxContinuousWalkMetres'];
    final total = raw['maxTotalWalkMetres'];
    final taxi = raw['allowTaxiBridge'];
    final priority = raw['priority'];
    if (budget is! int || budget < 1 || budget > 20000) return null;
    if (continuous is! int || continuous < 100 || continuous > 800) {
      return null;
    }
    if (total is! int || total < continuous || total > 2000) return null;
    if (taxi is! bool) return null;
    if (priority is! String || !priorities.containsKey(priority)) return null;
    return TripConditions(
      budgetCents: budget,
      maxContinuousWalkMetres: continuous,
      maxTotalWalkMetres: total,
      allowTaxiBridge: taxi,
      priority: priority,
    );
  }

  Map<String, Object> toJson() => {
    'budgetCents': budgetCents,
    'maxContinuousWalkMetres': maxContinuousWalkMetres,
    'maxTotalWalkMetres': maxTotalWalkMetres,
    'allowTaxiBridge': allowTaxiBridge,
    'priority': priority,
  };

  /// Texto del recuerdo: una sola afirmación legible, sin nombre, correo,
  /// ruta ni ubicación.
  String toMemoryText() {
    final soles = (budgetCents / 100).toStringAsFixed(2);
    final taxi = allowTaxiBridge ? 'acepta' : 'no acepta';
    return 'En Rutéalo, la persona prefiere planificar sus viajes con un '
        'presupuesto de S/ $soles, caminar como máximo '
        '$maxContinuousWalkMetres m seguidos y $maxTotalWalkMetres m en '
        'total, $taxi un taxi corto como tramo puente y prioriza '
        '${priorities[priority]}.';
  }
}
