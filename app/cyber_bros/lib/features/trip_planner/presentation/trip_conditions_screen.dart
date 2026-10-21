import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/palette.dart';
import '../data/osm_stops.dart';
import '../data/trip_memory_service.dart';
import '../domain/condition_parser.dart';
import '../domain/context_advisor.dart';
import '../domain/routing_engine.dart';
import 'pilot_options_screen.dart';
import 'route_options_screen.dart';
import 'widgets/context_banner.dart';
import 'widgets/natural_language_card.dart';
import 'widgets/remembered_conditions_card.dart';

class TripConditionsScreen extends StatefulWidget {
  const TripConditionsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.isDemo,
    this.originStop,
    this.destinationStop,
    this.initialLimits,
    this.tripMemory,
  });

  final String origin;
  final String destination;
  final bool isDemo;
  final OsmStop? originStop;
  final OsmStop? destinationStop;
  final PlanLimits? initialLimits;

  /// Condiciones recordadas (RF-26); por defecto la instancia global, que está
  /// apagada salvo que se configure `TRIP_MEMORY_API_URL`.
  final TripMemoryService? tripMemory;

  @override
  State<TripConditionsScreen> createState() => _TripConditionsScreenState();
}

class _TripConditionsScreenState extends State<TripConditionsScreen> {
  final _budgetController = TextEditingController(text: '8');
  final _notesController = TextEditingController();
  double _walkingLimit = 300;
  double _totalWalkingLimit = 800;
  bool _allowTaxi = true;
  String _priority = 'Menos caminata';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialLimits;
    if (initial != null) {
      _budgetController.text = (initial.budgetCents / 100).toStringAsFixed(2);
      _walkingLimit = initial.maxContinuousWalkMetres.toDouble().clamp(100, 800);
      _totalWalkingLimit = initial.maxTotalWalkMetres.toDouble().clamp(
        _walkingLimit,
        2000,
      );
      _allowTaxi = initial.allowTaxiBridge;
      _priority = _priorityLabel(initial.priority);
    } else {
      // Calcular presupuesto sugerido inteligente según distancia entre puntos
      if (widget.originStop != null && widget.destinationStop != null) {
        final dist = const Distance().as(
          LengthUnit.Meter,
          widget.originStop!.point,
          widget.destinationStop!.point,
        );
        // Si es menos de 1km, caminata o pasaje mínimo; si es más, bus regular + margen o taxi
        if (dist < 1000) {
          _budgetController.text = '2.50';
        } else if (dist < 4000) {
          _budgetController.text = '5.00';
        } else if (dist < 9000) {
          _budgetController.text = '9.50';
        } else {
          _budgetController.text = '16.00';
        }
      }
    }
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _getDynamicStep(double currentCost) {
    if (currentCost < 4.0) return 0.50; // S/ 0 a S/ 4: paso de 50 céntimos
    if (currentCost < 10.0) return 1.00; // S/ 4 a S/ 10: paso de 1 sol
    if (currentCost < 25.0) return 2.50; // S/ 10 a S/ 25: paso de 2.50 soles
    if (currentCost < 50.0) return 5.00; // S/ 25 a S/ 50: paso de 5 soles
    return 10.00;                        // S/ 50+: paso de 10 soles
  }

  void _stepBudget({required bool increment}) {
    final current =
        double.tryParse(_budgetController.text.replaceAll(',', '.')) ?? 8.0;
    final step = increment
        ? _getDynamicStep(current)
        : _getDynamicStep(math.max(0.1, current - 0.05));
    final next = increment
        ? (current + step).clamp(0.50, 200.0)
        : (current - step).clamp(0.50, 200.0);
    setState(() {
      _budgetController.text = next.toStringAsFixed(next % 1 == 0 ? 0 : 2);
    });
  }

