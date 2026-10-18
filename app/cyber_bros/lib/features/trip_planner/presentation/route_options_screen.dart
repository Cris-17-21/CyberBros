import 'package:flutter/material.dart';

import '../../../core/theme/palette.dart';
import 'map_screen.dart';
import 'route_detail_screen.dart';

class RouteOptionsScreen extends StatelessWidget {
  const RouteOptionsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.budget,
    required this.isDemo,
    required this.maxContinuousWalkMetres,
    required this.maxTotalWalkMetres,
    required this.allowTaxi,
  });

  final String origin;
  final String destination;
  final double budget;
  final bool isDemo;
  final int maxContinuousWalkMetres;
  final int maxTotalWalkMetres;
  final bool allowTaxi;

  static const _routes = [
    _RouteData(
      title: 'MENOS CAMINATA',
      price: 8.5,
      maxContinuousWalkMetres: 150,
      totalWalkMetres: 250,
      usesTaxi: true,
      initialWalkMetres: 150,
      finalWalkMetres: 100,
      taxiFare: 6,
      walking: '250 m a pie',
      duration: '32 min',
      transfers: '1 transbordo',
      firstLeg: '150 m',
      transit: 'Corredor Azul',
      lastLeg: 'Taxi puente',
      status: 'Recomendada',
      color: Palette.primary,
    ),
    _RouteData(
      title: 'MÁS BARATA',
      price: 5,
      maxContinuousWalkMetres: 450,
      totalWalkMetres: 850,
      usesTaxi: false,
      initialWalkMetres: 400,
      finalWalkMetres: 450,
      taxiFare: 0,
      walking: '850 m a pie',
      duration: '45 min',
      transfers: '2 transbordos',
      firstLeg: '400 m',
      transit: 'Convencional',
      lastLeg: '450 m',
      status: 'Simulado',
      color: Palette.confirmed,
    ),
    _RouteData(
      title: 'EQUILIBRADA',
      price: 6.5,
      maxContinuousWalkMetres: 220,
      totalWalkMetres: 420,
      usesTaxi: false,
      initialWalkMetres: 220,
      finalWalkMetres: 200,
      taxiFare: 0,
      walking: '420 m a pie',
      duration: '38 min',
      transfers: '1 transbordo',
      firstLeg: '220 m',
      transit: 'Metropolitano',
      lastLeg: '200 m',
      status: 'Estimado',
      color: Palette.estimated,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!isDemo) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sin rutas verificadas')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.route_outlined,
                    size: 48,
                    color: Palette.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aún no podemos calcular este viaje',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Los trazos publicados por la ATU todavía no incluyen paraderos ordenados, tarifas ni horarios. No sería seguro presentar opciones para esta ruta como si estuvieran verificadas.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cambiar condiciones'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final availableRoutes = _routes
        .where(
          (route) =>
              route.price <= budget &&
              route.maxContinuousWalkMetres <= maxContinuousWalkMetres &&
              route.totalWalkMetres <= maxTotalWalkMetres &&
              (allowTaxi || !route.usesTaxi),
        )
        .toList();
    final selectedFare = availableRoutes.firstOrNull?.price;
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Opciones',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Palette.primary,
              child: IconButton(
                tooltip: 'Cuenta',
                onPressed: () {},
                icon: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${availableRoutes.length} ${availableRoutes.length == 1 ? 'opción' : 'opciones'} de ejemplo',
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  color: Palette.ink,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Presupuesto fijado en S/ ${budget.toStringAsFixed(2)}',
                                style: const TextStyle(color: Palette.inkMuted),
                              ),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Ver el mapa',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const MapScreen(showDemoRoute: true),
                                ),
                              ),
                              icon: const Icon(Icons.map_outlined),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.tune_rounded, size: 18),
                              label: const Text('Ajustar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Palette.simulatedBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.science_outlined, color: Palette.inkMuted),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'MODO DEMO · Estas rutas y tarifas son ejemplos, no las uses para viajar.',
                              style: TextStyle(color: Palette.inkMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (availableRoutes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Text(
                          'Ninguna opción de demostración cumple tus límites. Ajusta presupuesto o caminata para explorar el ejemplo.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    for (var i = 0; i < availableRoutes.length; i++)
                      _RouteOptionCard(
                        data: availableRoutes[i],
                        selected: i == 0,
                        onTap: () => _openDetail(context, availableRoutes[i]),
                      ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        '◉  Valores de demostración · rutas y tarifas por verificar',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Palette.inkMuted, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              if (selectedFare != null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: FilledButton.icon(
                      onPressed: () =>
                          _openDetail(context, availableRoutes.first),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        'Elegir esta opción (S/ ${selectedFare.toStringAsFixed(2)})',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        backgroundColor: Palette.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, _RouteData route) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RouteDetailScreen(
          origin: origin,
          destination: destination,
          title: route.title,
          fare: route.price,
          budget: budget,
          transit: route.transit,
          duration: route.duration,
          initialWalkMetres: route.initialWalkMetres,
          finalWalkMetres: route.finalWalkMetres,
          taxiFare: route.taxiFare,
        ),
      ),
    );
  }
}

class _RouteData {
  const _RouteData({
    required this.title,
    required this.price,
    required this.maxContinuousWalkMetres,
    required this.totalWalkMetres,
    required this.usesTaxi,
    required this.initialWalkMetres,
    required this.finalWalkMetres,
    required this.taxiFare,
    required this.walking,
    required this.duration,
    required this.transfers,
    required this.firstLeg,
    required this.transit,
    required this.lastLeg,
    required this.status,
    required this.color,
  });

  final String title;
  final double price;
  final int maxContinuousWalkMetres;
  final int totalWalkMetres;
  final bool usesTaxi;
  final int initialWalkMetres;
  final int finalWalkMetres;
  final double taxiFare;
  final String walking;
  final String duration;
  final String transfers;
  final String firstLeg;
  final String transit;
  final String lastLeg;
  final String status;
  final Color color;
}

class _RouteOptionCard extends StatelessWidget {
  const _RouteOptionCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _RouteData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? Palette.primaryDark : Colors.transparent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.title,
                      style: TextStyle(
                        color: data.color,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .4,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: const BoxDecoration(
                        color: Palette.primaryDark,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          topRight: Radius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '✓  SELECCIONADA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Text(
                      data.status,
                      style: const TextStyle(
                        color: Palette.inkMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'S/ ${data.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Palette.ink,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const Spacer(),
                  _StatusPill(label: data.status, color: data.color),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _Metric(
                    icon: Icons.directions_walk_rounded,
                    label: data.walking,
                  ),
                  _Metric(icon: Icons.schedule_rounded, label: data.duration),
                  _Metric(
                    icon: Icons.compare_arrows_rounded,
                    label: data.transfers,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 7,
                runSpacing: 7,
                children: [
                  _LegChip(
                    text: data.firstLeg,
                    icon: Icons.directions_walk_rounded,
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: Palette.inkMuted,
                  ),
                  _LegChip(
                    text: data.transit,
                    icon: Icons.directions_bus_rounded,
                    blue: true,
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: Palette.inkMuted,
                  ),
                  _LegChip(
                    text: data.lastLeg,
                    icon: data.lastLeg.contains('Taxi')
                        ? Icons.local_taxi_rounded
                        : Icons.directions_walk_rounded,
                    red: data.lastLeg.contains('Taxi'),
                  ),
                ],
              ),
              if (selected) ...[
                const SizedBox(height: 10),
                Text(
                  'Caminarías ${data.totalWalkMetres} m en total; el tramo más largo sería de ${data.maxContinuousWalkMetres} m.${data.usesTaxi ? ' Incluye taxi puente.' : ''}',
                  style: const TextStyle(color: Palette.inkMuted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Palette.inkMuted),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: Palette.ink)),
    ],
  );
}

class _LegChip extends StatelessWidget {
  const _LegChip({
    required this.text,
    required this.icon,
    this.blue = false,
    this.red = false,
  });
  final String text;
  final IconData icon;
  final bool blue;
  final bool red;

  @override
  Widget build(BuildContext context) {
    final bg = blue
        ? const Color(0xFFD8E7FF)
        : red
        ? const Color(0xFFFCE0D9)
        : Palette.surfaceAlt;
    final fg = blue
        ? Palette.primaryDark
        : red
        ? Palette.taxi
        : Palette.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
