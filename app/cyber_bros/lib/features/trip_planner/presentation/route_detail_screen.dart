import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/palette.dart';

class RouteDetailScreen extends StatelessWidget {
  const RouteDetailScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.title,
    required this.fare,
    required this.budget,
    required this.transit,
    required this.duration,
    required this.initialWalkMetres,
    required this.finalWalkMetres,
    required this.taxiFare,
  });

  final String origin;
  final String destination;
  final String title;
  final double fare;
  final double budget;
  final String transit;
  final String duration;
  final int initialWalkMetres;
  final int finalWalkMetres;
  final double taxiFare;

  @override
  Widget build(BuildContext context) {
    final transitFare = fare - taxiFare;
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Recorrido de ejemplo',
          style: TextStyle(fontFamily: 'Georgia', fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Palette.primaryDark,
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          _CostSummary(
            fare: fare,
            budget: budget,
            transitFare: transitFare,
            taxiFare: taxiFare,
          ),
          const SizedBox(height: 16),
          _ItineraryCard(
            origin: origin,
            destination: destination,
            transitFare: transitFare,
            taxiFare: taxiFare,
            transit: transit,
            duration: duration,
            initialWalkMetres: initialWalkMetres,
            finalWalkMetres: finalWalkMetres,
          ),
          const SizedBox(height: 16),
          if (taxiFare > 0)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4DE),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Palette.taxi,
                        size: 24,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Taxi puente: el precio es estimado. Confírmalo en tu app de taxi antes de iniciar.',
                          style: TextStyle(
                            color: Palette.taxi,
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => _showCopiedNotice(context),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copiar destino para app de taxi'),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Palette.taxi,
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide.none,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          const Text(
            'DEMO · Este recorrido no está verificado para viajar. Las distancias, los tiempos y las tarifas son ilustrativos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Palette.inkMuted),
          ),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Elegir otra alternativa',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Alternativa seleccionada: $title · recorrido ilustrativo',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.inkMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Future<void> _showCopiedNotice(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: destination));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Destino copiado: $destination')));
  }
}

class _CostSummary extends StatelessWidget {
  const _CostSummary({
    required this.fare,
    required this.budget,
    required this.transitFare,
    required this.taxiFare,
  });

  final double fare;
  final double budget;
  final double transitFare;
  final double taxiFare;

  @override
  Widget build(BuildContext context) {
    final remaining = (budget - fare).clamp(0, budget).toDouble();
    final percent = budget <= 0 ? 0 : (fare / budget * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'COSTO PROYECTADO',
                  style: TextStyle(
                    color: Palette.inkMuted,
                    letterSpacing: 1,
                    fontSize: 12,
                  ),
                ),
              ),
              _Badge(
                icon: Icons.warning_amber_rounded,
                text: 'Estimado',
                color: Palette.estimated,
                bg: Palette.estimatedBg,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Gastarás ~S/ ${fare.toStringAsFixed(2)}',
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontWeight: FontWeight.w700,
              fontSize: 26,
              color: Palette.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Te quedarán ~S/ ${remaining.toStringAsFixed(2)} de tus S/ ${budget.toStringAsFixed(2)} presupuestados',
            style: const TextStyle(fontSize: 13, color: Palette.ink),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Expanded(
                  flex: (transitFare * 10).round().clamp(1, 100),
                  child: Container(height: 9, color: Palette.primaryDark),
                ),
                if (taxiFare > 0)
                  Expanded(
                    flex: (taxiFare * 10).round().clamp(1, 100),
                    child: Container(height: 9, color: Palette.taxi),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Palette.primaryDark),
              const SizedBox(width: 5),
              Text(
                'Transporte S/ ${transitFare.toStringAsFixed(2)}',
                style: const TextStyle(color: Palette.inkMuted, fontSize: 12),
              ),
              const SizedBox(width: 12),
              if (taxiFare > 0) ...[
                const Icon(Icons.circle, size: 10, color: Palette.taxi),
                const SizedBox(width: 5),
                Text(
                  'Taxi S/ ${taxiFare.toStringAsFixed(2)}',
                  style: const TextStyle(color: Palette.inkMuted, fontSize: 12),
                ),
              ],
              const Spacer(),
              Text(
                '$percent% del presupuesto',
                style: const TextStyle(
                  color: Palette.estimated,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItineraryCard extends StatelessWidget {
  const _ItineraryCard({
    required this.origin,
    required this.destination,
    required this.transitFare,
    required this.taxiFare,
    required this.transit,
    required this.duration,
    required this.initialWalkMetres,
    required this.finalWalkMetres,
  });

  final String origin;
  final String destination;
  final double transitFare;
  final double taxiFare;
  final String transit;
  final String duration;
  final int initialWalkMetres;
  final int finalWalkMetres;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Hoja de ruta',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$duration totales',
                style: const TextStyle(color: Palette.inkMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TimelineStop(
            icon: Icons.my_location_rounded,
            color: Palette.inkMuted,
            title: origin,
            subtitle: 'Punto de salida de ejemplo',
            detail: 'Camina $initialWalkMetres m hasta el transporte',
            detailColor: Palette.surfaceAlt,
            status: 'Estimado',
          ),
          _TimelineStop(
            icon: Icons.directions_bus_rounded,
            color: Palette.primaryDark,
            title: transit,
            subtitle: 'Punto de abordaje ilustrativo',
            detail: 'Trayecto en $transit · duración de ejemplo',
            detailColor: Palette.surfaceAlt,
            status: 'S/ ${transitFare.toStringAsFixed(2)}',
            connectorColor: Palette.primary,
          ),
          if (taxiFare > 0)
            _TimelineStop(
              icon: Icons.local_taxi_rounded,
              color: Palette.taxi,
              title: 'Taxi puente de ejemplo',
              subtitle: 'Punto de transbordo ilustrativo',
              detail: 'Traslado estimado hasta cercanías del destino',
              detailColor: const Color(0xFFFCE4DE),
              status: 'S/ ${taxiFare.toStringAsFixed(2)}',
              connectorColor: Palette.taxi,
            ),
          _TimelineStop(
            icon: Icons.flag_rounded,
            color: Palette.ink,
            title: '⚑ $destination',
            subtitle: 'Destino final',
            detail: 'Camina $finalWalkMetres m hasta el destino',
            detailColor: Palette.surfaceAlt,
            status: 'Gratis',
            showConnector: false,
          ),
        ],
      ),
    );
  }
}

class _TimelineStop extends StatelessWidget {
  const _TimelineStop({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.detailColor,
    required this.status,
    this.connectorColor = Palette.inkMuted,
    this.showConnector = true,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String detail;
  final Color detailColor;
  final String status;
  final Color connectorColor;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 42,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 19),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: connectorColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Palette.inkMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: detailColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            detail,
                            style: TextStyle(
                              color: color == Palette.taxi
                                  ? Palette.taxi
                                  : Palette.ink,
                              height: 1.4,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status,
                          style: TextStyle(
                            color: color == Palette.taxi
                                ? Palette.taxi
                                : Palette.inkMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
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
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.text,
    required this.color,
    required this.bg,
  });
  final IconData icon;
  final String text;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