  /// Pasa a los controles lo que la persona confirmó del texto libre. Los
  /// valores se ajustan a lo que permiten los controles y se avisa si hace
  /// falta.
  void _applyParsed(ParsedConditions parsed, Set<ConditionField> accepted) {
    final notes = <String>[];
    setState(() {
      if (accepted.contains(ConditionField.budget) &&
          parsed.budgetCents != null) {
        final soles = parsed.budgetCents! / 100;
        _budgetController.text = soles.toStringAsFixed(soles % 1 == 0 ? 0 : 2);
      }
      if (accepted.contains(ConditionField.continuousWalk) &&
          parsed.maxContinuousWalkMetres != null) {
        final metres = parsed.maxContinuousWalkMetres!;
        final snapped = ((metres / 100).round() * 100).clamp(100, 800);
        if (snapped != metres) {
          notes.add('La caminata seguida se ajustó a $snapped m (el control va de 100 a 800 m).');
        }
        _walkingLimit = snapped.toDouble();
        if (_totalWalkingLimit < _walkingLimit) _totalWalkingLimit = _walkingLimit;
      }
      if (accepted.contains(ConditionField.totalWalk) &&
          parsed.maxTotalWalkMetres != null) {
        final snapped = ((parsed.maxTotalWalkMetres! / 50).round() * 50)
            .clamp(_walkingLimit.round(), 2000);
        _totalWalkingLimit = snapped.toDouble();
      }
      if (accepted.contains(ConditionField.allowTaxi) &&
          parsed.allowTaxi != null) {
        _allowTaxi = parsed.allowTaxi!;
      }
      if (accepted.contains(ConditionField.priority) &&
          parsed.priority != null) {
        _priority = switch (parsed.priority!) {
          PlanPriority.savings => 'Ahorro',
          PlanPriority.lessWalking => 'Menos caminata',
          PlanPriority.time => 'Tiempo',
          PlanPriority.fewerTransfers => 'Menos transbordos',
          PlanPriority.balanced => 'Menos caminata',
        };
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notes.isEmpty
              ? 'Listo: revisa los controles y pulsa Ver opciones.'
              : notes.join(' '),
        ),
      ),
    );
  }

  static String _priorityLabel(PlanPriority priority) => switch (priority) {
    PlanPriority.savings => 'Ahorro',
    PlanPriority.lessWalking => 'Menos caminata',
    PlanPriority.time => 'Tiempo',
    PlanPriority.fewerTransfers => 'Menos transbordos',
    PlanPriority.balanced => 'Menos caminata',
  };

  PlanPriority get _priorityValue => switch (_priority) {
    'Ahorro' => PlanPriority.savings,
    'Menos caminata' => PlanPriority.lessWalking,
    'Tiempo' => PlanPriority.time,
    'Menos transbordos' => PlanPriority.fewerTransfers,
    _ => PlanPriority.balanced,
  };

  /// Límites actuales según los controles (para calcular sugerencias).
  PlanLimits _currentLimits() => PlanLimits(
    budgetCents: ((double.tryParse(_budgetController.text.replaceAll(',', '.')) ?? 8) * 100).round(),
    maxContinuousWalkMetres: _walkingLimit.round(),
    maxTotalWalkMetres: _totalWalkingLimit.round(),
    allowTaxiBridge: _allowTaxi,
    priority: _priorityValue,
  );

  /// Lo que se guardaría como condiciones de siempre, o `null` si el
  /// presupuesto escrito no es válido.
  PlanLimits? _limitsToRemember() {
    final budget = double.tryParse(_budgetController.text.replaceAll(',', '.'));
    if (budget == null || budget <= 0 || budget > 200) return null;
    return PlanLimits(
      budgetCents: (budget * 100).round(),
      maxContinuousWalkMetres: _walkingLimit.round(),
      maxTotalWalkMetres: _totalWalkingLimit.round(),
      allowTaxiBridge: _allowTaxi,
      priority: _priorityValue,
    );
  }

