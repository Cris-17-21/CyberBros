# Fuentes de datos

Cada dato de transporte debe poder rastrearse a una fuente y una fecha. Aquí se dice qué se usa,
de dónde viene, qué se midió y qué **no** se puede afirmar.

## Datos de transporte (empaquetados en la app)

| Archivo (`app/cyber_bros/assets/data`) | Fuente | Qué contiene | Fecha |
|---|---|---|---|
| `atu_sit_routes.json` | [Geovisor de la ATU](https://geovisor.atumovilidad.pe/), rutas SIT concesionadas | 47 trazos direccionales, usados como capa informativa del mapa | enero de 2026 |
| `osm_stops.json` | OpenStreetMap (extracto de Perú de Geofabrik), nodos etiquetados como parada o plataforma | 3 089 nodos en el área provisional Lima y Callao; 2 910 caen en 38 de los 43 distritos referenciales | ver `data/reports/osm-stop-coverage.json` |
| `osm_route_stops.json` | OpenStreetMap, relaciones de ruta con secuencia de paraderos | 95 relaciones con paraderos ordenados | ver `data/reports/osm-route-stops.json` |
| `corridor_candidates.json` | Cruce de los dos anteriores por código de ruta y distancia al trazo oficial (informe en `data/reports/atu-osm-route-crosswalk.json`) | **13 rutas** de los corredores Azul, Morado y Rojo, 886 paraderos en total. Es el **piloto** con el que planifica el motor | `corridor-pilot-b8f37ac7507b6034` |
| `data/raw/atu/general_fares.json` | Comunicados de la ATU en gob.pe (enlaces dentro del archivo) | Tarifas generales: Azul S/ 2.45, Morado S/ 2.80, Rojo S/ 2.43 | abril de 2026 (consultadas el 17/10/2026) |

Atribución: *Rutas SIT © ATU; paraderos © OpenStreetMap contributors (ODbL 1.0)*.

## Servicios externos en tiempo de ejecución

| Servicio | Para qué | Si falla |
|---|---|---|
| **Mapbox** (geocodificación, rutas por calle, mapa) | Buscar calles, dibujar tramos sobre calles y mostrar el mapa | Reintento + *circuit breaker*; los tramos se dibujan rectos y la búsqueda usa solo los paraderos locales |
| **Open-Meteo** (clima, datos abiertos, sin clave) | Lluvia actual y probabilidad de lluvia para sugerir menos caminata | No se muestra la sugerencia de clima |
| **Firebase** (Auth y Firestore) | Cuentas, historial en la nube y salas de taxi compartido | La app sigue funcionando como invitado con historial local |

## Qué es medido, qué es curado y qué es estimado

* **Medido / descargado**: los trazos ATU, los nodos y relaciones OSM, las tarifas de los
  comunicados. Se regeneran con los scripts de [`tools/`](../tools) (ver README).
* **Curado**: el cruce entre ATU y OSM (códigos de ruta + distancia) y el descarte de secuencias
  con saltos de más de 2,5 km entre paraderos consecutivos (error típico de relaciones OSM).
* **Estimado** (siempre rotulado como tal en la app): el costo del taxi (fórmula de UberX Lima con
  factor de hora punta), las distancias a pie (`haversine × 1,3`), las velocidades de bus y las
  esperas.

## Lo que NO se puede afirmar

* Que los paraderos de OSM **operan** o que la ruta efectivamente para ahí: son puntos
  colaborativos.
* Que el piloto representa **toda Lima**: son 13 relaciones de tres corredores.
* Que las tarifas incluyan promociones, medio pasaje, tarjeta o transbordos integrados.
* Frecuencias y horarios: no hay datos abiertos, las esperas son estimadas.
* Tiempo real de buses: no existe fuente abierta.

## Datos simulados

Las trazas del [laboratorio de paraderos](../app/cyber_bros/lib/features/trip_planner/presentation/stop_lab_screen.dart)
son **sintéticas** y se rotulan `SIMULADO` en pantalla; nunca se mezclan con datos de personas
reales.
