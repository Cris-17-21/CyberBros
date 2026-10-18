/// Mapbox public token configuration.
/// Can be overridden via --dart-define=MAPBOX_ACCESS_TOKEN=your_token
abstract final class MapboxConfig {
  static const token = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: 'MAPBOX_TOKEN_PLACEHOLDER',
  );
}
