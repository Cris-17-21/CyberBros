# Rendimiento

Todas las cifras de este documento fueron **medidas** con
[`test/benchmark_test.dart`](../app/cyber_bros/test/benchmark_test.dart) (`flutter test
test/benchmark_test.dart`). Se dice con claridad qué se midió y qué no.

**Entorno de la medición**: equipo de desarrollo Windows 11, Flutter 3.47.7 (Dart 3.13.5), motor
ejecutándose en la VM de pruebas de Dart (no en un teléfono). 18 de octubre de 2026.

## Latencia del motor (RNF-01)

Se planificaron **60 viajes** sobre los datos reales de los corredores: 5 pares de puntos de Lima ×
3 conjuntos de límites × 4 rondas, tras un calentamiento. Incluye la construcción del grafo, la
búsqueda y, cuando no hay ruta, la relajación mínima.

| Percentil | Medido | Meta (RNF-01) | ¿Cumple? |
|---|---|---|---|
| p50 | **270 ms** | ≤ 800 ms | Sí |
| p95 | **711 ms** | ≤ 2 s | Sí |
| p99 | **783 ms** | ≤ 3 s | Sí |
| máximo | 811 ms | — | — |

De los 60 viajes, 16 tuvieron recorrido y 44 no (se ofrecieron relajaciones mínimas): el piloto
cubre solo 13 rutas, y las condiciones estrictas descartan muchas combinaciones.

La prueba **falla** si el p95 supera 2 s, así que corre en CI como protección contra regresiones.

## Tamaño del grafo

**587 nodos** (paraderos más origen y destino) y **13 rutas**. El grafo se arma en memoria en cada
planificación a partir del catálogo empaquetado.

## Inferencia de paraderos de facto

| Operación | Medido |
|---|---|
| DBSCAN sobre 2 000 puntos en 10 zonas | 348 ms, 10 clústeres (los esperados) |
| Motor completo con 99 abordajes co-ubicados | 15 ms, 1 paradero |

## Lo que NO se midió (y por qué)

| Meta | Estado |
|---|---|
| Carga inicial web (FCP/TTI con Lighthouse) | **No medido** |
| Fluidez del mapa en un teléfono de gama media (≥ 30 fps) | **No medido** |
| 50 usuarios concurrentes / 100 planes por minuto | **No aplica a la planificación**: el motor corre en el cliente, no en un servidor. La carga relevante es la de Firestore, que **no se probó** |
| Consumo de batería y datos | **No medido** |
| Memoria del grafo | **No medido** (solo su tamaño en nodos) |

Cuando una meta no se cumpla o no se haya medido, se dice así: **no se ajustan los resultados
para cumplir** (RNF-24).
