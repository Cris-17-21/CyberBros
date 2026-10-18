import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/palette.dart';
import '../data/guest_history.dart';
import '../data/shared_taxi_store.dart';
import 'planner_home_screen.dart';
import 'shared_taxi_screen.dart';
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
  final _mapController = MapController();
  int _stage = 0;
  bool _busy = false;

  // Seguimiento interactivo con flecha en movimiento y GPS
  Timer? _animTimer;
  StreamSubscription<Position>? _gpsSubscription;
  bool _isUsingGps = false;
  LatLng? _currentNavPoint;
  double _currentBearing = 0.0;
  int _animPointIndex = 0;
  List<LatLng> _currentLegPoints = [];

  List<GuestTripLeg> get _stages => _trip.legs
      .where((leg) => leg.kind != 'alight' && leg.kind != 'board')
      .toList();

  @override
  void initState() {
    super.initState();
    _setupStageNavigation();
    if (_trip.status == GuestTripStatus.active) {
      _startGpsTracking();
      _notifyTripStarted();
    }
  }

  /// Datos del tramo de taxi actual para ofrecer compartirlo.
  SharedTaxiRequest? _taxiRequestFor(GuestTripLeg leg) {
    if (leg.kind != 'taxiBridge') return null;
    final mapLeg = widget.journeyLegs
        .where((item) => item.kind == JourneyLegKind.taxi)
        .firstOrNull;
    if (mapLeg == null) return null;
    return SharedTaxiRequest(
      fromLabel: leg.from,
      toLabel: leg.to,
      from: mapLeg.from,
      to: mapLeg.to,
      taxiCents: leg.costCents,
      distanceMetres: leg.distanceMetres,
    );
  }

  // ------------------------------------------------------- notificaciones

  String _instructionFor(int stage) {
    final stages = _stages;
    if (stages.isEmpty) return 'Sigue la ruta indicada';
    final leg = stages[stage.clamp(0, stages.length - 1)];
    return '${_label(leg)} hasta ${leg.to}';
  }

  void _notifyTripStarted() {
    unawaited(
      NotificationService.instance.tripStarted(
        tripId: _trip.id,
        destination: _trip.destinationLabel,
        stages: _stages.length,
        instruction: _instructionFor(_stage),
      ),
    );
  }

  void _notifyStatus(GuestTripStatus status) {
    final service = NotificationService.instance;
    switch (status) {
      case GuestTripStatus.active:
        _notifyTripStarted();
      case GuestTripStatus.completed:
        unawaited(
          service.arrived(
            tripId: _trip.id,
            destination: _trip.destinationLabel,
          ),
        );
      case GuestTripStatus.abandoned:
        unawaited(
          service.tripAbandoned(
            tripId: _trip.id,
            destination: _trip.destinationLabel,
          ),
        );
      case GuestTripStatus.planned:
        break;
    }
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    _gpsSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _setupStageNavigation() {
    _animTimer?.cancel();
    final stages = _stages;
    if (stages.isEmpty || _stage >= stages.length) return;

    // Obtener los puntos del tramo actual
    if (widget.journeyLegs.isNotEmpty && _stage < widget.journeyLegs.length) {
      final leg = widget.journeyLegs[_stage];
      _currentLegPoints = (leg.points != null && leg.points!.isNotEmpty)
          ? leg.points!
          : [leg.from, leg.to];
    } else {
      _currentLegPoints = [];
    }

    if (_currentLegPoints.isNotEmpty) {
      _currentNavPoint = _currentLegPoints.first;
      _animPointIndex = 0;
      if (_currentLegPoints.length > 1) {
        _currentBearing = _calculateBearing(
          _currentLegPoints[0],
          _currentLegPoints[1],
        );
      }
      try {
        _mapController.move(_currentNavPoint!, 16.5);
      } catch (_) {}
    }

    // Si el viaje está activo, asegurar que el seguimiento esté corriendo
    if (_trip.status == GuestTripStatus.active) {
      if (!_isUsingGps) {
        _startGpsTracking();
      }
    }
  }

  /// Inicia la navegación GPS en vivo con Geolocator
  Future<void> _startGpsTracking() async {
    _animTimer?.cancel();
    _gpsSubscription?.cancel();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _startSimulatedProgression();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _startSimulatedProgression();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _startSimulatedProgression();
        return;
      }

      _isUsingGps = true;

      // Obtener posición inmediata para centrar mapa
      Position? currentPos;
      try {
        currentPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 4),
          ),
        );
      } catch (_) {
        currentPos = null;
      }

      if (currentPos != null && mounted) {
        _onGpsPosition(currentPos);
      }

      // Escuchar stream en vivo de alta precisión (cada 2 metros)
      _gpsSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
        ),
      ).listen(
        (Position position) {
          if (!mounted) return;
          _onGpsPosition(position);
        },
        onError: (_) {
          _isUsingGps = false;
          _startSimulatedProgression();
        },
      );
    } catch (_) {
      _isUsingGps = false;
      _startSimulatedProgression();
    }
  }

  void _onGpsPosition(Position position) {
    final newPoint = LatLng(position.latitude, position.longitude);
    final prevPoint = _currentNavPoint;

    double bearing = _currentBearing;
    if (position.heading > 0) {
      bearing = position.heading * (math.pi / 180.0);
    } else if (prevPoint != null) {
      final dist = const Distance().as(LengthUnit.Meter, prevPoint, newPoint);
      if (dist >= 2) {
        bearing = _calculateBearing(prevPoint, newPoint);
      }
    }

    setState(() {
      _currentNavPoint = newPoint;
      _currentBearing = bearing;
    });

    try {
      _mapController.move(newPoint, 17.0);
    } catch (_) {}

    // Si el usuario llega a menos de 25m del final del tramo actual, avanzar de paso automáticamente
    if (_currentLegPoints.isNotEmpty) {
      final target = _currentLegPoints.last;
      final distanceToEnd = const Distance().as(
        LengthUnit.Meter,
        newPoint,
        target,
      );
      // Aviso de cercanía antes de llegar al final del tramo.
      if (distanceToEnd > 25 && distanceToEnd <= 120 && _stages.isNotEmpty) {
        final leg = _stages[_stage.clamp(0, _stages.length - 1)];
        unawaited(
          NotificationService.instance.nearStop(stage: _stage, place: leg.to),
        );
      }
      if (distanceToEnd <= 25) {
        if (_stage + 1 < _stages.length) {
          _nextStep();
        } else {
          _saveStatus(GuestTripStatus.completed);
        }
      }
    }
  }

  void _startSimulatedProgression() {
    _animTimer?.cancel();
    _animTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (!mounted) return;
      if (_animPointIndex + 1 < _currentLegPoints.length) {
        setState(() {
          _animPointIndex++;
          final prev = _currentNavPoint ?? _currentLegPoints[_animPointIndex - 1];
          _currentNavPoint = _currentLegPoints[_animPointIndex];
          _currentBearing = _calculateBearing(prev, _currentNavPoint!);
        });
        try {
          _mapController.move(_currentNavPoint!, 16.8);
        } catch (_) {}
      } else {
        timer.cancel();
        // Si completó automáticamente todos los puntos del tramo, avanzar al siguiente paso
        if (_stage + 1 < _stages.length) {
          _nextStep();
        } else {
          _saveStatus(GuestTripStatus.completed);
        }
      }
    });
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * (math.pi / 180.0);
    final startLng = start.longitude * (math.pi / 180.0);
    final endLat = end.latitude * (math.pi / 180.0);
    final endLng = end.longitude * (math.pi / 180.0);

    final dLng = endLng - startLng;
    final y = math.sin(dLng) * math.cos(endLat);
    final x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);

    return math.atan2(y, x);
  }

  void _nextStep() {
    if (_stage + 1 < _stages.length) {
      setState(() {
        _stage++;
      });
      _setupStageNavigation();
      unawaited(
        NotificationService.instance.stageChanged(
          destination: _trip.destinationLabel,
          stage: _stage,
          stages: _stages.length,
          instruction: _instructionFor(_stage),
        ),
      );
    } else {
      _saveStatus(GuestTripStatus.completed);
    }
  }

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
    _notifyStatus(status);
    if (!persisted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El cambio solo estará disponible durante esta visita.'),
        ),
      );
    }
  }

  /// Regresa directamente a la pantalla de inicio descartando el flujo de búsqueda previo
  void _returnHome() {
    _animTimer?.cancel();
    _gpsSubscription?.cancel();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const PlannerHomeScreen()),
      (route) => false,
    );
  }

  /// Cancela el viaje y regresa a la pantalla principal
  Future<void> _cancelTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Cancelar viaje?'),
        content: const Text(
          '¿Estás seguro de que deseas cancelar este recorrido y volver al inicio?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar viaje'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Palette.taxi),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _animTimer?.cancel();
      _gpsSubscription?.cancel();
      await _saveStatus(GuestTripStatus.abandoned);
      if (mounted) {
        _returnHome();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stages = _stages;
    final done = _trip.status == GuestTripStatus.completed;
    final current = stages.isEmpty
        ? null
        : stages[_stage.clamp(0, stages.length - 1)];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_trip.status == GuestTripStatus.active) {
          _cancelTrip();
        } else {
          _returnHome();
        }
      },
      child: Scaffold(
        backgroundColor: Palette.background,
        body: Stack(
          children: [
            // 1. Mapa interactivo en vivo con seguimiento de cámara y flecha en movimiento
            Positioned.fill(
              child: LimaMap(
                height: double.infinity,
                borderRadius: 0,
                mapController: _mapController,
                journeyLegs: widget.journeyLegs,
                navigationPoint: _currentNavPoint,
                navigationBearing: _currentBearing,
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
                        onPressed: () {
                          if (_trip.status == GuestTripStatus.active) {
                            _cancelTrip();
                          } else {
                            _returnHome();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Palette.primaryDark, Palette.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Palette.primary.withValues(alpha: 0.28),
                            blurRadius: 18,
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
                        onPressed: _returnHome,
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
                      if (_taxiRequestFor(current) != null) ...[
                        const SizedBox(height: 12),
                        SharedTaxiEntryCard(request: _taxiRequestFor(current)!),
                      ],
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () async {
                                if (_trip.status != GuestTripStatus.active) {
                                  await _saveStatus(GuestTripStatus.active);
                                  _startGpsTracking();
                                } else if (_stage + 1 < stages.length) {
                                  _nextStep();
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
                          backgroundColor: Palette.primary,
                          elevation: 3,
                          shadowColor: Palette.primary.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: _busy ? null : _cancelTrip,
                        child: const Text(
                          'Cancelar viaje',
                          style: TextStyle(color: Palette.taxi, fontSize: 13, fontWeight: FontWeight.w600),
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
