# Cyberon

**Planificador de viajes por Lima que respeta tu presupuesto y cuánto puedes caminar.**
Compara transporte público, caminata y un taxi corto *solo en el tramo donde conviene*, y te dice
con cifras exactas qué ganas y qué sacrificas en cada opción.

Hack the Andes 2026 · Track *Movilidad y Transporte* · Problema: **transporte público en Lima,
rutas y tiempos**.

**Demo en vivo:** https://cyberon-lima.web.app (funciona sin cuenta, en ventana privada; usa «Explorar sin cuenta»).

## El problema y para quién

Moverse por Lima combinando buses, corredores, caminata y taxi es un cálculo de **dinero, esfuerzo y
certidumbre** que la gente hace "de memoria y a ciegas". Google Maps, Moovit y Waze optimizan el
**tiempo** y tratan el viaje como "todo transporte público" o "todo taxi"; no conocen cuánto dinero
tienes ni cuánto puedes caminar hoy.

* **Valeria**, estudiante que vuelve de noche con S/ 8 y una mochila pesada, debe caminar 600 m
  entre dos corredores por una avenida poco iluminada. Pregunta que no puede responder hoy: *¿me
  conviene pagar un taxi solo esos 600 m y seguir en bus, y me alcanza el dinero?*
* **Rosa**, que vuelve del mercado con bolsas: *"lo más barato que no me mate la espalda"*.
* **Diego**, que ya pagó un bus y debe cambiar de plan *con los S/ 5.50 que le quedan*.

## Qué hace hoy

* **Planifica con restricciones duras**: presupuesto, caminata seguida y total, taxi sí o no.
  Ninguna opción devuelta las rompe (hay una prueba que lo verifica sobre los datos reales).
* **Hasta 3 alternativas distintas** (más barata, menos caminata, equilibrada…) con una explicación
  de lo que ganas y lo que sacrificas, con cifras exactas.
* **Si no hay recorrido, no dice "sin resultados"**: calcula el **cambio mínimo de una sola
  condición** ("Te faltan S/ 0.50", "Si aceptas caminar hasta 450 m…") y lo aplica solo si tú
  aceptas.
* **Cuéntalo con tus palabras**: *"tengo 10 soles y no quiero caminar más de 2 cuadras"* se
  convierte en condiciones que tú revisas antes de usarlas.
* **Contexto real**: el clima de Lima (Open-Meteo) y la hora sugieren caminar menos cuando llueve o
  es de noche.
* **Seguimiento del viaje** tramo a tramo con GPS, **notificaciones locales** (viaje en curso,
  siguiente paso, cercanía, llegada, feedback, recordatorio).
* **Taxi compartido para el tramo puente**: salas para repartir el taxi con personas que van al
  mismo tramo.
* **Cuentas y historial** en la nube (Firebase Auth + Firestore), o uso como invitado con historial
  local.
* **Laboratorio de paraderos de facto**: cómo descubrir dónde la gente aborda de verdad y cómo se
  defiende de datos falsos (todo **simulado** y rotulado).

## Lo técnico, en una mirada

| Pieza | Qué es |
|---|---|
| Motor de ruteo | Búsqueda **multietiqueta con dominancia de Pareto** sobre un grafo en memoria; una tarifa por abordaje; céntimos enteros |
| Relajación mínima | Problema de factibilidad: para cada itinerario candidato, qué restricciones viola; si es una, define el cambio mínimo |
| Intérprete | Analizador en español propio, validado por esquema; no inventa valores |
| Paraderos de facto | Detección de abordaje + **DBSCAN** + fuentes independientes (`nEff`) + cuarentena + decaimiento + reversión |
| Resiliencia | Cliente HTTP con reintentos y *circuit breaker* por servidor; funciona en web |
| Datos | ATU (SIT) + OpenStreetMap + tarifas ATU, cruzados con scripts reproducibles |

Detalle en [ARQUITECTURA](docs/ARCHITECTURE.md), [MODELO DE AMENAZAS](docs/THREAT_MODEL.md) y
[RENDIMIENTO](docs/PERFORMANCE.md) (cifras **medidas**: planificar un viaje tarda p50 270 ms y
p95 711 ms sobre los datos reales).

