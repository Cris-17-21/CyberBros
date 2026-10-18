import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/palette.dart';
import '../data/guest_history.dart';
import '../data/osm_stops.dart';
import '../domain/routing_engine.dart';
import 'trip_conditions_screen.dart';

enum _Filter { all, active, completed, abandoned }

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  late Future<List<GuestTripSnapshot>> _trips = GuestHistoryRepository.instance
      .list();
  _Filter _filter = _Filter.all;

  Future<void> _refresh() async {
    final next = GuestHistoryRepository.instance.list();
    setState(() => _trips = next);
    await next;
  }

  bool _matches(GuestTripSnapshot trip) => switch (_filter) {
    _Filter.all => true,
    _Filter.active =>
      trip.status == GuestTripStatus.active ||
          trip.status == GuestTripStatus.planned,
    _Filter.completed => trip.status == GuestTripStatus.completed,
    _Filter.abandoned => trip.status == GuestTripStatus.abandoned,
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Palette.background,
    appBar: AppBar(title: const Text('Mis viajes')),
    body: FutureBuilder<List<GuestTripSnapshot>>(
      future: _trips,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _MessageState(
            icon: Icons.error_outline_rounded,
            title: 'No pudimos cargar tus viajes',
            text: 'Revisa tu conexión e inténtalo de nuevo.',
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data!;
        final trips = all.where(_matches).toList();
        final cloud = GuestHistoryRepository.instance.cloudSync;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _SyncBanner(cloud: cloud),
                  if (!GuestHistoryRepository.instance.storageAvailable) ...[
                    const SizedBox(height: 10),
                    const _Banner(
                      icon: Icons.warning_amber_rounded,
                      color: Palette.estimated,
                      background: Palette.estimatedBg,
                      text:
                          'El almacenamiento está bloqueado. Los viajes solo estarán disponibles durante esta visita.',
                    ),
                  ],
                  if (all.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _FilterBar(
                      selected: _filter,
                      onChanged: (value) => setState(() => _filter = value),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (all.isEmpty)
                    _EmptyHistory(onPlan: () => Navigator.of(context).pop())
                  else if (trips.isEmpty)
                    const _MessageState(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'Sin viajes en este filtro',
                      text: 'Prueba con otra categoría.',
                    )
                  else
                    for (final trip in trips)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TripCard(
                          trip: trip,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    _TripHistoryDetailScreen(trip: trip),
                              ),
                            );
                            if (mounted) _refresh();
                          },
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

// ---------------------------------------------------------------- lista

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.cloud});

  final bool cloud;

  @override
  Widget build(BuildContext context) => _Banner(
    icon: cloud ? Icons.cloud_done_outlined : Icons.phone_android_rounded,
    color: cloud ? Palette.confirmed : Palette.primary,
    background: cloud ? Palette.confirmedBg : Palette.primaryLight,
    text: cloud
        ? 'Guardados en tu cuenta. Los ves en todos tus dispositivos.'
        : 'Guardados solo en este celular por 30 días. Inicia sesión para conservarlos en tu cuenta.',
  );
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.background,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 13, height: 1.3),
          ),
        ),
      ],
    ),
  );
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _Filter selected;
  final ValueChanged<_Filter> onChanged;

  static const _labels = {
    _Filter.all: 'Todos',
    _Filter.active: 'En curso',
    _Filter.completed: 'Completados',
    _Filter.abandoned: 'Abandonados',
  };

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final filter in _Filter.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_labels[filter]!),
              selected: selected == filter,
              onSelected: (_) => onChanged(filter),
              showCheckmark: false,
              labelStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected == filter ? Colors.white : Palette.ink,
              ),
              selectedColor: Palette.primary,
              backgroundColor: Palette.surface,
              side: BorderSide(
                color: selected == filter ? Palette.primary : Palette.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
      ],
    ),
  );
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});

  final GuestTripSnapshot trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(trip.status);
    return Material(
      color: Palette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusChip(trip.status),
                  const Spacer(),
                  Text(
                    _friendlyDate(trip.createdAtUtc),
                    style: const TextStyle(
                      color: Palette.inkMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _RouteLine(
                from: trip.originLabel,
                to: trip.destinationLabel,
                color: style.color,
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Palette.border),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      icon: Icons.payments_outlined,
                      value: _soles(trip.costCents),
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      icon: Icons.directions_walk_rounded,
                      value: '${trip.walkMetres} m',
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      icon: Icons.schedule_rounded,
                      value: '${trip.durationMinutes} min',
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Palette.inkMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Origen y destino unidos por una línea, como un mini recorrido.
class _RouteLine extends StatelessWidget {
  const _RouteLine({required this.from, required this.to, required this.color});

  final String from;
  final String to;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          const SizedBox(height: 3),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 3),
              color: Palette.surface,
            ),
          ),
          Container(width: 2, height: 24, color: color.withValues(alpha: 0.3)),
          Icon(Icons.location_on_rounded, size: 18, color: color),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              from,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Palette.inkMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              to,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Palette.ink,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 17, color: Palette.inkMuted),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Palette.ink,
            fontSize: 13.5,
          ),
        ),
      ),
    ],
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);

  final GuestTripStatus status;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.color),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.onPlan});

  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 40),
    child: Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Palette.primaryLight,
          ),
          child: const Icon(
            Icons.alt_route_rounded,
            size: 44,
            color: Palette.primary,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Aún no tienes viajes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Palette.ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Planifica una ruta y elígela: aparecerá aquí para que la repitas cuando quieras.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Palette.inkMuted, height: 1.4),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onPlan,
          icon: const Icon(Icons.explore_outlined),
          label: const Text('Planificar un viaje'),
        ),
      ],
    ),
  );
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Palette.inkMuted),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Palette.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.inkMuted),
          ),
        ],
      ),
    ),
  );
}