  /// La persona eligió usar sus condiciones recordadas.
  void _applyRemembered(PlanLimits limits) {
    setState(() {
      final soles = limits.budgetCents / 100;
      _budgetController.text = soles.toStringAsFixed(soles % 1 == 0 ? 0 : 2);
      _walkingLimit = limits.maxContinuousWalkMetres.toDouble().clamp(100, 800);
      _totalWalkingLimit = limits.maxTotalWalkMetres.toDouble().clamp(
        _walkingLimit,
        2000,
      );
      _allowTaxi = limits.allowTaxiBridge;
      _priority = _priorityLabel(limits.priority);
    });
  }

  /// La persona aceptó una sugerencia de clima u hora: se aplica a la caminata.
  void _applyContext(ContextSuggestion suggestion) {
    setState(() {
      _walkingLimit = suggestion.limits.maxContinuousWalkMetres
          .toDouble()
          .clamp(100, 800);
      _totalWalkingLimit = suggestion.limits.maxTotalWalkMetres
          .toDouble()
          .clamp(_walkingLimit, 2000);
    });
  }

  void _openOptions() {
    final budget = double.tryParse(_budgetController.text.replaceAll(',', '.'));
    if (budget == null || budget <= 0 || budget > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un presupuesto entre S/ 0,01 y S/ 200.'),
        ),
      );
      return;
    }
    final limits = PlanLimits(
      budgetCents: (budget * 100).round(),
      maxContinuousWalkMetres: _walkingLimit.round(),
      maxTotalWalkMetres: _totalWalkingLimit.round(),
      allowTaxiBridge: _allowTaxi,
      priority: _priorityValue,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => widget.isDemo
            ? RouteOptionsScreen(
                origin: widget.origin,
                destination: widget.destination,
                budget: budget,
                isDemo: true,
                maxContinuousWalkMetres: _walkingLimit.round(),
                maxTotalWalkMetres: _totalWalkingLimit.round(),
                allowTaxi: _allowTaxi,
              )
            : PilotOptionsScreen(
                origin: widget.originStop!,
                destination: widget.destinationStop!,
                limits: limits,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Tus Condiciones',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4),
        ),
        actions: [
          IconButton(
            tooltip: 'Cuenta',
            onPressed: () {},
            icon: const CircleAvatar(
              radius: 17,
              backgroundColor: Palette.primaryDark,
              child: Icon(Icons.person_outline_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.near_me_outlined, color: Palette.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RUTA SELECCIONADA',
                          style: TextStyle(
                            color: Palette.inkMuted,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.origin} → ${widget.destination}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cambiar'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          RememberedConditionsCard(
            service: widget.tripMemory ?? TripMemoryService.instance,
            currentLimits: _limitsToRemember,
            onApply: _applyRemembered,
          ),
          NaturalLanguageCard(onApply: _applyParsed),
          const SizedBox(height: 14),
          ContextBanner(
            point: widget.originStop?.point ?? const LatLng(-12.0464, -77.0428),
            limits: _currentLimits(),
            onApply: _applyContext,
          ),
          _ConditionCard(
            title: '¿Cuánto puedes gastar?',
            icon: Icons.payments_outlined,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botón para bajar el costo
                    Material(
                      color: Palette.surface,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 1.5,
                      shadowColor: Colors.black.withValues(alpha: 0.08),
                      child: InkWell(
                        onTap: () => _stepBudget(increment: false),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 52,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Palette.inkMuted.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Icon(
                            Icons.remove_rounded,
                            size: 26,
                            color: Palette.ink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Visualizador central del costo
                    Expanded(
                      child: Container(
                        height: 64,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Palette.surfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Palette.primary.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'S/  ',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Palette.inkMuted,
                              ),
                            ),
                            SizedBox(
                              width: 96,
                              child: TextField(
                                controller: _budgetController,
                                textAlign: TextAlign.center,
                                onChanged: (_) => setState(() {}),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Palette.ink,
                                  letterSpacing: -0.8,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  filled: false,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botón para subir el costo
                    Material(
                      color: Palette.primary,
                      borderRadius: BorderRadius.circular(16),
                      elevation: 2,
                      shadowColor: Palette.primary.withValues(alpha: 0.35),
                      child: InkWell(
                        onTap: () => _stepBudget(increment: true),
                        borderRadius: BorderRadius.circular(16),
                        child: const SizedBox(
                          width: 52,
                          height: 60,
                          child: Icon(
                            Icons.add_rounded,
                            size: 26,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final curr = double.tryParse(
                          _budgetController.text.replaceAll(',', '.'),
                        ) ??
                        8.0;
                    final step = _getDynamicStep(curr);
                    return Text(
                      'Paso dinámico: ±S/ ${step.toStringAsFixed(step % 1 == 0 ? 0 : 2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Palette.inkMuted,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final value in [6, 8, 10, 15])
                      ChoiceChip(
                        label: Text('S/ $value'),
                        selected:
                            double.tryParse(_budgetController.text) == value,
                        onSelected: (_) =>
                            setState(() => _budgetController.text = '$value'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ConditionCard(
            title: '¿Cuánto caminas seguido?',
            icon: Icons.directions_walk_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // Con letra grande o pantalla angosta, el valor pasa abajo
                  // en lugar de desbordar.
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 8,
                    children: [
                      const Text(
                        'Distancia estimada',
                        style: TextStyle(color: Palette.inkMuted),
                      ),
                      Text(
                        '${_walkingLimit.round()} m ≈ ${(_walkingLimit / 100).round()} cuadras',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Palette.primary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Slider(
                  value: _walkingLimit,
                  min: 100,
                  max: 800,
                  divisions: 7,
                  onChanged: (value) => setState(() {
                    _walkingLimit = value;
                    if (_totalWalkingLimit < value) _totalWalkingLimit = value;
                  }),
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('100'),
                    Text('200'),
                    Text('300'),
                    Text('500'),
                    Text('800 m'),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Caminata total máxima: ${_totalWalkingLimit.round()} m'),
                Slider(
                  value: _totalWalkingLimit,
                  min: _walkingLimit,
                  max: 2000,
                  divisions: ((2000 - _walkingLimit) / 50).round(),
                  label: '${_totalWalkingLimit.round()} m',
                  onChanged: (value) =>
                      setState(() => _totalWalkingLimit = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ConditionCard(
            title: '¿Aceptas un taxi corto?',
            icon: Icons.local_taxi_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Permitir taxi puente si reduce la caminata.',
                        style: TextStyle(color: Palette.inkMuted),
                      ),
                    ),
                    Switch(
                      value: _allowTaxi,
                      onChanged: (value) => setState(() => _allowTaxi = value),
                    ),
                  ],
                ),
                if (_allowTaxi)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE0D9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'El precio del taxi debe confirmarse en la app del proveedor.',
                      style: TextStyle(color: Palette.taxi, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ConditionCard(
            title: 'Prioridad de viaje',
            icon: Icons.tune_rounded,
            child: Column(
              children: [
                for (final row in [
                  ['Ahorro', 'Menos caminata'],
                  ['Tiempo', 'Menos transbordos'],
                ]) ...[
                  Row(
                    children: [
                      for (final option in row) ...[
                        Expanded(
                          child: _PriorityButton(
                            label: option,
                            icon: switch (option) {
                              'Ahorro' => Icons.savings_outlined,
                              'Menos caminata' => Icons.directions_walk_rounded,
                              'Tiempo' => Icons.timer_outlined,
                              _ => Icons.swap_horiz_rounded,
                            },
                            selected: _priority == option,
                            onTap: () => setState(() => _priority = option),
                          ),
                        ),
                        if (option == row.first) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ConditionCard(
            title: 'Cuéntalo con tus palabras',
            icon: Icons.edit_note_rounded,
            child: TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Ej. Tengo prisa, pero solo llevo S/ 7…',
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _openOptions,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Ver opciones'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              backgroundColor: Palette.primaryDark,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Demostración visual · tarifas y recorridos pendientes de verificación',
            textAlign: TextAlign.center,
            style: TextStyle(color: Palette.inkMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: Palette.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Palette.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _PriorityButton extends StatelessWidget {
  const _PriorityButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Palette.primary : Palette.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 58,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : Palette.primary,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : Palette.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