## Estado y límites (lo que quedó fuera)

Para ser honestos con lo que se puede demostrar:

* **Cobertura**: el motor planifica con **13 rutas** de los corredores Azul, Morado y Rojo (piloto).
  Fuera de ellas solo ofrece ir a pie o en taxi directo, si caben en tus límites. **No cubre toda
  Lima.**
* **Tarifas**: generales de la ATU (abril de 2026). No incluyen promociones, medio pasaje ni
  transbordos integrados. Los precios de taxi son **estimados**.
* **Tiempos**: las esperas y velocidades son estimaciones; no hay datos abiertos de buses en
  tiempo real.
* **Paraderos de facto**: la inferencia está implementada y probada con trazas **sintéticas**.
  Con usuarios reales haría falta un backend que valide y agregue las trazas.
* **No implementado todavía**: replanificar a mitad de viaje con el saldo restante, eliminar la
  cuenta desde la app, notificaciones push (FCM), pago o reserva de taxi.

## Ejecutar

Requiere Flutter (probado con 3.47.7). Desde `app/cyber_bros`:

```powershell
flutter pub get
flutter run -d <dispositivo>          # Android
flutter build web --release           # versión web
flutter analyze lib
flutter test                          # 95 pruebas
```

El flujo principal y la demo funcionan **sin cuenta, sin GPS y sin servicios de terceros**: el
"viaje de ejemplo" da siempre el mismo resultado.

**Configuración** (`lib/core/config/`): la clave web de Firebase y el token público de Mapbox
no son secretos; pueden reemplazarse al compilar con
`--dart-define=FIREBASE_API_KEY=...` y `--dart-define=MAPBOX_ACCESS_TOKEN=...`. Ver
[`.env.example`](.env.example). Las reglas de seguridad de Firestore están en
[`firebase/`](firebase) (todo denegado por defecto).

## Pruebas

Corren en CI en cada push ([`ci.yml`](.github/workflows/ci.yml)) junto con el análisis estático y
la compilación web:

* Motor y "viajes de oro" (solución única, taxi que no debe aparecer, recálculo con saldo
  reducido, caminata que excede el límite, presupuesto menor que cualquier tarifa).
* Relajación mínima con resultados exactos.
* Intérprete de condiciones (incluye entradas hostiles).
* Inferencia de paraderos y las pruebas de ataque: **carrito**, **carrito + auto**, **bots**,
  control positivo y reversión.
* Cliente resiliente (reintentos, circuito abierto, recuperación), clima, taxi compartido.

## Datos y herramientas

Fuentes, fechas y qué se puede afirmar: [DATA_SOURCES](docs/DATA_SOURCES.md). Los datos se
regeneran con los scripts de [`tools/`](tools) (Python, dependencias en `tools/requirements.txt`).

```powershell
python tools/fetch_atu_data.py && python tools/build_atu_dataset.py          # capa ATU
python tools/extract_osm_stops.py <extracto-peru.pbf>                       # paraderos OSM
python tools/extract_osm_route_stops.py <extracto-peru.pbf>                 # secuencias de paraderos
python tools/crosswalk_atu_osm_routes.py && python tools/build_corridor_candidates.py   # piloto
```

Los conteos de cobertura son mediciones del origen, no demuestran operación ni cobertura integral.

## Documentos

* [Arquitectura](docs/ARCHITECTURE.md) · [Modelo de amenazas](docs/THREAT_MODEL.md) ·
  [Rendimiento](docs/PERFORMANCE.md) · [Fuentes de datos](docs/DATA_SOURCES.md) ·
  [Privacidad](docs/PRIVACY.md) · [Decisiones](docs/DECISIONS.md)
* Diseño del producto: [contexto](cyberon-contexto-completo.md) ·
  [requerimientos](cyberon-requerimientos.md) · [arquitectura objetivo](cyberon-arquitectura.md) ·
  [diseño UX/UI](cyberon-diseno.md)
