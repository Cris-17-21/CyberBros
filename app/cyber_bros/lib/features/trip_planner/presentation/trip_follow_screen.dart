import 'package:flutter/material.dart';
import '../../../core/theme/palette.dart';
import '../data/guest_history.dart';
import 'widgets/journey_map_leg.dart';
import 'widgets/lima_map.dart';

/// Live interactive navigation screen inspired by inDrive / Google Maps.
class TripFollowScreen extends StatefulWidget {
  const TripFollowScreen({
    super.key,
    required this.trip,
    this.journeyLegs = const [],
  });

  final GuestTripSnapshot trip;
  final List<JourneyMapLeg> journeyLegs;

  @override
  State<TripFollowScreen> createState() => _TripFollowScreenState();
}

class _TripFollowScreenState extends State<TripFollowScreen> {
  late GuestTripSnapshot _trip = widget.trip;
  int _stage = 0;
  bool _busy = false;

  List<GuestTripLeg> get _stages => _trip.legs
      .where((leg) => leg.kind != 'alight' && leg.kind != 'board')
      .toList();

  Future<void> _saveStatus(GuestTripStatus status) async {
    if (_busy) return;
    setState(() => _busy = true);
    final updated = _trip.withStatus(status);
    final persisted = await GuestHistoryRepository.instance.save(updated);
    if (!mounted) return;
    setState(() {
      _trip = updated;
      _busy = false;
    });
    if (!persisted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El cambio solo estará disponible durante esta visita.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stages = _stages;
    final done = _trip.status == GuestTripStatus.completed;
    final current = stages.isEmpty
        ? null
        : stages[_stage.clamp(0, stages.length - 1)];

    return Scaffold(
      backgroundColor: Palette.background,
      body: Stack(
        children: [
          // 1. Mapa interactivo en vivo a pantalla completa
          Positioned.fill(
            child: LimaMap(
              height: double.infinity,
              borderRadius: 0,
              journeyLegs: widget.journeyLegs,
              originPoint: widget.journeyLegs.isNotEmpty
                  ? widget.journeyLegs.first.from
                  : null,
              destinationPoint: widget.journeyLegs.isNotEmpty
                  ? widget.journeyLegs.last.to
                  : null,
            ),
          ),

          // 2. Cabecera superior flotante estilo Google Maps con la indicación del tramo actual
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Palette.ink),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Palette.primaryDark,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            current != null ? _icon(current.kind) : Icons.navigation_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  done
                                      ? '¡Llegaste a tu destino!'
                                      : (current != null ? _label(current) : 'En camino'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (current != null && !done)
                                  Text(
                                    'Hacia: ${current.to}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Hoja inferior flotante con el estado y avance de etapa
          Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (done) ...[
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Palette.confirmed, size: 28),
                          SizedBox(width: 10),
                          Text(
                            'Viaje Completado',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Palette.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Completaste el recorrido de ${_trip.originLabel} a ${_trip.destinationLabel}.',
                        style: const TextStyle(color: Palette.inkMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: Palette.primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Volver al inicio', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ] else if (current != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Paso ${_stage + 1} de ${stages.length}',
                            style: const TextStyle(
                              color: Palette.primaryDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '~${current.durationMinutes} min · ${current.distanceMetres} m',
                            style: const TextStyle(
                              color: Palette.inkMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${current.from} → ${current.to}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Palette.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () async {
                                if (_trip.status != GuestTripStatus.active) {
                                  await _saveStatus(GuestTripStatus.active);
                                } else if (_stage + 1 < stages.length) {
                                  setState(() => _stage++);
                                } else {
                                  await _saveStatus(GuestTripStatus.completed);
                                }
                              },
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(
                          _trip.status != GuestTripStatus.active
                              ? 'Iniciar navegación'
                              : _stage + 1 < stages.length
                              ? 'Siguiente paso'
                              : 'Finalizar viaje',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Palette.primaryDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: _busy || _trip.status != GuestTripStatus.active
                            ? null
                            : () => _saveStatus(GuestTripStatus.abandoned),
                        child: const Text(
                          'Cancelar viaje',
                          style: TextStyle(color: Palette.inkMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _icon(String kind) => switch (kind) {
  'walk' => Icons.directions_walk_rounded,
  'ride' => Icons.directions_bus_rounded,
  'taxiBridge' => Icons.local_taxi_rounded,
  _ => Icons.route_rounded,
};

String _label(GuestTripLeg leg) => switch (leg.kind) {
  'walk' => 'Camina ${leg.distanceMetres} m',
  'ride' => 'Toma el corredor o bus',
  'taxiBridge' => 'Tramo en taxi / colectivo',
  _ => 'Sigue la ruta indicada',
};
