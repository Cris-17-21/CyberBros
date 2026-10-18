import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../../core/theme/palette.dart';
import '../../../core/widgets/cyberon_brand.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/presentation/profile_screen.dart';
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
  final _originFocus = FocusNode();
  final _destinationFocus = FocusNode();
  Timer? _debounce;
  Future<List<OsmStop>>? _suggestionFuture;
  bool _suggestionForOrigin = true;
  bool _isDemo = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _originFocus.dispose();
    _destinationFocus.dispose();
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
      _suggestionFuture = null;
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

  Future<List<OsmStop>> _searchStopsAndStreets(String query) async {
    final clean = query.trim();
    if (clean.length < 2) return const [];

    final catalog = await _stops;
    final stopMatches = catalog.search(clean, limit: 3);

    final addressMatches =
        await MapboxRoadService.searchAddresses(clean, limit: 4);

    final combined = <OsmStop>[...stopMatches];
    final seenNames =
        stopMatches.map((s) => s.displayName.toLowerCase()).toSet();

    for (final addr in addressMatches) {
      if (!seenNames.contains(addr.displayName.toLowerCase())) {
        combined.add(addr);
      }
    }

    return combined;
  }

  // ---------------------------------------------------------- sugerencias

  void _onQueryChanged({required bool origin, required String text}) {
    setState(() {
      _isDemo = false;
      if (origin) {
        _originStop = null;
      } else {
        _destinationStop = null;
      }
    });
    _debounce?.cancel();
    if (text.trim().length < 2) {
      setState(() => _suggestionFuture = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _suggestionForOrigin = origin;
        _suggestionFuture = _searchStopsAndStreets(text);
      });
    });
  }

  void _clearField({required bool origin}) {
    setState(() {
      _isDemo = false;
      _suggestionFuture = null;
      if (origin) {
        _originController.clear();
        _originStop = null;
      } else {
        _destinationController.clear();
        _destinationStop = null;
      }
    });
  }

  Widget _suggestionsPanel() {
    final future = _suggestionFuture;
    if (future == null) return const SizedBox.shrink();
    final origin = _suggestionForOrigin;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Palette.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: FutureBuilder<List<OsmStop>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _SuggestionMessage(
                icon: Icons.cloud_off_rounded,
                text: 'No pudimos buscar lugares. Revisa tu conexión.',
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Buscando calles y paraderos…',
                      style: TextStyle(color: Palette.inkMuted),
                    ),
                  ],
                ),
              );
            }
            final matches = snapshot.data!;
            if (matches.isEmpty) {
              return const _SuggestionMessage(
                icon: Icons.search_off_rounded,
                text:
                    'Sin coincidencias en Lima. Prueba con otro nombre o elige el punto en el mapa.',
              );
            }
            return Column(
              children: [
                for (var i = 0; i < matches.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 64),
                  _SuggestionTile(
                    stop: matches[i],
                    onTap: () {
                      setState(() => _suggestionFuture = null);
                      _chooseStop(matches[i], origin: origin);
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
    );
  }

  String _distanceLabel(int metres) => metres >= 1000
      ? '${(metres / 1000).toStringAsFixed(1)} km'
      : '$metres m';

  // ---------------------------------------------------------------- build

  /// Mapa con el que se fijan origen y destino tocando.
  Widget _map() => LimaMap(
    height: double.infinity,
    borderRadius: 0,
    mapController: _mapController,
    originPoint: _originStop?.point,
    destinationPoint: _destinationStop?.point,
    onTap: (point) {
      // Si falta origen, fija el origen; si no, el destino.
      if (_originStop == null) {
        _chooseStop(OsmStop.mapPoint(point), origin: true);
      } else {
        _chooseStop(OsmStop.mapPoint(point), origin: false);
      }
    },
  );

  /// Botones y etiqueta que flotan sobre el mapa. Van dentro de un
  /// PointerInterceptor para que, en web, sus clics no atraviesen al iframe.
  Widget _mapOverlays() => Stack(
    children: [
      Positioned(
        top: 16,
        right: 16,
        child: PointerInterceptor(
          child: Column(
            children: [
              _MapButton(
                icon: Icons.fullscreen_rounded,
                tooltip: 'Ver mapa completo',
                onPressed: _openMap,
              ),
              const SizedBox(height: 10),
              _MapButton(
                icon: _locatingGPS
                    ? Icons.sync_rounded
                    : Icons.my_location_rounded,
                tooltip: 'Usar mi ubicación',
                onPressed: _locateDirectly,
              ),
            ],
          ),
        ),
      ),
      if (_isDemo)
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Palette.ink.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 15, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Modo demostración',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );

  /// Botón principal "Ver rutas y precios" con su ayuda.
  Widget _cta({required bool canContinue, required int? pointDistance}) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: canContinue ? _openConditions : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            iconAlignment: IconAlignment.end,
            label: const Text('Ver rutas y precios'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              elevation: canContinue ? 3 : 0,
              shadowColor: Palette.primary.withValues(alpha: 0.4),
            ),
          ),
          if (!canContinue && pointDistance == null) ...[
            const SizedBox(height: 8),
            const Text(
              'Elige tu origen y tu destino para continuar',
              style: TextStyle(color: Palette.inkMuted, fontSize: 13),
            ),
          ],
        ],
      );

  /// Contenido del formulario (sin el botón principal, que va fijo aparte).
  List<Widget> _formChildren({
    required int? pointDistance,
    required bool tooClose,
    required bool showHandle,
  }) => [
    if (showHandle) ...[
      Center(
        child: Container(
          width: 42,
          height: 5,
          decoration: BoxDecoration(
            color: Palette.border,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
      const SizedBox(height: 14),
    ],
    const Text(
      '¿A dónde vamos hoy?',
      style: TextStyle(
        color: Palette.ink,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.7,
        fontSize: 24,
      ),
    ),
    const SizedBox(height: 2),
    ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final session = AuthService.instance.session;
        return Text(
          session == null
              ? 'Compara rutas según tu presupuesto y cuánto quieres caminar.'
              : 'Hola, ${session.label}. Compara rutas según tu presupuesto.',
          style: const TextStyle(color: Palette.inkMuted, fontSize: 14),
        );
      },
    ),
    const SizedBox(height: 16),
    _RouteCard(
      originController: _originController,
      destinationController: _destinationController,
      originFocus: _originFocus,
      destinationFocus: _destinationFocus,
      onOriginChanged: (text) => _onQueryChanged(origin: true, text: text),
      onDestinationChanged: (text) =>
          _onQueryChanged(origin: false, text: text),
      onClearOrigin: () => _clearField(origin: true),
      onClearDestination: () => _clearField(origin: false),
      onMapOrigin: () => _choosePointFromMap(origin: true),
      onMapDestination: () => _choosePointFromMap(origin: false),
      onSwap: _swapPoints,
    ),
    _suggestionsPanel(),
    const SizedBox(height: 12),
    SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickChip(
            icon: Icons.my_location_rounded,
            label: 'Mi ubicación',
            onTap: _locateDirectly,
          ),
          _QuickChip(
            icon: Icons.touch_app_outlined,
            label: 'Elegir en el mapa',
            onTap: () => _choosePointFromMap(origin: _originStop == null),
          ),
          _QuickChip(
            icon: Icons.auto_awesome_rounded,
            label: 'Viaje de ejemplo',
            onTap: _loadExample,
          ),
        ],
      ),
    ),
    if (pointDistance != null) ...[
      const SizedBox(height: 14),
      _DistanceNote(
        tooClose: tooClose,
        text: tooClose
            ? 'Están a solo $pointDistance m: puedes ir caminando.'
            : 'Distancia en línea recta: ${_distanceLabel(pointDistance)}',
      ),
    ],
  ];


  @override
  Widget build(BuildContext context) {
    final pointDistance = _originStop != null && _destinationStop != null
        ? const Distance()
              .as(LengthUnit.Meter, _originStop!.point, _destinationStop!.point)
              .round()
        : null;
    final canContinue =
        _isDemo || (pointDistance != null && pointDistance >= 100);
    final tooClose = pointDistance != null && pointDistance < 100;

    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const CyberonBrand(compact: true),
        actions: [
          ListenableBuilder(
            listenable: AuthService.instance,
            builder: (context, _) {
              final session = AuthService.instance.session;
              return IconButton(
                tooltip: 'Mi perfil',
                onPressed: _openProfile,
                icon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Palette.primaryDark,
                    child: session == null
                        ? const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                          )
                        : Text(
                            session.label.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // En pantallas anchas (web de escritorio) el formulario va en un panel
          // lateral y el mapa ocupa el resto: nada se superpone al mapa. En
          // móvil se usa la hoja inferior arrastrable.
          if (constraints.maxWidth >= 900) {
            return Row(
              children: [
                SizedBox(
                  width: 440,
                  child: Material(
                    color: Palette.background,
                    elevation: 6,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                            children: _formChildren(
                              pointDistance: pointDistance,
                              tooClose: tooClose,
                              showHandle: false,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, -3),
                              ),
                            ],
                          ),
                          child: _cta(
                            canContinue: canContinue,
                            pointDistance: pointDistance,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: _map()),
                      _mapOverlays(),
                    ],
                  ),
                ),
              ],
            );
          }
          return Stack(
            children: [
              Positioned.fill(child: _map()),
              _mapOverlays(),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: DraggableScrollableSheet(
                      initialChildSize: 0.5,
                      minChildSize: 0.16,
                      maxChildSize: 0.94,
                      builder: (context, scrollController) {
                        // PointerInterceptor: en web evita que los clics sobre la
                        // hoja lleguen al mapa (iframe) que está debajo.
                        return PointerInterceptor(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Palette.background,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(28),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.16),
                                  blurRadius: 24,
                                  offset: const Offset(0, -6),
                                ),
                              ],
                            ),
                            child: ListView(
                              controller: scrollController,
                              // Espacio inferior para que el botón fijo no tape nada.
                              padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
                              children: _formChildren(
                                pointDistance: pointDistance,
                                tooClose: tooClose,
                                showHandle: true,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              // El botón principal siempre visible, fuera de la lista que se desplaza.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: PointerInterceptor(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 14,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: _cta(
                          canContinue: canContinue,
                          pointDistance: pointDistance,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
          if (index == 2) _openProfile();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Planificar',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(Icons.directions_bus_rounded),
            label: 'Mis viajes',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle_rounded),
            label: 'Cuenta',
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- widgets

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 3,
    shadowColor: Colors.black26,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: Palette.primaryDark),
    ),
  );
}

