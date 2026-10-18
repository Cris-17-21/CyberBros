# Cyberon

Planificador multimodal para viajes en Lima. La app debe comparar transporte público, caminata y taxi puente según el presupuesto y los límites que el usuario fija para cada viaje.

## Decisiones vigentes

- Cobertura objetivo: toda Lima. La cobertura anunciada debe basarse en la delimitación administrativa, los datos de transporte medidos y su calidad; no se afirmará hasta validar el dataset.
- Cliente Flutter para Android y web. El motor se implementará como dominio Dart puro y local; Firebase será opcional para identidad, historial y tracción.
- Zavu está incluido en el MVP mediante un backend de confianza; la clave nunca se guarda en Flutter.
- El flujo principal y la demo funcionan sin cuenta, GPS ni servicios de terceros.
- OpenStreetMap provee el mapa base. La vista web independiente usa Leaflet; Android usa Flutter Map. Ambos muestran atribución OSM. La capa cartográfica necesita conexión.
- El mapa ya no se superpone a los formularios ni a las opciones. Las rutas dibujadas de demostración están marcadas `DEMO` y no representan transporte validado.

## Estado del repositorio

La auditoría inicial de Overpass terminó sin conteos por errores del servicio (`data/reports/osm-lima-coverage.json`). Se incorporó una primera fuente oficial: el [geovisor de la ATU](https://geovisor.atumovilidad.pe/) publica 47 trazos direccionales SIT (enero de 2026). El proceso reproducible en `tools/fetch_atu_data.py` y `tools/build_atu_dataset.py` valida el archivo, genera el activo de Flutter y un informe de cobertura en `data/reports/atu-sit-coverage.json`. De 43 distritos referenciales de Lima, 30 contienen al menos 100 m de estos trazos. Esto mide solo las rutas concesionadas presentes en esa fuente y no demuestra cobertura integral de transporte ni capacidad de planificar viajes. El dataset no trae secuencia de paraderos, tarifas u horarios.

El estado de implementación y los siguientes cortes están en [`tasks/todo.md`](tasks/todo.md) y [`tasks/plan.md`](tasks/plan.md). La app Flutter está en `app/cyber_bros`.

## Mapa y app web

- Flutter Web está habilitado. Leaflet 1.9.4 se carga desde el CDN público unpkg en la vista dedicada `web/leaflet_map.html`.
- Android conserva `flutter_map` con teselas OSM; no requiere clave de Google Maps.
- La vista de mapa permite seleccionar un trazo SIT publicado por ATU. La línea lleva atribución y fecha de los datos; no se usa todavía para calcular opciones de viaje.
- La búsqueda local de paraderos usa 3 089 nodos etiquetados en OpenStreetMap dentro de un bbox provisional de Lima y Callao. El informe `data/reports/osm-stop-coverage.json` cuenta 2 910 nodos dentro de 38 de los 43 distritos referenciales de Lima. Son puntos colaborativos: su presencia no verifica operación ni pertenencia a una ruta.
- Las tres alternativas ilustrativas aparecen únicamente al activar «Viaje de ejemplo». Al ingresar otros puntos, la app explica que aún no hay datos suficientes para calcular un itinerario verificable.
- El formulario permite fijar origen y destino desde sugerencias OSM locales o desde la pantalla de mapa. El texto libre sin punto confirmado no avanza al cálculo; dos puntos a menos de 100 m se señalan como trayecto caminable. El ejemplo aplica límites de presupuesto y caminata antes de mostrar sus alternativas simuladas.
- Al elegir una alternativa del piloto se guarda una copia fija en **Mis viajes**, con límites, tramos, fuentes y versión del dataset. El historial de invitado es local, se retiene hasta 30 días y puede borrarse por viaje; repetir recalcula con los datos actuales. Si el navegador bloquea el almacenamiento, el viaje permanece solo en memoria durante esa visita. Los botones de cuenta no simulan autenticación; todavía falta configurar un proveedor de identidad y sincronización.
- Hay un **piloto de planificación estimada** para 13 relaciones OSM cuyos códigos de ruta y paraderos coinciden geométricamente con trazos oficiales ATU de los corredores Azul, Morado y Rojo. El motor local cobra en céntimos al abordar, respeta presupuesto y caminatas máximas, y muestra hasta tres alternativas con su incertidumbre. También considera caminata directa corta y un taxi puente estimado de hasta 1,8 km entre dos trayectos de transporte cuando el usuario lo permite. Usa tarifas generales publicadas por ATU en abril de 2026; descuentos, integración, tarjeta, operación y abordaje exacto deben confirmarse. No cubre toda Lima ni se presenta como navegación verificada.
- La disponibilidad de mapas depende de la conexión y de las políticas del servidor de teselas. No hay geocodificación ni rutas de tránsito validadas todavía.
- Ejecutar Android: `flutter run -d <dispositivo>` desde `app/cyber_bros`.
- Compilar web: `flutter build web --release` desde `app/cyber_bros`.

## Ejecutar la auditoría inicial

Desde la raíz del repositorio:

```powershell
python tools/check_osm_coverage.py
```

El bbox de este auditor es provisional. Los conteos no demuestran geometría completa, orden de paradas, tarifas ni vigencia.

Para actualizar la capa ATU se necesita Python con las dependencias de `tools/requirements.txt`. Ejecute `python tools/fetch_atu_data.py` y después `python tools/build_atu_dataset.py`. Revise los términos de publicación del conjunto de datos antes de redistribuirlo públicamente.

Para actualizar los puntos OSM se necesita el extracto PBF de Perú de Geofabrik y `osmium` de `tools/requirements.txt`. Ejecute `python tools/extract_osm_stops.py <ruta-al-pbf>` y `python tools/audit_osm_stop_coverage.py`. El archivo derivado conserva atribución OSM y referencia a sus nodos.

Para rehacer el piloto, ejecute `python tools/extract_osm_route_stops.py <ruta-al-pbf>`, `python tools/crosswalk_atu_osm_routes.py` y `python tools/build_corridor_candidates.py`. El cruce usa los códigos de ruta y la distancia de los paraderos al trazo; su informe está en `data/reports/atu-osm-route-crosswalk.json`. Las tarifas generales y enlaces oficiales están versionados en `data/raw/atu/general_fares.json`.

## Documentos

- [Contexto completo](cyberon-contexto-completo.md)
- [Requerimientos](cyberon-requerimientos.md)
- [Arquitectura](cyberon-arquitectura.md)
- [Diseño UX/UI](cyberon-diseno.md)
- [Decisiones vigentes](docs/DECISIONS.md)
