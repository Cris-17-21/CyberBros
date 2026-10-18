import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/palette.dart';
import '../domain/stop_inference.dart';
import '../domain/trace_simulator.dart';

/// Laboratorio de paraderos de facto (RF-19): muestra cómo la app descubre
/// dónde la gente aborda de verdad y cómo se defiende de datos falsos. Todo lo
/// que se ve aquí es **simulado** y no se mezcla con datos reales.
class StopLabScreen extends StatefulWidget {
  const StopLabScreen({super.key});

  @override
  State<StopLabScreen> createState() => _StopLabScreenState();
}

class _StopLabScreenState extends State<StopLabScreen> {
  /// Paradero informal imaginario sobre una avenida de Lima.
  static const _spot = LatLng(-12.0896, -77.0305);
  static final _t0 = DateTime.utc(2026, 10, 18, 10);
  static final _now = DateTime.utc(2026, 10, 18, 12);

  late StopInferenceEngine _engine = _newEngine();
  List<InferredStop> _stops = const [];
  final Map<String, int> _discarded = {};
  String _lastAction = 'Elige una prueba para empezar.';
  bool _busy = false;

  static StopInferenceEngine _newEngine() => StopInferenceEngine(
    // La ruta conocida del bus: un auto cualquiera no cuenta como bus.
    routes: [TraceSimulator.straightRoute(_spot, 90)],
  );

  void _reset() => setState(() {
    _engine = _newEngine();
    _stops = const [];
    _discarded.clear();
    _lastAction = 'Laboratorio reiniciado.';
  });

  /// Ejecuta una prueba, cuenta los descartes y recalcula los paraderos.
  Future<void> _run(String title, void Function() ingest) async {
    if (_busy) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final logBefore = _engine.log.length;
    final eventsBefore = _engine.eventCount;
    ingest();
    for (final entry in _engine.log.skip(logBefore)) {
      if (entry.reason != 'quarantine' && entry.reason != 'invalidated') {
        _discarded[entry.reason] = (_discarded[entry.reason] ?? 0) + 1;
      }
    }
    final stops = _engine.inferStops(_now);
    if (!mounted) return;
    setState(() {
      _stops = stops;
      _busy = false;
      _lastAction =
          '$title → ${_engine.eventCount - eventsBefore} abordajes aceptados.';
    });
  }

  void _legitRiders() => _run('Personas reales', () {
    const offsets = [0, 3, 6, 40, 43];
    for (var i = 0; i < offsets.length; i++) {
      _engine.ingest(
        sessionId: 'persona-$i',
        sourceId: 'dispositivo-$i',
        isSimulated: true,
        pings: TraceSimulator.rider(
          stop: _spot,
          arrival: _t0.add(Duration(minutes: offsets[i])),
          approachBearingDeg: 30.0 * i + 100,
          approachFromMetres: 40.0 + 10 * i,
          waitSeconds: 60 + 9 * i,
          seed: 100 + i,
        ),
      );
    }
  });

  void _cartAttack() => _run('Ataque: carrito de 99 teléfonos', () {
    for (var i = 0; i < 99; i++) {
      _engine.ingest(
        sessionId: 'carrito-$i',
        sourceId: 'bot-carrito-$i',
        isSimulated: true,
        pings: TraceSimulator.cartWalker(start: _spot, from: _t0, seed: i),
      );
    }
  });

  void _cartCarAttack() => _run('Ataque: carrito + auto', () {
    for (var i = 0; i < 99; i++) {
      _engine.ingest(
        sessionId: 'auto-$i',
        sourceId: 'bot-auto-$i',
        isSimulated: true,
        pings: TraceSimulator.cartThenCar(spot: _spot, from: _t0, seed: i),
      );
    }
  });

  void _botsAttack() => _run('Ataque: 20 bots de una misma IP', () {
    for (var i = 0; i < 20; i++) {
      _engine.ingest(
        sessionId: 'bot-$i',
        sourceId: 'bot-misma-ip',
        isSimulated: true,
        pings: TraceSimulator.rider(
          stop: _spot,
          arrival: _t0.add(Duration(minutes: i * 3)),
          approachBearingDeg: 18.0 * i,
          approachFromMetres: 40 + i.toDouble(),
          seed: 300 + i,
        ),
      );
    }
  });

