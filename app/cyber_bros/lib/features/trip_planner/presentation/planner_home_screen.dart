import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/palette.dart';
import '../../../core/widgets/cyberon_brand.dart';
import '../data/osm_stops.dart';
import '../data/mapbox_road_service.dart';
import 'widgets/lima_map.dart';
import 'map_screen.dart';
import 'trip_history_screen.dart';
import 'trip_conditions_screen.dart';

class PlannerHomeScreen extends StatefulWidget {
  const PlannerHomeScreen({super.key});

  @override
  State<PlannerHomeScreen> createState() => _PlannerHomeScreenState();
}

class _PlannerHomeScreenState extends State<PlannerHomeScreen> {
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _mapController = MapController();
  late final Future<OsmStopCatalog> _stops = OsmStopCatalog.load();
  OsmStop? _originStop;
  OsmStop? _destinationStop;
  bool _isDemo = false;

  @override
  void dispose() {
    _originController.dispose();
    _destinationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _openConditions() {
    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();
    if (!_isDemo && (_originStop == null || _destinationStop == null)) return;
    if (origin.isEmpty || destination.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TripConditionsScreen(
          origin: origin,
          destination: destination,
          isDemo: _isDemo,
          originStop: _originStop,
          destinationStop: _destinationStop,
        ),
      ),
    );
  }

  void _loadExample() {
    setState(() {
      _originController.text = 'Av. Brasil cdra. 12, Jesús María';
      _destinationController.text = 'Plaza Bolognesi, Lima';
      _isDemo = true;
      _originStop = null;
      _destinationStop = null;
    });
  }

  Future<void> _openMap() async {
    final selection = await Navigator.of(context).push<MapSelection>(
      MaterialPageRoute(
        builder: (_) =>
            MapScreen(origin: _originStop, destination: _destinationStop),
      ),
    );
    if (selection == null || !mounted) return;
    if (selection.origin != null) _chooseStop(selection.origin!, origin: true);
    if (selection.destination != null) {
      _chooseStop(selection.destination!, origin: false);
    }
  }

  Future<void> _choosePointFromMap({required bool origin}) async {
    final stop = await Navigator.of(context).push<OsmStop>(
      MaterialPageRoute(
        builder: (_) => MapScreen(
          selectPoint: true,
          selectingOrigin: origin,
          origin: _originStop,
          destination: _destinationStop,
        ),
      ),
    );
    if (stop == null || !mounted) return;
    _chooseStop(stop, origin: origin);
  }

  bool _locatingGPS = false;

  Future<void> _locateDirectly() async {
    if (_locatingGPS) return;
    setState(() => _locatingGPS = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw StateError('Activa el GPS en tu dispositivo para ubicarte.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('El permiso de ubicación fue denegado.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final point = LatLng(position.latitude, position.longitude);
      _chooseStop(OsmStop.mapPoint(point, currentLocation: true), origin: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is StateError ? e.message : 'No se pudo obtener tu ubicación.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _locatingGPS = false);
    }
  }

  void _chooseStop(OsmStop stop, {required bool origin}) {
    setState(() {
      _isDemo = false;
      if (origin) {
        _originStop = stop;
        _originController.text = stop.displayName;
      } else {
        _destinationStop = stop;
        _destinationController.text = stop.displayName;
      }
    });
    FocusScope.of(context).unfocus();

    // Mover la cámara del mapa al punto seleccionado suavemente
    try {
      if (_originStop != null && _destinationStop != null) {
        final bounds = LatLngBounds.fromPoints([
          _originStop!.point,
          _destinationStop!.point,
        ]);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 220),
          ),
        );
      } else {
        _mapController.move(stop.point, 16.0);
      }
    } catch (_) {}

