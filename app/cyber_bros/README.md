# Cyberon · Flutter

## Mapa

La app usa `flutter_map` con datos de OpenStreetMap. No necesita una clave de
Google Maps. La atribución visible **© OpenStreetMap contributors · flutter_map**
se muestra sobre el mapa.

Para preparar y ejecutar la app:

```powershell
flutter pub get
flutter run
```

El servidor público de teselas de OpenStreetMap tiene capacidad limitada y no
ofrece SLA. La app lo usa con peticiones interactivas normales; no descargar ni
precargar grandes áreas. Si el uso crece, cambiar a un proveedor de teselas con
SLA o alojar el servicio. Más detalles en la
[política de uso de teselas](https://operations.osmfoundation.org/policies/tiles/).

Los marcadores y líneas del recorrido siguen siendo ilustrativos: el mapa base
sí es real, pero las rutas, tarifas y paraderos aún no están conectados a datos
de transporte verificados.