  void _revertBots() {
    final removed = _engine.invalidate(
      (event) => event.sourceId.startsWith('bot-'),
    );
    setState(() {
      _stops = _engine.inferStops(_now);
      _lastAction = 'Reversión: se invalidaron $removed abordajes de bots.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(title: const Text('Laboratorio de paraderos')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const _Intro(),
              const SizedBox(height: 14),
              _Plot(engine: _engine, stops: _stops, spot: _spot),
              const SizedBox(height: 8),
              Text(
                _lastAction,
                style: const TextStyle(
                  color: Palette.inkMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              const _Title('1 · Aporte legítimo'),
              const SizedBox(height: 8),
              _LabButton(
                icon: Icons.groups_rounded,
                label: '5 personas esperan y abordan (llegan escalonadas)',
                color: Palette.confirmed,
                onTap: _busy ? null : _legitRiders,
              ),
              const SizedBox(height: 14),
              const _Title('2 · Intentos de engañar al sistema'),
              const SizedBox(height: 8),
              _LabButton(
                icon: Icons.shopping_cart_outlined,
                label: 'Carrito: 99 teléfonos caminando juntos',
                color: Palette.taxi,
                onTap: _busy ? null : _cartAttack,
              ),
              const SizedBox(height: 8),
              _LabButton(
                icon: Icons.directions_car_filled_outlined,
                label: 'Carrito + auto: 99 teléfonos suben a un auto',
                color: Palette.taxi,
                onTap: _busy ? null : _cartCarAttack,
              ),
              const SizedBox(height: 8),
              _LabButton(
                icon: Icons.smart_toy_outlined,
                label: '20 bots de una misma IP, con llegadas escalonadas',
                color: Palette.taxi,
                onTap: _busy ? null : _botsAttack,
              ),
              const SizedBox(height: 14),
              const _Title('3 · Deshacer'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _revertBots,
                      icon: const Icon(Icons.undo_rounded),
                      label: const Text('Revertir lote de bots'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Reiniciar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _Title('Paraderos inferidos'),
              const SizedBox(height: 8),
              if (_stops.isEmpty)
                const _Empty()
              else
                for (final stop in _stops) _StopCard(stop: stop),
              if (_discarded.isNotEmpty) ...[
                const SizedBox(height: 18),
                const _Title('Datos descartados y por qué'),
                const SizedBox(height: 8),
                _DiscardedList(counts: _discarded),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- piezas

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Palette.inferredBg,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.science_outlined, color: Palette.inferred),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cómo descubrimos paraderos informales',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Palette.inferred,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Si varias personas esperan quietas en un punto y luego salen a velocidad de bus, ahí hay un paradero que no figura en el mapa. Se agrupan con DBSCAN y solo se publican si vienen de fuentes independientes, escalonadas y repetidas en el tiempo.',
          style: TextStyle(color: Palette.ink, height: 1.35, fontSize: 13.5),
        ),
        SizedBox(height: 8),
        Text(
          'SIMULADO: todo lo de esta pantalla es sintético y no mezcla datos de personas reales.',
          style: TextStyle(
            color: Palette.inferred,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: Palette.ink,
    ),
  );
}

class _LabButton extends StatelessWidget {
  const _LabButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Palette.surface,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.13),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Palette.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Palette.border),
    ),
    child: const Text(
      'Ninguno por ahora. Un paradero solo aparece cuando hay evidencia suficiente.',
      style: TextStyle(color: Palette.inkMuted),
    ),
  );
}

class _StopCard extends StatelessWidget {
  const _StopCard({required this.stop});

  final InferredStop stop;

  @override
  Widget build(BuildContext context) {
    final visible = stop.status == StopStatus.visible;
    final color = visible ? Palette.confirmed : Palette.estimated;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Chip(
                text: visible ? 'VISIBLE · inferido' : 'EN CUARENTENA',
                color: color,
              ),
              const SizedBox(width: 8),
              const _Chip(text: 'SIMULADO', color: Palette.inferred),
              const Spacer(),
              Text(
                '${(stop.confidence * 100).round()}% confianza',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${stop.effectiveSources} fuentes independientes de ${stop.rawEvents} abordajes',
            style: const TextStyle(fontWeight: FontWeight.w800, color: Palette.ink),
          ),
          const SizedBox(height: 2),
          Text(
            'Llegadas repartidas en ${stop.arrivalSpreadSeconds ~/ 60} min · ${stop.windows} ${stop.windows == 1 ? 'ventana' : 'ventanas'} de tiempo',
            style: const TextStyle(color: Palette.inkMuted, fontSize: 12.5),
          ),
          if (stop.blockers.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final blocker in stop.blockers)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.block_rounded,
                      size: 14,
                      color: Palette.estimated,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        blocker,
                        style: const TextStyle(
                          color: Palette.estimated,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _DiscardedList extends StatelessWidget {
  const _DiscardedList({required this.counts});

  final Map<String, int> counts;

  static const _labels = {
    'walkingMovement': 'Movimiento peatonal sostenido (nube que camina)',
    'noDwell': 'No esperó lo suficiente en un punto',
    'noVehicleSpeed': 'Esperó pero no subió a un vehículo',
    'offRoute': 'El vehículo no siguió ninguna ruta de bus',
    'impossibleSpeed': 'Velocidad o salto de posición imposible',
    'constantAccuracy': 'Precisión perfecta y constante (señal de bot)',
    'outOfOrder': 'Marcas de tiempo fuera de orden',
    'tooFewPings': 'Pocos pings fiables',
    'nearOfficialStop': 'Junto a un paradero oficial',
    'duplicateToday': 'Repetido el mismo día en el mismo punto',
    'blockedSource': 'Fuente bloqueada',
  };

  @override
  Widget build(BuildContext context) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.border),
      ),
      child: Column(
        children: [
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${entry.value}×',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Palette.ink,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _labels[entry.key] ?? entry.key,
                      style: const TextStyle(color: Palette.inkMuted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Diagrama de dispersión: abordajes aceptados y paraderos inferidos.
class _Plot extends StatelessWidget {
  const _Plot({required this.engine, required this.stops, required this.spot});

  final StopInferenceEngine engine;
  final List<InferredStop> stops;
  final LatLng spot;

  @override
  Widget build(BuildContext context) => Container(
    height: 220,
    decoration: BoxDecoration(
      color: Palette.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Palette.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: CustomPaint(
      painter: _PlotPainter(
        events: engine.eventPoints,
        stops: stops,
        origin: spot,
      ),
      child: const Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Text(
            'Vista en planta (±120 m) · SIMULADO',
            style: TextStyle(
              color: Palette.inkMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

class _PlotPainter extends CustomPainter {
  _PlotPainter({
    required this.events,
    required this.stops,
    required this.origin,
  });

  final List<LatLng> events;
  final List<InferredStop> stops;
  final LatLng origin;

  static const _halfSpanMetres = 120.0;

  Offset _toCanvas(LatLng p, Size size) {
    final cosLat = math.cos(origin.latitude * math.pi / 180);
    final x = (p.longitude - origin.longitude) * cosLat * 111320;
    final y = (p.latitude - origin.latitude) * 110540;
    final scale = size.shortestSide / (2 * _halfSpanMetres);
    return Offset(size.width / 2 + x * scale, size.height / 2 - y * scale);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 4),
        Offset(size.width, size.height * i / 4),
        grid,
      );
      canvas.drawLine(
        Offset(size.width * i / 4, 0),
        Offset(size.width * i / 4, size.height),
        grid,
      );
    }
    // Ruta del bus (hacia el este).
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = Palette.primary.withValues(alpha: 0.35)
        ..strokeWidth = 5,
    );
    final dot = Paint()..color = Palette.inkMuted.withValues(alpha: 0.55);
    for (final point in events) {
      canvas.drawCircle(_toCanvas(point, size), 2.5, dot);
    }
    for (final stop in stops) {
      final visible = stop.status == StopStatus.visible;
      final color = visible ? Palette.confirmed : Palette.estimated;
      final center = _toCanvas(stop.center, size);
      canvas.drawCircle(
        center,
        16,
        Paint()..color = color.withValues(alpha: 0.15),
      );
      canvas.drawCircle(
        center,
        16,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      canvas.drawCircle(center, 5, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _PlotPainter old) =>
      old.events.length != events.length || old.stops != stops;
}
