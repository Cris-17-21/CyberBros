import 'package:flutter/material.dart';

import '../../../../core/theme/palette.dart';
import '../../data/trip_memory_service.dart';
import '../../domain/routing_engine.dart';

/// "Tus condiciones de siempre" (RF-26): con consentimiento, recuerda las
/// condiciones de la cuenta y las ofrece al planificar. Nunca cambia los
/// controles sin que la persona pulse "Usar estas", y si el servicio falla lo
/// dice y el formulario sigue igual.
class RememberedConditionsCard extends StatefulWidget {
  const RememberedConditionsCard({
    super.key,
    required this.service,
    required this.currentLimits,
    required this.onApply,
  });

  final TripMemoryService service;

  /// Condiciones que muestran ahora los controles, o `null` si no son válidas.
  final PlanLimits? Function() currentLimits;
  final void Function(PlanLimits limits) onApply;

  @override
  State<RememberedConditionsCard> createState() =>
      _RememberedConditionsCardState();
}

class _RememberedConditionsCardState extends State<RememberedConditionsCard> {
  /// Lo que se muestra; `null` mientras se consulta.
  _Shown? _shown;
  String? _note;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (widget.service.isEnabled) _recall();
  }

  Future<void> _recall() async {
    setState(() {
      _shown = null;
      _note = null;
    });
    final result = await widget.service.recall();
    if (!mounted) return;
    setState(() {
      _shown = switch (result) {
        TripMemoryFound(:final limits) ||
        TripMemorySaved(:final limits) => _Remembered(limits),
        TripMemoryEmpty() || TripMemoryDeleted() => const _Nothing(),
        TripMemorySignedOut() => const _SignedOut(),
        TripMemoryUnavailable() => const _Unavailable(),
      };
    });
  }

  Future<void> _save() async {
    final limits = widget.currentLimits();
    if (limits == null) {
      setState(() => _note = 'Revisa el presupuesto antes de guardar.');
      return;
    }
    setState(() => _busy = true);
    final result = await widget.service.save(limits);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case TripMemorySaved(:final limits):
          _shown = _Remembered(limits);
          _note = 'Guardado. En tu próximo viaje podrás usarlas con un toque.';
        case TripMemorySignedOut():
          _shown = const _SignedOut();
          _note = null;
        case TripMemoryFound() ||
            TripMemoryEmpty() ||
            TripMemoryDeleted() ||
            TripMemoryUnavailable():
          _note = 'No pudimos confirmar que se guardó. Inténtalo de nuevo.';
      }
    });
  }

  Future<void> _forget() async {
    setState(() => _busy = true);
    final result = await widget.service.forget();
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case TripMemoryDeleted():
          _shown = const _Nothing();
          _note = 'Olvidamos tus condiciones guardadas.';
        case TripMemorySignedOut():
          _shown = const _SignedOut();
          _note = null;
        case TripMemoryFound() ||
            TripMemorySaved() ||
            TripMemoryEmpty() ||
            TripMemoryUnavailable():
          _note = 'No pudimos confirmar que se borraron. Inténtalo de nuevo.';
      }
    });
  }

  void _use(PlanLimits remembered) {
    widget.onApply(remembered);
    setState(
      () => _note = 'Usamos tus condiciones guardadas. Puedes ajustarlas.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.service.isEnabled) return const SizedBox.shrink();

    final List<Widget> body = switch (_shown) {
      null => const [
        Row(
          children: [
            SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Buscando tus condiciones guardadas…',
                style: TextStyle(color: Palette.inkMuted),
              ),
            ),
          ],
        ),
      ],
      _SignedOut() => const [
        Text(
          'Inicia sesión para guardar tus condiciones y usarlas en tus '
          'próximos viajes.',
          style: TextStyle(color: Palette.inkMuted),
        ),
      ],
      _Remembered(:final limits) => [
        const Text(
          'Recordamos tus condiciones:',
          style: TextStyle(color: Palette.inkMuted),
        ),
        const SizedBox(height: 6),
        Text(
          describeLimits(limits),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Palette.ink,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            FilledButton.tonalIcon(
              onPressed: _busy ? null : () => _use(limits),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Usar estas'),
            ),
            TextButton(
              onPressed: _busy ? null : _save,
              child: const Text('Guardar las actuales'),
            ),
            TextButton(
              onPressed: _busy ? null : _forget,
              child: const Text('Olvidar'),
            ),
          ],
        ),
      ],
      _Unavailable() => [
        const Text(
          'No pudimos consultar tus condiciones guardadas. Puedes seguir con '
          'los controles de siempre.',
          style: TextStyle(color: Palette.inkMuted),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _recall,
            child: const Text('Reintentar'),
          ),
        ),
      ],
      _Nothing() => [
        const Text(
          'Guarda tu presupuesto, caminata, taxi y prioridad para '
          'precompletarlos la próxima vez.',
          style: TextStyle(color: Palette.inkMuted),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: _busy ? null : _save,
          icon: const Icon(Icons.bookmark_add_outlined, size: 18),
          label: const Text('Guardar mis condiciones'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Se guardan en Atomic Memory solo para tu cuenta. No se guarda tu '
          'ruta, tu ubicación ni tu correo. Puedes borrarlas cuando quieras.',
          style: TextStyle(color: Palette.inkMuted, fontSize: 12),
        ),
      ],
    };

    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.bookmark_outline_rounded, color: Palette.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tus condiciones de siempre',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Palette.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...body,
            if (_note != null) ...[
              const SizedBox(height: 8),
              Text(
                _note!,
                style: const TextStyle(
                  color: Palette.primaryDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: card);
  }
}

/// Estados visibles de la tarjeta.
sealed class _Shown {
  const _Shown();
}

final class _Remembered extends _Shown {
  const _Remembered(this.limits);

  final PlanLimits limits;
}

final class _Nothing extends _Shown {
  const _Nothing();
}

final class _SignedOut extends _Shown {
  const _SignedOut();
}

final class _Unavailable extends _Shown {
  const _Unavailable();
}

/// Resumen corto, p. ej. "S/ 8 · 300 m seguidos · 800 m en total · con taxi
/// · Menos caminata".
String describeLimits(PlanLimits limits) {
  final soles = limits.budgetCents / 100;
  return [
    'S/ ${soles.toStringAsFixed(soles % 1 == 0 ? 0 : 2)}',
    '${limits.maxContinuousWalkMetres} m seguidos',
    '${limits.maxTotalWalkMetres} m en total',
    limits.allowTaxiBridge ? 'con taxi' : 'sin taxi',
    switch (limits.priority) {
      PlanPriority.savings => 'Ahorro',
      PlanPriority.lessWalking => 'Menos caminata',
      PlanPriority.time => 'Tiempo',
      PlanPriority.fewerTransfers => 'Menos transbordos',
      PlanPriority.balanced => 'Equilibrada',
    },
  ].join(' · ');
}
