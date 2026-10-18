import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/palette.dart';
import '../data/osm_stops.dart';
import '../domain/routing_engine.dart';
import 'pilot_options_screen.dart';
import 'route_options_screen.dart';

class TripConditionsScreen extends StatefulWidget {
  const TripConditionsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.isDemo,
    this.originStop,
    this.destinationStop,
    this.initialLimits,
  });

  final String origin;
  final String destination;
  final bool isDemo;
  final OsmStop? originStop;
  final OsmStop? destinationStop;
  final PlanLimits? initialLimits;

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
      _priority = switch (initial.priority) {
        PlanPriority.savings => 'Ahorro',
        PlanPriority.lessWalking => 'Menos caminata',
        PlanPriority.time => 'Tiempo',
        PlanPriority.fewerTransfers => 'Menos transbordos',
        PlanPriority.balanced => 'Menos caminata',
      };
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
      priority: switch (_priority) {
        'Ahorro' => PlanPriority.savings,
        'Menos caminata' => PlanPriority.lessWalking,
        'Tiempo' => PlanPriority.time,
        'Menos transbordos' => PlanPriority.fewerTransfers,
        _ => PlanPriority.balanced,
      },
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
          _ConditionCard(
            title: '¿Cuánto puedes gastar?',
            icon: Icons.payments_outlined,
            child: Column(
              children: [
                Container(
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Palette.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
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
                          keyboardType: const TextInputType.numberWithOptions(
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
                  child: Row(
                    children: [
                      const Text(
                        'Distancia estimada',
                        style: TextStyle(color: Palette.inkMuted),
                      ),
                      const Spacer(),
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
