import 'package:flutter/material.dart';

import '../../../core/theme/palette.dart';
import '../data/guest_history.dart';
import '../data/osm_stops.dart';
import '../domain/routing_engine.dart';
import 'trip_conditions_screen.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  late Future<List<GuestTripSnapshot>> _trips = GuestHistoryRepository.instance
      .list();

  void _refresh() =>
      setState(() => _trips = GuestHistoryRepository.instance.list());

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Palette.background,
    appBar: AppBar(title: const Text('Mis viajes')),
    body: FutureBuilder<List<GuestTripSnapshot>>(
      future: _trips,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('No se pudo leer el historial local.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final trips = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Historial de este dispositivo',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Se conserva localmente hasta 30 días. No está sincronizado con una cuenta ni guarda trazas GPS.',
                  style: TextStyle(color: Palette.inkMuted),
                ),
                if (!GuestHistoryRepository.instance.storageAvailable) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'El almacenamiento está bloqueado. Los viajes solo estarán disponibles durante esta visita.',
                    style: TextStyle(color: Palette.estimated),
                  ),
                ],
                const SizedBox(height: 20),
                if (trips.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.route_outlined,
                            size: 40,
                            color: Palette.primary,
                          ),
                          const SizedBox(height: 10),
                          const Text('Aún no tienes viajes guardados.'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Planificar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                for (final trip in trips)
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      title: Text(
                        '${trip.originLabel} → ${trip.destinationLabel}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${_date(trip.createdAtUtc)} · ${trip.alternativeLabel} · ${_status(trip.status)}\n'
                          'S/ ${(trip.costCents / 100).toStringAsFixed(2)} estimados · ${trip.walkMetres} m a pie',
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
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
        );
      },
    ),
  );
}

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
        content: const Text(
          'Se borrará del historial local de este dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await GuestHistoryRepository.instance.delete(_trip.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Palette.background,
    appBar: AppBar(title: const Text('Viaje guardado')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${_trip.originLabel} → ${_trip.destinationLabel}',
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_date(_trip.createdAtUtc)} · ${_status(_trip.status)}',
              style: const TextStyle(color: Palette.inkMuted),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _trip.alternativeLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'S/ ${(_trip.costCents / 100).toStringAsFixed(2)} estimados · ${_trip.walkMetres} m · ~${_trip.durationMinutes} min',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Versión de datos: ${_trip.dataVersion}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Palette.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Recorrido guardado',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            for (final leg in _trip.legs)
              Card(
                child: ListTile(
                  leading: Icon(_legIcon(leg.kind), color: Palette.primaryDark),
                  title: Text(_legTitle(leg)),
                  subtitle: Text(
                    '${leg.from} → ${leg.to}\n${leg.certainty} · ${leg.source}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _busy ? null : _repeat,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Repetir con datos actuales'),
            ),
            const SizedBox(height: 8),
            if (_trip.status == GuestTripStatus.planned)
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _updateStatus(GuestTripStatus.active),
                child: const Text('Marcar viaje iniciado'),
              ),
            if (_trip.status == GuestTripStatus.active) ...[
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _updateStatus(GuestTripStatus.completed),
                child: const Text('Marcar completado'),
              ),
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () => _updateStatus(GuestTripStatus.abandoned),
                child: const Text('Marcar abandonado'),
              ),
            ],
            TextButton.icon(
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Eliminar viaje'),
            ),
            const Text(
              'Historial local de invitado. Los estados se registran manualmente; no prueban que el servicio operó.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.inkMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

String _date(DateTime utc) {
  final date = utc.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
}

String _status(GuestTripStatus status) => switch (status) {
  GuestTripStatus.planned => 'Planificado',
  GuestTripStatus.active => 'En curso (manual)',
  GuestTripStatus.completed => 'Completado (manual)',
  GuestTripStatus.abandoned => 'Abandonado (manual)',
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
