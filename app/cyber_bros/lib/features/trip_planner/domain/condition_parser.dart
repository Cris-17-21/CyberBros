/// Intérprete de condiciones de viaje en español (RF-04).
///
/// Convierte una frase como "Tengo 10 soles, llevo cajas y no quiero caminar
/// más de 2 cuadras seguidas" en parámetros estructurados. Es un analizador
/// propio basado en reglas, determinista, sin red ni claves, y por eso:
///
///  * **No inventa**: lo ambiguo o ausente queda vacío (`null`).
///  * **Valida contra un esquema estricto**: rangos de dinero y de metros.
///  * **Es seguro**: el texto solo puede producir los campos de
///    [ParsedConditions]; nunca se concatena a consultas ni instrucciones.
///  * **No actúa solo**: devuelve etiquetas que la persona debe confirmar
///    antes de usarlas.
library;

import 'routing_engine.dart';

/// Largo máximo aceptado del texto (RNF-12).
const maxConditionTextLength = 500;

/// Equivalencia usada para convertir cuadras a metros (se muestra al usuario).
const metresPerBlock = 100;

enum ParseStatus { ok, partial, failed }

enum ConditionField {
  budget,
  continuousWalk,
  totalWalk,
  allowTaxi,
  priority,
  spent,
}

/// Una condición entendida, lista para mostrarse como etiqueta editable.
final class ConditionTag {
  const ConditionTag(this.field, this.label);

  final ConditionField field;
  final String label;
}

final class ParsedConditions {
  const ParsedConditions({
    this.budgetCents,
    this.maxContinuousWalkMetres,
    this.maxTotalWalkMetres,
    this.allowTaxi,
    this.priority,
    this.spentCents,
    this.tags = const [],
    this.warnings = const [],
    this.status = ParseStatus.failed,
  });

  final int? budgetCents;
  final int? maxContinuousWalkMetres;
  final int? maxTotalWalkMetres;
  final bool? allowTaxi;
  final PlanPriority? priority;

  /// Dinero que la persona dice haber gastado ya en el viaje.
  final int? spentCents;

  final List<ConditionTag> tags;
  final List<String> warnings;
  final ParseStatus status;

  bool get isEmpty => tags.isEmpty;
}

abstract final class ConditionParser {
  /// Dinero máximo plausible: S/ 200 (RF-03).
  static const _maxBudgetCents = 20000;

  /// Caminata máxima plausible: 5 km.
  static const _maxWalkMetres = 5000;

  static ParsedConditions parse(String raw) {
    if (raw.trim().isEmpty) return const ParsedConditions();
    final clipped = raw.length > maxConditionTextLength
        ? raw.substring(0, maxConditionTextLength)
        : raw;
    final text = _numbersToDigits(_normalize(clipped));
    final warnings = <String>[];
    if (raw.length > maxConditionTextLength) {
      warnings.add(
        'El texto era muy largo; solo leímos los primeros $maxConditionTextLength caracteres.',
      );
    }

    final money = _findMoney(text);
    int? budget = money.budget;
    int? spent = money.spent;
    if (budget != null && (budget <= 0 || budget > _maxBudgetCents)) {
      warnings.add(
        'El presupuesto no parece válido (máximo S/ ${_maxBudgetCents ~/ 100}). No lo usamos.',
      );
      budget = null;
    }
    if (spent != null && (spent < 0 || spent > _maxBudgetCents)) spent = null;

    final walk = _findWalk(text);
    int? continuous = walk.continuous;
    int? total = walk.total;
    if (continuous != null && continuous > _maxWalkMetres) {
      warnings.add('La caminata indicada es demasiado larga; no la usamos.');
      continuous = null;
    }
    if (total != null && total > _maxWalkMetres) total = null;
    if (continuous != null && total != null && continuous > total) {
      total = continuous; // RF-03: la total nunca es menor que la seguida
      warnings.add('Ajustamos la caminata total para que no sea menor que la seguida.');
    }

    final taxi = _findTaxi(text);
    final priority = _findPriority(text);

    final tags = <ConditionTag>[
      if (budget != null)
        ConditionTag(
          ConditionField.budget,
          'Presupuesto: ${_soles(budget)}',
        ),
      if (spent != null)
        ConditionTag(ConditionField.spent, 'Ya gastaste: ${_soles(spent)}'),
      if (continuous != null)
        ConditionTag(
          ConditionField.continuousWalk,
          'Caminata seguida: máx. ${_metresLabel(continuous)}',
        ),
      if (total != null)
        ConditionTag(
          ConditionField.totalWalk,
          'Caminata total: máx. ${_metresLabel(total)}',
        ),
      if (taxi != null)
        ConditionTag(
          ConditionField.allowTaxi,
          taxi ? 'Acepta taxi en algún tramo' : 'Sin taxi',
        ),
      if (priority != null)
        ConditionTag(ConditionField.priority, 'Prioridad: ${_priorityLabel(priority)}'),
    ];

    final status = tags.isEmpty
        ? ParseStatus.failed
        : (budget != null && continuous != null)
        ? ParseStatus.ok
        : ParseStatus.partial;
    return ParsedConditions(
      budgetCents: budget,
      spentCents: spent,
      maxContinuousWalkMetres: continuous,
      maxTotalWalkMetres: total,
      allowTaxi: taxi,
      priority: priority,
      tags: tags,
      warnings: warnings,
      status: status,
    );
  }

