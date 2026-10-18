import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/palette.dart';
import '../data/atu_routes.dart';
import '../data/osm_stops.dart';
import 'widgets/lima_map.dart';
import 'widgets/journey_map_leg.dart';

class MapSelection {
  const MapSelection(this.origin, this.destination);
  final OsmStop? origin;
  final OsmStop? destination;
}

/// A dedicated map view keeps the planning forms readable on small screens.
class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    this.showDemoRoute = false,
    this.selectPoint = false,
    this.journeyLegs = const [],
    this.origin,
    this.destination,
    this.selectingOrigin = true,
  });

  final bool showDemoRoute;
  final bool selectPoint;
  final List<JourneyMapLeg> journeyLegs;
  final OsmStop? origin;
  final OsmStop? destination;
  final bool selectingOrigin;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final Future<AtuRouteCatalog> _catalog = AtuRouteCatalog.load();
  late final Future<OsmStopCatalog> _stops = OsmStopCatalog.load();
  final TextEditingController _stopSearchController = TextEditingController();
  AtuRoute? _selectedRoute;
  OsmStop? _selectedStop;
  OsmStop? _origin;
  OsmStop? _destination;
  String _stopQuery = '';
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _origin = widget.origin;
    _destination = widget.destination;
  }

  void _selectCoordinate(LatLng point) {
    setState(() => _selectedStop = OsmStop.mapPoint(point));
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError(
          'Activa la ubicación del dispositivo e inténtalo otra vez.',
        );
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(
          'El permiso de ubicación no está disponible. Puedes elegir un punto tocando el mapa.',
        );
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      setState(
        () => _selectedStop = OsmStop.mapPoint(
          LatLng(position.latitude, position.longitude),
          currentLocation: true,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError ? error.message : 'No se pudo obtener tu ubicación. Elige un punto tocando el mapa.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  void dispose() {
    _stopSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        title: const Text('Mapa de Lima'),
        actions: [
          IconButton(
            tooltip: 'Usar mi ubicación actual',
            onPressed: _locating ? null : _useCurrentLocation,
            icon: _locating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
          ),
        ],
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: Column(
        children: [
          if (widget.selectPoint)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Toca el mapa para elegir ${widget.selectingOrigin ? 'el origen' : 'el destino'}, busca un paradero o usa tu ubicación actual.',
                style: const TextStyle(color: Palette.inkMuted),
              ),
            ),
          if (widget.journeyLegs.isNotEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Trayecto piloto estimado: líneas entre puntos OSM, no navegación por calles. Azul: bus · gris: caminata · rojo: taxi.',
                style: TextStyle(color: Palette.inkMuted, fontSize: 12),
              ),
            ),
          if (widget.showDemoRoute)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                      'Vista de demostración: la ruta no representa un servicio validado.',
                      style: TextStyle(color: Palette.inkMuted),
                    ),
                  ),
                ],
              ),
            ),
          FutureBuilder<AtuRouteCatalog>(
            future: _catalog,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'No se pudieron cargar los trazos publicados por la ATU.',
                  ),
                );
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              return Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedRoute?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Ruta SIT publicada por ATU',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Elige una ruta para verla en el mapa'),
                  items: [
                    for (final route in snapshot.data!.routes)
                      DropdownMenuItem(
                        value: route.id,
                        child: Text(
                          route.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (id) => setState(() {
                    _selectedRoute = snapshot.data!.routes
                        .where((route) => route.id == id)
                        .firstOrNull;
                  }),
                ),
              );
            },
          ),
          if (_selectedRoute != null)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Trazo publicado, sin paraderos, tarifas ni horarios verificados. Datos ATU: enero de 2026.',
                style: TextStyle(color: Palette.inkMuted, fontSize: 12),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: TextField(
              controller: _stopSearchController,
              onChanged: (query) => setState(() => _stopQuery = query),
              decoration: const InputDecoration(
                labelText: 'Buscar paradero en OpenStreetMap',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_stopQuery.trim().length >= 2)
            FutureBuilder<OsmStopCatalog>(
              future: _stops,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(
                    'No se pudo cargar el catálogo de paraderos OSM.',
                  );
                }
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final matches = snapshot.data!.search(_stopQuery, limit: 4);
                if (matches.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Sin coincidencias en los datos disponibles.'),
                  );
                }
                return SizedBox(
                  height: matches.length * 64.0,
                  child: ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      final stop = matches[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          stop.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: const Text('OSM · operación no verificada'),
                        onTap: () => setState(() {
                          _selectedStop = stop;
                          _stopQuery = '';
                          _stopSearchController.clear();
                          FocusScope.of(context).unfocus();
                        }),
                      );
                    },
                  ),
                );
              },
            ),
          if (_selectedStop != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                _selectedStop!.source == 'user-map-selection' ||
                        _selectedStop!.source == 'device-location'
                    ? '${_selectedStop!.displayName} · Punto elegido; no implica un paradero'
                    : '${_selectedStop!.displayName} · OSM · operación no verificada',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Palette.inkMuted),
              ),
            ),
          if (widget.selectPoint && _selectedStop != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(_selectedStop),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Usar este punto'),
              ),
            ),
          if (!widget.selectPoint &&
              widget.journeyLegs.isEmpty &&
              _selectedStop != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _origin = _selectedStop),
                    icon: const Icon(Icons.trip_origin_rounded),
                    label: const Text('Fijar origen'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        setState(() => _destination = _selectedStop),
                    icon: const Icon(Icons.flag_outlined),
                    label: const Text('Fijar destino'),
                  ),
                ],
              ),
            ),
          if (!widget.selectPoint &&
              widget.journeyLegs.isEmpty &&
              (_origin != widget.origin || _destination != widget.destination))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context)
                        .pop(MapSelection(_origin, _destination)),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Usar estos puntos en el plan'),
              ),
            ),
          Expanded(
            child: LimaMap(
              key: ValueKey(
                '${_selectedRoute?.id}:${_selectedStop?.id}:${widget.journeyLegs.length}',
              ),
              showDemoRoute: widget.showDemoRoute,
              atuRoute: _selectedRoute,
              selectedStop: _selectedStop,
              originPoint: _origin?.point,
              destinationPoint: _destination?.point,
              onTap: _selectCoordinate,
              journeyLegs: widget.journeyLegs,
              height: double.infinity,
              borderRadius: 0,
            ),
          ),
          const SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Mapa © OpenStreetMap contributors',
                textAlign: TextAlign.center,
                style: TextStyle(color: Palette.inkMuted, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