// -------------------------------------------------------------- detalle

class _TripHistoryDetailScreen extends StatefulWidget {
  const _TripHistoryDetailScreen({required this.trip});

  final GuestTripSnapshot trip;

  @override
  State<_TripHistoryDetailScreen> createState() =>
      _TripHistoryDetailScreenState();
}

class _TripHistoryDetailScreenState extends State<_TripHistoryDetailScreen> {
  late GuestTripSnapshot _trip = widget.trip;
  bool _busy = false;

  Future<void> _updateStatus(GuestTripStatus status) async {
    if (_busy) return;
    setState(() => _busy = true);
    final updated = _trip.withStatus(status);
    final saved = await GuestHistoryRepository.instance.save(updated);
    if (!mounted) return;
    setState(() {
      _trip = updated;
      _busy = false;
    });
    final notifications = NotificationService.instance;
    switch (status) {
      case GuestTripStatus.active:
        unawaited(notifications.cancelTripReminders(updated.id));
      case GuestTripStatus.completed || GuestTripStatus.abandoned:
        unawaited(notifications.cancelTripReminders(updated.id));
        unawaited(
          notifications.scheduleFeedbackReminder(
            tripId: updated.id,
            destination: updated.destinationLabel,
          ),
        );
      case GuestTripStatus.planned:
        break;
    }
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cambio visible solo durante esta visita.'),
        ),
      );
    }
  }

  Future<void> _repeat() async {
    final catalog = await OsmStopCatalog.load();
    final origin = catalog.findById(_trip.originId);
    final destination = catalog.findById(_trip.destinationId);
    if (!mounted) return;
    if (origin == null || destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Un punto ya no figura en los datos actuales. Elige uno nuevo en Planificar.',
          ),
        ),
      );
      return;
    }
    final priority =
        PlanPriority.values
            .where((item) => item.name == _trip.priority)
            .firstOrNull ??
        PlanPriority.balanced;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripConditionsScreen(
          origin: origin.displayName,
          destination: destination.displayName,
          isDemo: false,
          originStop: origin,
          destinationStop: destination,
          initialLimits: PlanLimits(
            budgetCents: _trip.budgetCents,
            maxContinuousWalkMetres: _trip.maxContinuousWalkMetres,
            maxTotalWalkMetres: _trip.maxTotalWalkMetres,
            allowTaxiBridge: _trip.allowTaxi,
            priority: priority,
          ),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar este viaje'),
        content: Text(
          GuestHistoryRepository.instance.cloudSync
              ? 'Se borrará de tu cuenta y de todos tus dispositivos.'
              : 'Se borrará del historial local de este dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    unawaited(NotificationService.instance.cancelTripReminders(_trip.id));
    unawaited(NotificationService.instance.cancelFeedbackReminder(_trip.id));
    await GuestHistoryRepository.instance.delete(_trip.id);
    final warning = GuestHistoryRepository.instance.deleteWarning;
    if (warning != null) {
      messenger.showSnackBar(SnackBar(content: Text(warning)));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cloud = GuestHistoryRepository.instance.cloudSync;
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(title: const Text('Detalle del viaje')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _DetailHero(trip: _trip),
              const SizedBox(height: 20),
              const _SectionTitle('Recorrido'),
              const SizedBox(height: 10),
              _Journey(legs: _trip.legs),
              const SizedBox(height: 8),
              Text(
                'Datos del ${_trip.dataVersion}. El recorrido guardado no cambia aunque las rutas se actualicen.',
                style: const TextStyle(color: Palette.inkMuted, fontSize: 12),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _busy ? null : _repeat,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Repetir con datos actuales'),
              ),
              if (_trip.status == GuestTripStatus.planned) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _updateStatus(GuestTripStatus.active),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Marcar viaje iniciado'),
                  style: _outlined(Palette.primary),
                ),
              ],
              if (_trip.status == GuestTripStatus.active) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _updateStatus(GuestTripStatus.completed),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Marcar completado'),
                  style: _outlined(Palette.confirmed),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _updateStatus(GuestTripStatus.abandoned),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Marcar abandonado'),
                  style: _outlined(Palette.inkMuted),
                ),
              ],
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Eliminar viaje'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                cloud
                    ? 'Guardado en tu cuenta. Los estados se registran manualmente; no prueban que el servicio operó.'
                    : 'Historial local de invitado. Los estados se registran manualmente; no prueban que el servicio operó.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.inkMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _outlined(Color color) => OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(52),
    foregroundColor: color,
    side: BorderSide(color: color.withValues(alpha: 0.5)),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.trip});

  final GuestTripSnapshot trip;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Palette.primaryDark, Palette.primary],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Palette.primary.withValues(alpha: 0.25),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusChip(trip.status),
            const Spacer(),
            Text(
              _friendlyDate(trip.createdAtUtc),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _LightRouteLine(from: trip.originLabel, to: trip.destinationLabel),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _HeroStat(value: _soles(trip.costCents), label: 'Estimado'),
              const _HeroDivider(),
              _HeroStat(value: '${trip.walkMetres} m', label: 'A pie'),
              const _HeroDivider(),
              _HeroStat(value: '~${trip.durationMinutes} min', label: 'Tiempo'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          trip.alternativeLabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

/// Variante clara del trazo de ruta para fondos oscuros.
class _LightRouteLine extends StatelessWidget {
  const _LightRouteLine({required this.from, required this.to});

  final String from;
  final String to;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          const SizedBox(height: 3),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
          Container(width: 2, height: 26, color: Colors.white38),
          const Icon(Icons.location_on_rounded, size: 18, color: Colors.white),
        ],
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              from,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              to,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: Colors.white24);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: Palette.ink,
      letterSpacing: -0.3,
    ),
  );
}