  // ------------------------------------------------------------- dinero

  static ({int? budget, int? spent}) _findMoney(String text) {
    final matches = <({int cents, int start})>[];
    // "s/ 10", "s/. 2.50"
    for (final m in RegExp(r's/\.?\s*(\d+(?:\.\d+)?)').allMatches(text)) {
      matches.add((cents: _toCents(m.group(1)!), start: m.start));
    }
    // "10 soles", "2.50 sol"
    for (final m in RegExp(r'(\d+(?:\.\d+)?)\s*(?:nuevos soles|soles|sol)\b')
        .allMatches(text)) {
      matches.add((cents: _toCents(m.group(1)!), start: m.start));
    }
    matches.sort((a, b) => a.start.compareTo(b.start));
    int? budget;
    int? spent;
    for (final match in matches) {
      final before = text.substring(
        match.start >= 28 ? match.start - 28 : 0,
        match.start,
      );
      final isSpent = RegExp(r'(gast|pag|cost[oó]|me cobr)').hasMatch(before);
      if (isSpent) {
        spent ??= match.cents;
      } else {
        budget ??= match.cents;
      }
    }
    return (budget: budget, spent: spent);
  }

  static int _toCents(String number) => (double.parse(number) * 100).round();

  // ---------------------------------------------------------- caminata

  static ({int? continuous, int? total}) _findWalk(String text) {
    int? continuous;
    int? total;
    final pattern = RegExp(
      r'(\d+(?:\.\d+)?)\s*(cuadras?|metros?|mts|km|kilometros?|m)\b',
    );
    for (final m in pattern.allMatches(text)) {
      final unit = m.group(2)!;
      final value = double.parse(m.group(1)!);
      final metres = switch (unit) {
        'cuadra' || 'cuadras' => (value * metresPerBlock).round(),
        'km' || 'kilometro' || 'kilometros' => (value * 1000).round(),
        _ => value.round(),
      };
      final before = text.substring(m.start >= 40 ? m.start - 40 : 0, m.start);
      final after = text.substring(
        m.end,
        m.end + 24 <= text.length ? m.end + 24 : text.length,
      );
      final isWalking =
          unit.startsWith('cuadra') ||
          RegExp(r'(camin|a pie|andar|pie)').hasMatch(before) ||
          RegExp(r'(camin|a pie|de caminata)').hasMatch(after) ||
          // "500 metros seguidos" o "300 metros en total" ya implican caminar.
          RegExp(r'(seguid|continu|en total|de corrido|sin parar)')
              .hasMatch(after);
      if (!isWalking) continue;
      final isTotal = RegExp(r'\btotal(es)?\b').hasMatch('$before $after');
      final isContinuous = RegExp(
        r'(seguid|continu|sin parar|de corrido|de una vez)',
      ).hasMatch(after);
      if (isTotal && !isContinuous) {
        total ??= metres;
      } else {
        continuous ??= metres;
      }
    }
    return (continuous: continuous, total: total);
  }

  // -------------------------------------------------------- taxi y otros

  static bool? _findTaxi(String text) {
    if (!text.contains('taxi')) return null;
    if (RegExp(r'\b(sin|no)\s+(quiero\s+|acepto\s+|usar\s+|tomar\s+|con\s+|un\s+)?taxi')
        .hasMatch(text)) {
      return false;
    }
    if (RegExp(
      r'(puedo|acepto|quiero|con|si hace falta|de ser necesario|tomaria|tomar)\s+(un\s+)?taxi|taxi\s+(si|solo|corto)',
    ).hasMatch(text)) {
      return true;
    }
    return null; // se nombra el taxi pero no se entiende si lo acepta
  }

