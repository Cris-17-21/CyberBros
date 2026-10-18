# Decisiones de implementación

**Fecha:** 17/10/2026  
**Estado:** decisiones vigentes para el desarrollo; prevalecen sobre propuestas anteriores cuando difieren.

## D-001 — Cobertura objetivo: todo Lima

La cobertura objetivo del MVP es toda Lima, no todo el Perú ni un solo eje. El límite geográfico exacto se fijará con una delimitación administrativa y quedará versionado en los datos. No se anunciará cobertura completa hasta medir rutas, paraderos, geometrías y secuencia de paradas en el área elegida.

El bbox de `tools/check_osm_coverage.py` es provisional y solo sirve para una primera auditoría. No representa todavía el polígono final de la app.

## D-002 — Zavu forma parte del MVP

Zavu se integra como canal de mensajería para planificar y replanificar. La app y Zavu reutilizarán el mismo dominio de planificación; no se implementará un segundo motor.

La integración necesita un servicio de confianza para guardar la clave de Zavu, verificar la firma de los webhooks y aplicar límites de entrada. Ese servicio será un backend ligero del MVP. Si Zavu o el backend no responden, el flujo principal de la app seguirá disponible.

## D-003 — El mapa no ocupa las pantallas de planificación

El mapa se abre en una vista propia para conservar el espacio de los formularios y de la comparación de opciones. En navegador se usa Leaflet sobre teselas de OpenStreetMap; Android conserva el mapa nativo Flutter basado en los mismos datos abiertos. Una ruta ilustrativa siempre se identifica como `DEMO`/`SIMULADO` y no se presenta como transporte validado.

La atribución de OpenStreetMap permanece visible. Las teselas públicas no son un servicio con SLA; antes de publicar se revisarán sus políticas y el volumen esperado.

## Consecuencias

- Las secciones previas que limitan el P0 a un eje o sitúan Zavu en un incremento posterior describen el plan anterior. Se actualizarán al implementar cada módulo afectado.
- No se inventarán rutas, tarifas ni conteos para aparentar cobertura.
- La primera entrega técnica mide los datos abiertos disponibles antes de construir el grafo de ruteo.
- La primera versión del mapa web carga Leaflet 1.9.4 desde el CDN público unpkg y las teselas desde `tile.openstreetmap.org`; requiere conexión de red.

## D-004 — Trazos SIT de ATU como capa informativa

El geovisor oficial de ATU publica un GeoJSON de rutas SIT actuales y polígonos distritales referenciales. La extracción del 17/10/2026 contiene 47 trazos direccionales válidos. El informe reproducible `data/reports/atu-sit-coverage.json` registra que 30 de los 43 distritos referenciales de Lima contienen al menos 100 m de esas líneas. La referencia temporal de rutas publicada por el geovisor es enero de 2026; los límites distritales se describen allí como censales INEI 2017 y referenciales.

Estos trazos se muestran con atribución ATU en la pantalla de mapa. No contienen secuencia de paraderos, tarifas, horarios ni confirmación operativa y no alimentan todavía el planificador. La fuente abarca solo las líneas SIT incluidas por ATU; el resultado de 30/43 no representa la cobertura de todo el transporte limeño. Se revisarán los términos específicos de publicación antes de redistribuir el activo en una versión pública.

## D-005 — Paraderos OSM como referencias de búsqueda

El extracto local OSM de Perú contiene 3 089 nodos etiquetados como parada o plataforma en el bbox provisional de Lima y Callao. Al contrastarlos con los polígonos referenciales ATU/INEI 2017, 2 910 están en Lima, repartidos en 38 de 43 distritos referenciales; 178 están en Callao y uno queda fuera de esos polígonos. El reporte `data/reports/osm-stop-coverage.json` guarda el desglose. La app permite buscarlos por nombre y centrarlos en el mapa. No se muestran como paraderos operativos confirmados ni se asignan a las rutas ATU por cercanía. El dato derivado conserva atribución OpenStreetMap y obligaciones ODbL.

## D-006 — Piloto de rutas cruzadas ATU/OSM

El PBF de Perú contiene 95 relaciones OSM con al menos dos paraderos etiquetados y ordenados dentro del bbox provisional. De 88 con cinco o más, 13 comparten código y familia de corredor con un trazo ATU y cumplen medianas de distancia ≤ 70 m y percentil 90 ≤ 150 m. El informe `data/reports/atu-osm-route-crosswalk.json` deja las distancias por ruta. Se usan solo como **candidatas geométricas**, porque la proximidad no comprueba permiso de abordaje ni operación actual.

Las tarifas generales de los corredores Azul, Morado y Rojo se tomaron de publicaciones ATU de abril de 2026 y se guardan en `data/raw/atu/general_fares.json` con fuente por servicio. No se aplican automáticamente promociones ni reglas de integración por falta de una tabla completa por tramo/tarjeta. El piloto cobra la tarifa general por abordaje y rotula los resultados como estimados; cada viaje muestra advertencias visibles. El motor no afirma cobertura de toda Lima y no debe recibir rutas con tarifa desconocida como si fueran planificables. La caminata directa usa distancia recta × 1,3; no valida caminos peatonales. El taxi puente usa la fórmula local estimada de la arquitectura, enlaza dos trayectos de transporte y se limita a un tramo de hasta 1,8 km; el precio real se confirma en la app de taxi.

## D-007 — Historial local de invitado hasta integrar identidad

El piloto guarda una copia del viaje elegido en `shared_preferences`, con versión del dataset, límites, tramos y fuentes. Retiene como máximo 100 registros durante 30 días en el dispositivo y permite repetir el trayecto recalculando con datos actuales. No almacena trazas GPS ni contraseñas. Si el almacenamiento falla, conserva registros solo en memoria durante la visita y avisa. Los estados de viaje son cambios manuales, no telemetría validada. `shared_preferences` no garantiza persistencia crítica; la sincronización entre dispositivos, vinculación de invitado a cuenta y protección de datos por usuario requieren identidad y backend aún no configurados. Los botones de login no deben fingir autenticación.

## Estado del entorno al iniciar

- El directorio se inicializó como repositorio Git en `main`.
- El SDK de Flutter disponible en este entorno está en `E:\flutter` (fuera del PATH).
- Overpass devolvió `502` por saturación y `500` en un endpoint alternativo; aún no hay conteos de cobertura.