/// Recorrido como línea de tiempo vertical con un paso por tramo.
class _Journey extends StatelessWidget {
  const _Journey({required this.legs});

  final List<GuestTripLeg> legs;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < legs.length; i++)
        _JourneyStep(leg: legs[i], isLast: i == legs.length - 1),
    ],
  );
}

class _JourneyStep extends StatelessWidget {
  const _JourneyStep({required this.leg, required this.isLast});

  final GuestTripLeg leg;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = _legColor(leg.kind);
    final certainty = _certainty(leg.certainty);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_legIcon(leg.kind), color: color, size: 20),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Palette.border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _legTitle(leg),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Palette.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${leg.from} → ${leg.to}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Palette.inkMuted,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: certainty.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      certainty.label,
                      style: TextStyle(
                        color: certainty.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- ayudas

typedef _Style = ({Color color, Color background, IconData icon, String label});

_Style _statusStyle(GuestTripStatus status) => switch (status) {
  GuestTripStatus.planned => (
    color: Palette.primary,
    background: Palette.primaryLight,
    icon: Icons.bookmark_outline_rounded,
    label: 'Planificado',
  ),
  GuestTripStatus.active => (
    color: Palette.estimated,
    background: Palette.estimatedBg,
    icon: Icons.directions_run_rounded,
    label: 'En curso',
  ),
  GuestTripStatus.completed => (
    color: Palette.confirmed,
    background: Palette.confirmedBg,
    icon: Icons.check_circle_outline_rounded,
    label: 'Completado',
  ),
  GuestTripStatus.abandoned => (
    color: Palette.inkMuted,
    background: Palette.surfaceAlt,
    icon: Icons.cancel_outlined,
    label: 'Abandonado',
  ),
};

({Color color, Color background, String label}) _certainty(String value) =>
    switch (value) {
      'confirmed' => (
        color: Palette.confirmed,
        background: Palette.confirmedBg,
        label: 'CONFIRMADO',
      ),
      'community' => (
        color: Palette.inferred,
        background: Palette.inferredBg,
        label: 'COMUNITARIO',
      ),
      _ => (
        color: Palette.estimated,
        background: Palette.estimatedBg,
        label: 'ESTIMADO',
      ),
    };

String _soles(int cents) => 'S/ ${(cents / 100).toStringAsFixed(2)}';

String _friendlyDate(DateTime utc) {
  final date = utc.toLocal();
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  final time = '${two(date.hour)}:${two(date.minute)}';
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Hoy · $time';
  if (diff == 1) return 'Ayer · $time';
  return '${two(date.day)}/${two(date.month)}/${date.year} · $time';
}

Color _legColor(String kind) => switch (kind) {
  'walk' => Palette.walk,
  'taxiBridge' => Palette.taxi,
  'board' || 'ride' => Palette.primary,
  _ => Palette.inkMuted,
};

IconData _legIcon(String kind) => switch (kind) {
  'walk' => Icons.directions_walk_rounded,
  'taxiBridge' => Icons.local_taxi_rounded,
  'board' => Icons.directions_bus_rounded,
  'ride' => Icons.route_rounded,
  _ => Icons.pin_drop_outlined,
};

String _legTitle(GuestTripLeg leg) => switch (leg.kind) {
  'walk' => 'Camina ~${leg.distanceMetres} m',
  'taxiBridge' =>
    'Taxi puente · S/ ${(leg.costCents / 100).toStringAsFixed(2)} estimados',
  'board' =>
    'Aborda ${leg.route ?? 'transporte'} · S/ ${(leg.costCents / 100).toStringAsFixed(2)}',
  'ride' => 'Viaja en ${leg.route ?? 'transporte'}',
  _ => 'Baja del transporte',
};