  static PlanPriority? _findPriority(String text) {
    if (RegExp(r'(sin transbordos|menos transbordos|directo)').hasMatch(text)) {
      return PlanPriority.fewerTransfers;
    }
    if (RegExp(r'(mas rapido|rapido|llegar pronto|apurad|tengo prisa|con prisa)')
        .hasMatch(text)) {
      return PlanPriority.time;
    }
    if (RegExp(r'(menos caminata|caminar poco|caminar lo menos)').hasMatch(text)) {
      return PlanPriority.lessWalking;
    }
    if (RegExp(r'(mas barato|lo barato|ahorrar|economic)').hasMatch(text)) {
      return PlanPriority.savings;
    }
    if (text.contains('equilibrad')) return PlanPriority.balanced;
    return null;
  }

  // ------------------------------------------------------------ texto

  static String _normalize(String input) {
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    final buffer = StringBuffer();
    for (final rune in input.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final index = from.indexOf(char);
      buffer.write(index >= 0 ? to[index] : char);
    }
    return buffer
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d),(\d)'),
          (m) => '${m.group(1)}.${m.group(2)}',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const _units = {
    'cero': 0,
    'un': 1,
    'uno': 1,
    'una': 1,
    'dos': 2,
    'tres': 3,
    'cuatro': 4,
    'cinco': 5,
    'seis': 6,
    'siete': 7,
    'ocho': 8,
    'nueve': 9,
    'diez': 10,
    'once': 11,
    'doce': 12,
    'trece': 13,
    'catorce': 14,
    'quince': 15,
    'dieciseis': 16,
    'diecisiete': 17,
    'dieciocho': 18,
    'diecinueve': 19,
    'veinte': 20,
    'veintiuno': 21,
    'veintidos': 22,
    'veintitres': 23,
    'veinticuatro': 24,
    'veinticinco': 25,
    'veintiseis': 26,
    'veintisiete': 27,
    'veintiocho': 28,
    'veintinueve': 29,
  };

  static const _tens = {
    'treinta': 30,
    'cuarenta': 40,
    'cincuenta': 50,
    'sesenta': 60,
    'setenta': 70,
    'ochenta': 80,
    'noventa': 90,
    'cien': 100,
    'ciento': 100,
    'doscientos': 200,
    'trescientos': 300,
    'cuatrocientos': 400,
    'quinientos': 500,
  };

  /// Reemplaza números escritos con letras por dígitos ("treinta y cinco" ->
  /// "35"). "un/una" solo se convierte si lo sigue una unidad de medida o de
  /// dinero, para no tocar frases como "una persona".
  static String _numbersToDigits(String text) {
    final tokens = text.split(' ');
    final out = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i].replaceAll(RegExp(r'[.,;:!?]+$'), '');
      final trailing = tokens[i].substring(token.length);
      final next = i + 1 < tokens.length ? tokens[i + 1] : '';
      final isMeasure = RegExp(r'^(sol|soles|cuadra|cuadras|metro|metros|km|m)')
          .hasMatch(next);
      if (_tens.containsKey(token)) {
        var value = _tens[token]!;
        if (i + 2 < tokens.length &&
            tokens[i + 1] == 'y' &&
            _units.containsKey(tokens[i + 2]) &&
            _units[tokens[i + 2]]! < 10) {
          value += _units[tokens[i + 2]]!;
          i += 2;
        }
        out.add('$value$trailing');
      } else if (_units.containsKey(token) &&
          (!{'un', 'uno', 'una'}.contains(token) || isMeasure)) {
        out.add('${_units[token]}$trailing');
      } else {
        out.add(tokens[i]);
      }
    }
    return out.join(' ');
  }

  // ------------------------------------------------------- presentación

  static String _soles(int cents) => 'S/ ${(cents / 100).toStringAsFixed(2)}';

  static String _metresLabel(int metres) {
    final blocks = (metres / metresPerBlock).round();
    return '$metres m (≈ $blocks ${blocks == 1 ? 'cuadra' : 'cuadras'})';
  }

  static String _priorityLabel(PlanPriority priority) => switch (priority) {
    PlanPriority.savings => 'ahorrar',
    PlanPriority.lessWalking => 'caminar menos',
    PlanPriority.time => 'llegar rápido',
    PlanPriority.fewerTransfers => 'menos transbordos',
    PlanPriority.balanced => 'equilibrada',
  };
}