/// Origen y destino en una sola tarjeta, unidos por una línea de recorrido.
class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.originController,
    required this.destinationController,
    required this.originFocus,
    required this.destinationFocus,
    required this.onOriginChanged,
    required this.onDestinationChanged,
    required this.onClearOrigin,
    required this.onClearDestination,
    required this.onMapOrigin,
    required this.onMapDestination,
    required this.onSwap,
  });

  final TextEditingController originController;
  final TextEditingController destinationController;
  final FocusNode originFocus;
  final FocusNode destinationFocus;
  final ValueChanged<String> onOriginChanged;
  final ValueChanged<String> onDestinationChanged;
  final VoidCallback onClearOrigin;
  final VoidCallback onClearDestination;
  final VoidCallback onMapOrigin;
  final VoidCallback onMapDestination;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
    decoration: BoxDecoration(
      color: Palette.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Palette.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F0F172A),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Palette.primary, width: 3.5),
                color: Palette.surface,
              ),
            ),
            for (var i = 0; i < 4; i++)
              Container(
                width: 2,
                height: 5,
                margin: const EdgeInsets.only(top: 3),
                color: Palette.border,
              ),
            const SizedBox(height: 3),
            const Icon(Icons.location_on_rounded, size: 22, color: Palette.taxi),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _PlaceField(
                controller: originController,
                focusNode: originFocus,
                hint: 'Punto de partida',
                onChanged: onOriginChanged,
                onClear: onClearOrigin,
                onMap: onMapOrigin,
                textInputAction: TextInputAction.next,
              ),
              const Divider(height: 1),
              _PlaceField(
                controller: destinationController,
                focusNode: destinationFocus,
                hint: '¿A dónde vas?',
                onChanged: onDestinationChanged,
                onClear: onClearDestination,
                onMap: onMapDestination,
                textInputAction: TextInputAction.search,
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Palette.primaryLight,
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: IconButton(
            tooltip: 'Intercambiar origen y destino',
            onPressed: onSwap,
            icon: const Icon(
              Icons.swap_vert_rounded,
              size: 22,
              color: Palette.primary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PlaceField extends StatelessWidget {
  const _PlaceField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.onClear,
    required this.onMap,
    required this.textInputAction,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onMap;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            textInputAction: textInputAction,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              color: Palette.ink,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Palette.inkMuted,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.text.isEmpty
              ? IconButton(
                  tooltip: 'Elegir en el mapa',
                  onPressed: onMap,
                  icon: const Icon(
                    Icons.map_outlined,
                    size: 21,
                    color: Palette.inkMuted,
                  ),
                )
              : IconButton(
                  tooltip: 'Borrar',
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Palette.inkMuted,
                  ),
                ),
        ),
      ],
    ),
  );
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.stop, required this.onTap});

  final OsmStop stop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final street = stop.source == 'mapbox:geocoding';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: street ? Palette.primaryLight : Palette.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                street ? Icons.signpost_rounded : Icons.directions_bus_rounded,
                size: 20,
                color: street ? Palette.primary : Palette.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Palette.ink,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    street ? 'Calle o dirección en Lima' : 'Paradero (OpenStreetMap)',
                    style: const TextStyle(
                      color: Palette.inkMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.north_west_rounded,
              size: 16,
              color: Palette.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionMessage extends StatelessWidget {
  const _SuggestionMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Icon(icon, color: Palette.inkMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Palette.inkMuted, height: 1.3),
          ),
        ),
      ],
    ),
  );
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ActionChip(
      onPressed: onTap,
      avatar: Icon(icon, size: 18, color: Palette.primary),
      label: Text(label),
      backgroundColor: Palette.surface,
      side: const BorderSide(color: Palette.border),
      labelStyle: const TextStyle(
        color: Palette.ink,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

class _DistanceNote extends StatelessWidget {
  const _DistanceNote({required this.text, required this.tooClose});

  final String text;
  final bool tooClose;

  @override
  Widget build(BuildContext context) {
    final color = tooClose ? Palette.estimated : Palette.primaryDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: tooClose ? Palette.estimatedBg : Palette.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            tooClose ? Icons.directions_walk_rounded : Icons.route_rounded,
            size: 19,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