    // Si es un punto del mapa o coordenadas numéricas, resolver nombre de calle real con Mapbox
    if (stop.name == null ||
        stop.name!.contains(',') ||
        stop.source == 'user-map-selection' ||
        stop.source == 'device-location') {
      MapboxRoadService.reverseGeocode(stop.point).then((streetAddress) {
        if (!mounted) return;
        final updatedStop = OsmStop(
          id: stop.id,
          name: streetAddress,
          point: stop.point,
          source: stop.source,
        );
        setState(() {
          if (origin && _originStop?.id == stop.id) {
            _originStop = updatedStop;
            _originController.text = streetAddress;
          } else if (!origin && _destinationStop?.id == stop.id) {
            _destinationStop = updatedStop;
            _destinationController.text = streetAddress;
          }
        });
      });
    }
  }

  void _swapPoints() {
    setState(() {
      final originText = _originController.text;
      _originController.text = _destinationController.text;
      _destinationController.text = originText;
      final originStop = _originStop;
      _originStop = _destinationStop;
      _destinationStop = originStop;
      _isDemo = false;
    });
  }

  Widget _suggestions({required bool origin}) {
    final query = origin ? _originController.text : _destinationController.text;
    if (query.trim().length < 2 ||
        (origin ? _originStop : _destinationStop) != null) {
      return const SizedBox.shrink();
    }
    return FutureBuilder<OsmStopCatalog>(
      future: _stops,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('No se pudieron cargar los lugares locales.'),
          );
        }
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final matches = snapshot.data!.search(query, limit: 4);
        if (matches.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Sin coincidencias. Puedes explorar el mapa.'),
          );
        }
        return Column(
          children: [
            for (final stop in matches)
              ListTile(
                dense: true,
                leading: const Icon(Icons.location_on_outlined),
                title: Text(
                  stop.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: const Text('Paradero OSM · operación no verificada'),
                onTap: () => _chooseStop(stop, origin: origin),
              ),
          ],
        );
      },
    );
  }

  void _showUnavailable(String section) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$section estará disponible próximamente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pointDistance = _originStop != null && _destinationStop != null
        ? const Distance().as(
            LengthUnit.Meter,
            _originStop!.point,
            _destinationStop!.point,
          )
        : null;
    final canContinue =
        _isDemo || (pointDistance != null && pointDistance >= 100);

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const CyberonBrand(compact: true),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Center(
              child: Text(
                'Plan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Cuenta',
            onPressed: () => _showUnavailable('Cuenta'),
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: Palette.primaryDark,
              child: Icon(Icons.person_outline_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa en vivo a pantalla completa
          Positioned.fill(
            child: LimaMap(
              height: double.infinity,
              borderRadius: 0,
              mapController: _mapController,
              originPoint: _originStop?.point,
              destinationPoint: _destinationStop?.point,
              onTap: (point) {
                // Si falta origen, setea origen; si no, setea destino
                if (_originStop == null) {
                  _chooseStop(OsmStop.mapPoint(point), origin: true);
                } else {
                  _chooseStop(OsmStop.mapPoint(point), origin: false);
                }
              },
            ),
          ),
          // Botón flotante para ubicar o limpiar
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: Palette.primaryDark,
              onPressed: _openMap,
              tooltip: 'Ver pantalla completa de mapa',
              child: const Icon(Icons.fullscreen_rounded),
            ),
          ),
          // Hoja inferior flotante colapsable estilo Uber / inDrive
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.12,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Palette.surfaceAlt,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '¿A dónde vamos hoy?',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Palette.ink,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                            fontSize: 21,
                          ),
                        ),
                        if (_locatingGPS)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Palette.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Palette.border),
                      ),
                      child: Column(
                        children: [
                          _PlaceInput(
                            controller: _originController,
                            eyebrow: 'DESDE',
                            icon: _locatingGPS
                                ? Icons.sync_rounded
                                : Icons.my_location_rounded,
                            accent: const Color(0xFFD6E6FF),
                            hint: 'Punto de partida',
                            onIconTap: _locateDirectly,
                            onChanged: (_) => setState(() {
                              _isDemo = false;
                              _originStop = null;
                            }),
                            trailing: IconButton(
                              tooltip: 'Elegir en mapa',
                              onPressed: () => _choosePointFromMap(origin: true),
                              icon: const Icon(
                                Icons.map_outlined,
                                color: Palette.primary,
                              ),
                            ),
                          ),
                          _suggestions(origin: true),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              tooltip: 'Intercambiar',
                              onPressed: _swapPoints,
                              icon: const Icon(Icons.swap_vert_rounded, size: 22),
                            ),
                          ),
                          _PlaceInput(
                            controller: _destinationController,
                            eyebrow: 'HASTA',
                            icon: Icons.flag_outlined,
                            accent: const Color(0xFFFCE0D9),
                            hint: 'Toca el mapa o escribe destino',
                            onChanged: (_) => setState(() {
                              _isDemo = false;
                              _destinationStop = null;
                            }),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Elegir en mapa',
                                  onPressed: () =>
                                      _choosePointFromMap(origin: false),
                                  icon: const Icon(Icons.map_outlined),
                                ),
                                if (_destinationController.text.isNotEmpty)
                                  IconButton(
                                    tooltip: 'Borrar',
                                    onPressed: () {
                                      _destinationController.clear();
                                      setState(() {
                                        _isDemo = false;
                                        _destinationStop = null;
                                      });
                                    },
                                    icon: const Icon(Icons.close_rounded, size: 20),
                                  ),
                              ],
                            ),
                          ),
                          _suggestions(origin: false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: _loadExample,
                            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                            label: const Text('Viaje de ejemplo'),
                          ),
                        ),
                        if (_isDemo)
                          const Text(
                            'Modo Demo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Palette.inkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    FilledButton(
                      onPressed: canContinue ? _openConditions : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: Palette.primary,
                        elevation: 3,
                        shadowColor: Palette.primary.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Ver rutas y precios',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TripHistoryScreen(),
              ),
            );
          }
          if (index == 2) _showUnavailable('Cuenta');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'Planificar',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            label: 'Mis viajes',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            label: 'Cuenta',
          ),
        ],
      ),
    );
  }
}

class _PlaceInput extends StatelessWidget {
  const _PlaceInput({
    required this.controller,
    required this.eyebrow,
    required this.icon,
    required this.accent,
    required this.hint,
    required this.trailing,
    required this.onChanged,
    this.onIconTap,
  });

  final TextEditingController controller;
  final String eyebrow;
  final IconData icon;
  final Color accent;
  final String hint;
  final Widget trailing;
  final ValueChanged<String> onChanged;
  final VoidCallback? onIconTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Palette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onIconTap,
            borderRadius: BorderRadius.circular(21),
            child: CircleAvatar(
              radius: 19,
              backgroundColor: accent,
              child: Icon(icon, color: Palette.primary, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: eyebrow,
                hintText: hint,
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

