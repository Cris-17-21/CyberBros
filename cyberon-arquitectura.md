# 🏗️ Cyberon — Arquitectura del sistema (enfoque MVP)

**Proyecto:** Cyberon · **Evento:** Hack the Andes (Lima, 17–18 oct 2026) · **Track:** `transport`
**Stack decidido por el equipo:** **Flutter** (cliente) · **Firebase** (base de datos, notificaciones y, por lo que implica, identidad)
**Documentos hermanos:**
- [cyberon-requerimientos.md](cyberon-requerimientos.md) — **qué** debe hacer el sistema (RF/RNF).
- [cyberon-contexto-completo.md](cyberon-contexto-completo.md) — contexto, problema, solución y sponsors.
- [cyberon-diseno.md](cyberon-diseno.md) — **cómo se ve y se siente**: sistema de diseño UX/UI "Amanecer en los Andes" (color, tipografía, componentes, pantallas).
- **Este documento** — **cómo** se construye: componentes, datos, flujos, despliegue y plan por incrementos.

> ⚠️ **Este documento reemplaza al stack propuesto en la sec. 8 del documento de contexto** (que sugería PostgreSQL + PostGIS + backend Node/Python). Con Flutter + Firebase y un plazo de ~18 h, esa pila es innecesaria y más riesgosa. Las razones están en la sección 15 (decisiones).

---

## 0. Cómo leer este documento

| Marca | Significado |
|---|---|
| ✅ | Decisión firme, coherente con los requerimientos |
| ⚠️ | Dato o supuesto **por verificar** antes de depender de él |
| 🤖 | **Nota para el agente constructor**: instrucción concreta |
| 🎯 | Relevante para la rúbrica o la demo |
| 🔻 | Se recorta si el tiempo aprieta |

**Orden:** 1 resumen · 2 enfoque MVP · 3 restricciones · 4 vistas (contexto y contenedores) · 5 app Flutter · 6 motor de ruteo · 7 datos estáticos · 8 Firebase · 9 backend ligero · 10 flujos · 11 seguridad y privacidad · 12 rendimiento y resiliencia · 13 pruebas y calidad · 14 despliegue · 15 decisiones (ADR) · 16 trazabilidad con requerimientos · 17 plan de construcción · 18 riesgos y preguntas abiertas · 19 reglas duras.

---

## 1. Resumen ejecutivo

**En una frase:** una app **Flutter** (Android + web mobile-first) que **calcula los recorridos en el propio dispositivo** con un motor de ruteo escrito en **Dart puro**, sobre un **dataset de transporte empaquetado**, y usa **Firebase** solo para lo que realmente necesita estado compartido: cuentas, historial, evidencia de tracción y (más adelante) notificaciones y paraderos inferidos.

**Las cinco decisiones que definen la arquitectura:**

1. **Un solo cliente Flutter para todo.** El mismo código produce la **app móvil** y la **versión web pública** que el jurado abrirá en incógnito (regla del evento: *"se evalúa una demo en vivo desde tus links"*).
2. **El motor de ruteo es un paquete Dart puro y testeable**, sin dependencias de Flutter, red ni Firebase. Se usa hoy dentro de la app y mañana también en el backend (misma lógica, un solo lenguaje).
3. **En el MVP no hay servidor propio.** El motor corre en la app; los datos de transporte van empaquetados; Firebase guarda lo del usuario. Menos piezas = menos cosas que fallan el domingo a las 10:00.
4. **Un backend ligero aparece solo cuando es imprescindible** (Incremento A/B): lo que exige secretos o confianza — inferencia de paraderos con defensas anti-manipulación (RF-36), alertas con claves de terceros, envío de notificaciones push, agregados de tracción validados.
5. **La app habla con un `PlannerGateway`** (interfaz): hoy `LocalPlanner` (motor en el dispositivo), mañana `RemotePlanner` (backend) o ambos (respaldo si el backend cae). Cambiar de uno a otro no toca la interfaz de usuario.

**Diagrama de una sola mirada (MVP):**

```
   Pasajero / Jurado (PC en incógnito)
              │
              ▼
 ┌──────────────────────────────────────────────────────────────┐
 │                  APP FLUTTER  (Android + Web)                │
 │                                                              │
 │   Interfaz (features)   ──▶   PlannerGateway (interfaz)      │
 │   Riverpod · go_router            │                          │
 │   flutter_map · geolocator        ▼                          │
 │                           ┌────────────────┐   ┌───────────┐ │
 │                           │ routing_engine │◀──│ Dataset   │ │
 │                           │  (Dart puro)   │   │ estático  │ │
 │                           └────────────────┘   │ (asset)   │ │
 │                                                └───────────┘ │
 └─────────────────────────┬────────────────────────────────────┘
                           │  SDK de Firebase
        ┌──────────────────┼───────────────────┐
        ▼                  ▼                   ▼
   Firebase Auth     Cloud Firestore      (FCM: Incremento B)
   (invitado/cuenta) (usuario, historial,
                      tracción, reglas)
```

---

## 2. Enfoque MVP

### 2.1 Filosofía
> **Primero un corte vertical delgado que funcione de punta a punta y esté desplegado; después, capas de diferenciación que se pueden recortar sin romper lo anterior.**

La rúbrica premia ante todo: **(a)** que funcione en vivo desde la URL pública, **(b)** complejidad técnica real, **(c)** repo limpio, **(d)** evidencia de uso. Un MVP pequeño que cumple (a)(c)(d) y demuestra (b) con el motor de ruteo **vale más** que una app ambiciosa que falla en la demo.

### 2.2 Qué es "el MVP" (definición operativa)

> **MVP = MVP-0 (Núcleo) + MVP-1 (Evidencia).** Es lo mínimo que **debe** estar entregado y probado en incógnito antes de empezar cualquier incremento.

**El corte vertical:** *un pasajero (invitado o con cuenta) elige origen y destino en un eje de Lima, fija presupuesto y caminata, recibe hasta 3 alternativas honestas (con taxi puente donde conviene), entiende el tradeoff, sigue el recorrido paso a paso, replantea con el saldo restante, y su historial y su uso quedan registrados.*

| Hito | Contenido | Requerimientos (ver sec. 16) |
|---|---|---|
| **MVP-0 · Núcleo** | Datos del eje + motor de ruteo con restricciones duras, tramo puente, 3 alternativas, infactibilidad con relajación mínima, certidumbre en pantalla; app Flutter con S1→S5; invitado y registro/login; historial básico; **despliegue web público probado en incógnito** | RF-01, 02, 03, 05, 06, 07, 08, 09, 10, 11, 15, 24, 25, 31, 32, 33, 34 · RNF-01, 02, 03\*, 04, 07, 08, 09, 12, 14, 15, 17, 20, 21, 22, 26, 28, 29 |
| **MVP-1 · Evidencia** | Seguimiento por tramos (avance manual, GPS opcional), replanificación con saldo, finalización con feedback, **eventos de uso y panel de tracción**, modo demo con viaje ensayado, notificaciones **locales**, consentimiento mínimo, README/descripción/slides, **`andes project submit` v1** | RF-12, 13, 14, 20, 22, 23, 29, 30, 35 (cerrar sesión) · RNF-05, 06, 11, 13, 19, 24, 27 |

\* RNF-03 se ajusta para Flutter web (ver sec. 12.1).

### 2.3 Incrementos (se hacen **después** del MVP, en este orden, recortables)

| Incremento | Qué agrega | Por qué en ese orden | Necesita backend |
|---|---|---|---|
| **A · Motor 2 (paraderos de facto)** | Captura de telemetría con consentimiento, detección espera→abordaje, agrupamiento, simulador `SIMULADO`, **defensas RF-36 [P0]** (cuarentena, `n_eff`, plausibilidad) | Es el mayor diferenciador técnico, pero **la inferencia no puede correr en el cliente** (no es confiable) | **Sí (ligero)** |
| **B · Integraciones** | Alertas (Tavily/Exa) con fuente, **notificaciones push FCM por tema de ruta**, intérprete de lenguaje natural, sponsors útiles (Maritime, AtomicMemory) | Todo lo que necesita **claves secretas** o **envío push** | **Sí** |
| **C · Extras** | Mensajería (Zavu), refresco automático (n8n/Apify), eliminación de cuenta completa, análisis de anomalías | Valor marginal; solo si sobra | Sí/No |

**🔻 Líneas de corte (reglas de decisión):**
- Si al llegar a **H+10** el MVP-0 no está **desplegado y probado en incógnito** → se **congela todo lo demás** hasta lograrlo.
- Si al llegar a **H+13** el MVP-1 no está completo → **no se inicia ningún incremento**.
- El **Incremento A** solo se empieza si hay **≥ 5 h** libres antes de las 07:00; si no, se muestra el detector únicamente como **simulador en la UI** (rotulado `SIMULADO`) y se declara "alcance futuro".
- **Nada** de B ni C se inicia sin que A esté estable o descartado explícitamente.

### 2.4 Qué NO entra al MVP (y por qué)
| Fuera del MVP | Motivo |
|---|---|
| Servidor propio, PostGIS, OSRM, geocodificador remoto | No hacen falta para el corte vertical; añaden fallos |
| Motor 2 en producción | Requiere backend y defensas RF-36 |
| Lenguaje natural, alertas, push FCM, Zavu, n8n, Apify, Qatom | Dependen de claves/servidor y no cambian la tesis |
| Taxi compartido entre usuarios | Alto riesgo, poco verificable |
| Eliminación de cuenta con cascada completa | Incremento C; en MVP se documenta el procedimiento |
| App iOS | No hay entorno; Android + web alcanzan |

---

## 3. Restricciones y supuestos de partida

| # | Restricción / supuesto | Consecuencia arquitectónica |
|---|---|---|
| R1 | Cliente en **Flutter** (equipo) | Un código → Android + web; paquetes Dart compartibles con el backend |
| R2 | **Firebase para base de datos y notificaciones** (equipo); Auth se asume por RF-31/32/33 | Firestore + FCM (+ Auth). Sin consultas geoespaciales nativas |
| R3 | La organización abre la **URL pública en incógnito**, sin sesión | La web es el entregable oficial; **invitado sin registro**; nada de localhost |
| R4 | ~**18 h** de construcción, equipo de 2–4 | MVP delgado, incrementos recortables |
| R5 | El jurado revisa el **repo** (calidad) | Estructura limpia, tipado, pruebas, README |
| R6 | Sponsors con créditos (Maritime, Tavily, Exa, etc.) | Backend futuro puede alojarse en Maritime; claves **solo en servidor** |
| R7 | **Sin hardware especial**, datos abiertos | Datos OSM/ATU curados; sin sensores propios |
| R8 | ⚠️ Plan gratuito de Firebase puede limitar lecturas/escrituras y **no permitir funciones en la nube** | Backend **externo** y diseño que cuida lecturas/escrituras (sec. 8.6) |
| R9 | Jurado en PC de escritorio, red del recinto | La demo debe ser liviana y no depender de permisos de ubicación |

---

## 4. Vistas del sistema

### 4.1 Contexto (quién interactúa con qué)

```
 ┌───────────────┐        usa           ┌──────────────────────────┐
 │ Pasajero      │ ───────────────────▶ │                          │
 │ (Android/web) │                      │                          │
 └───────────────┘                      │         CYBERON          │
 ┌───────────────┐   evalúa (incógnito) │   (app Flutter + Firebase│
 │ Jurado        │ ───────────────────▶ │    + backend ligero*)    │
 └───────────────┘                      │                          │
 ┌───────────────┐   cura datos, opera  │                          │
 │ Equipo        │ ───────────────────▶ └───┬───────┬──────────┬───┘
 └───────────────┘                          │       │          │
                          datos abiertos    │       │          │ 
                 ┌──────────────────────────┘       │          └─────────────┐
                 ▼                                  ▼                        ▼
        OpenStreetMap / ATU            Servicios de terceros*       Teselas del mapa
        (ingesta offline)         (Tavily/Exa, LLM, mensajería)    (proveedor configurable)
                                       * solo en incrementos A/B/C
```

### 4.2 Contenedores — **arquitectura del MVP**

```
┌───────────────────────────────── CLIENTE ──────────────────────────────────┐
│                                                                            │
│  apps/cyberon_app  (Flutter: Android + Web)                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐   │
│  │ features/    │  │ core/        │  │ data/        │  │ packages/     │   │
│  │ plan, trip,  │─▶│ gateways,    │─▶│ firebase_*   │  │ cyberon_domain│   │
│  │ history,     │  │ config, i18n │  │ repositories │  │ routing_engine│   │
│  │ auth, demo,  │  │ tema, utils  │  │ dataset_repo │  │ (Dart puro)   │   │
│  │ traction     │  └──────────────┘  └──────────────┘  └───────────────┘   │
│  └──────────────┘                                                          │
└──────────────┬─────────────────────────────────────────────────────────────┘
               │  HTTPS (SDK Firebase)
┌──────────────▼───────────────────── FIREBASE ──────────────────────────────┐
│  Auth (anónimo → cuenta)  │  Firestore (+ reglas versionadas)  │ Hosting*  │
└─────────────────────────────────────────────────────────────────────────────┘
* Hosting estático de la versión web: Firebase Hosting u otro host estático; es indistinto para la arquitectura.

  Artefacto de datos (build offline, no servicio):  data/build/lima_axis_vYYYYMMDD.json
  ──▶ empaquetado como asset de la app y versionado en el repo.
```

### 4.3 Contenedores — **arquitectura objetivo (con incrementos A y B)**

```
┌────────────── CLIENTE (Flutter) ──────────────┐
│ UI ─ PlannerGateway ─┬─ LocalPlanner (motor)  │
│                      └─ RemotePlanner (HTTP)  │◀── respaldo mutuo
└───────┬───────────────────────┬───────────────┘
        │ SDK Firebase          │ HTTPS + ID token
        ▼                       ▼
┌───────────────┐      ┌─────────────────────────────────────────────┐
│ Firebase      │      │ BACKEND LIGERO (Dart, en Maritime u otro)    │
│ • Auth        │◀────▶│ • verifica ID tokens                         │
│ • Firestore   │ Admin│ • API: /plan (opcional), /alerts, /nlp,      │
│ • FCM (push)  │ REST │   /telemetry/batches                         │
└───────────────┘      │ • Jobs: stop_inference (RF-17/18/36),        │
                       │   métricas de tracción, caducidad de alertas │
                       │ • Claves de Tavily/Exa/LLM/Zavu (solo aquí)  │
                       └───────────────────────┬─────────────────────┘
                                               ▼
                                   Servicios de terceros (sponsors)
```

> 🤖 **El paso de MVP → objetivo no reescribe nada:** se agrega `RemotePlanner`, se añade el backend, se cambian reglas de Firestore para que ciertos documentos solo los escriba el backend. La UI y el motor no cambian.

---

## 5. La app Flutter

### 5.1 Pila de paquetes (recomendación; ⚠️ confirmar versiones al crear el proyecto)

| Necesidad | Paquete | Nota |
|---|---|---|
| Estado | `flutter_riverpod` | Sencillo de probar; separa UI de lógica |
| Navegación | `go_router` | Enlaces profundos y soporte web (URL por pantalla) |
| Mapa | `flutter_map` + `latlong2` | Funciona en web y móvil, **sin clave obligatoria** |
| Ubicación | `geolocator` | Web y móvil; manejar permisos denegados |
| Firebase | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_messaging` | Configuración con FlutterFire CLI |
| Notificaciones locales | `flutter_local_notifications` | **Solo móvil** (no existe en web) |
| Modelos | clases Dart inmutables (`freezed` opcional) | 🔻 `freezed` añade tiempo de `build_runner`; usar solo si el equipo ya lo domina |
| HTTP (incrementos) | `dio` o `http` | Solo para `RemotePlanner` y backend |
| Pruebas | `flutter_test`, `mocktail` | Pruebas de widgets y repositorios |
| Configuración | `--dart-define` / `--dart-define-from-file` | **Nunca** claves secretas en el cliente |

### 5.2 Estructura de capas (arquitectura limpia, *feature-first*)

```
lib/
├─ main.dart · app.dart                 # arranque, tema, router, ProviderScope
├─ core/
│  ├─ config/        # flavors, dart-define, feature flags
│  ├─ gateways/      # PlannerGateway (interfaz) + Local/Remote
│  ├─ errors/        # tipos de error → mensajes es-PE
│  ├─ i18n/          # textos (es-PE), formateo S/, metros, fechas
│  └─ ui/            # tema, widgets base, chips de certidumbre
├─ data/
│  ├─ dataset/       # carga y validación del dataset empaquetado
│  ├─ firebase/      # auth_repo, trips_repo, events_repo, prefs_repo
│  └─ location/      # servicio de ubicación + modo demo
└─ features/
   ├─ plan/          # S1 origen/destino · S2 condiciones · S3 comparar · S4 infactible
   ├─ trip/          # S5 revisión · S6 seguimiento · S7 "algo cambió" · S8 fin
   ├─ history/       # "Mis viajes", detalle, repetir
   ├─ auth/          # invitado, registro, login, cuenta
   ├─ traction/      # S9 panel público
   └─ demo/          # viajes de ejemplo, modo demo, (simulador en Inc. A)
```

**Reglas de dependencia (se verifican en revisión):**
- `features` → `core` y `data` (por interfaces). `features` **nunca** importa Firebase directamente.
- `data` → paquetes `cyberon_domain` y SDK de Firebase.
- `routing_engine` y `cyberon_domain` **no importan Flutter, Firebase ni red**.
- Todo acceso a Firebase pasa por **repositorios** (interfaces) → se puede sustituir por *fakes* en pruebas.

### 5.3 Estado y flujo de datos
- **Proveedores Riverpod** por feature: `planFormProvider` (condiciones), `planResultProvider` (alternativas), `activeTripProvider` (viaje en curso), `authStateProvider`, `historyProvider`.
- **Estado inmutable**; los cálculos del motor devuelven objetos de dominio puros.
- **Viaje activo persistente:** se guarda en Firestore (si hay uid) y en almacenamiento local como respaldo, para **reanudar** (RF-12).

### 5.4 Diferencias web vs. móvil (donde Flutter obliga a decidir)

| Tema | Android | Web (lo que ve el jurado) | Decisión |
|---|---|---|---|
| Ubicación | Permiso del sistema | Permiso del navegador; en PC es poco precisa | **Modo demo**: fijar posición tocando el mapa (RF-20) |
| Notificaciones locales | ✅ | ❌ no disponibles | Se demuestran en teléfono; en web, avisos en pantalla |
| Push FCM | ✅ | Requiere service worker y permiso; poco fiable en incógnito | Incremento B; demo en teléfono |
| Hilos | `Isolate` real | **Sin isolates**: el cómputo corre en el hilo principal | Búsqueda **cooperativa** que cede el control cada ~8 ms (sec. 6.5) |
| Peso inicial | APK | Motor de Flutter web pesa del orden de 1,5–2 MB | Pantalla de carga inmediata y datos diferidos (sec. 12.1) |
| Almacenamiento | Persistente | Puede estar bloqueado en incógnito | **Invitado funciona sin persistencia** (RF-33, RNF-17) |
| Offline de Firestore | Activo por defecto | Requiere habilitarse y es de una sola pestaña | No depender de él en el MVP |

### 5.5 Mapas y búsqueda (decisiones prácticas)
- **Teselas:** proveedor configurable por `dart-define`. El servidor público de OpenStreetMap **tiene política de uso** (no apto para tráfico intensivo, requiere atribución): válido para el evento, pero **dejar listo el cambio** a un proveedor con plan gratuito si se esperan muchos usuarios. ⚠️ Revisar términos al elegir.
- **Búsqueda de lugares (MVP):** **no se usa geocodificador remoto con autocompletado** (los servicios públicos gratuitos lo prohíben o lo limitan). Se busca sobre una **lista local** de paraderos/estaciones/hitos del eje (incluida en el dataset) y se permite **tocar el mapa** para fijar el punto. Geocodificación remota → 🔻 incremento.
- **Rendimiento del mapa:** ≤ 300 marcadores; agrupar a zoom bajo; polilíneas simplificadas en la **ingesta** (no en el dispositivo).

---

## 6. El motor de ruteo (`packages/routing_engine`)

### 6.1 Responsabilidad y frontera
**Entrada:** dataset (paraderos, rutas, tarifas) + solicitud (`origen`, `destino`, restricciones, saldo, posición a bordo opcional).
**Salida:** hasta 3 alternativas con tramos, costos, caminata, tiempo, transbordos, certidumbre y texto de tradeoff; **o** diagnóstico de infactibilidad con relajaciones mínimas.
**No hace:** red, disco, Firebase, UI, ni relojes del sistema (la hora entra como parámetro, para pruebas deterministas).

### 6.2 Interfaz pública (contrato estable)

```dart
abstract interface class PlannerGateway {
  Future<PlanResult> plan(PlanRequest request);
  Future<PlanResult> replan(ReplanRequest request);   // usa saldo restante
}

sealed class PlanResult {}
final class Feasible extends PlanResult { final List<Alternative> alternatives; final bool degraded; }
final class Infeasible extends PlanResult { final List<Blocker> blocking; final List<Relaxation> relaxations; }
```

Tipos principales (en `cyberon_domain`): `PlanRequest`, `Constraints {budgetCents, maxContinuousWalkM, maxTotalWalkM, allowTaxi, priority}`, `Alternative {label, totalCost(Money, Certainty), walkM, longestWalkM, durationMin, transfers, legs, tradeoffText}`, `Leg {type, from, to, geometry, distanceM, durationMin, routeCode?, cost?, certainty, boardingStop?}`, `Certainty {confirmed, estimated}`, `StopKind {officialAtu, osmCommunity, inferred}`.

> ✅ **Dinero en céntimos enteros** (`int`) en todo el dominio (RNF-08). Nunca `double`.

### 6.3 Algoritmo (resumen; detalle en el documento de contexto, sec. 5.5)
1. **Índice espacial** (cuadrícula) de paraderos para vecindades de caminata (R ≤ 800 m).
2. **Estados** = `(paradero, ruta_a_bordo | ninguna)`; la tarifa se cobra al **abordar**.
3. **Aristas:** `RIDE` (a lo largo de la ruta), `BOARD`, `ALIGHT`, `WALK`, `TAXI_BRIDGE` (generada perezosamente entre dos paraderos cuando la caminata supera el límite del usuario).
4. **Búsqueda multicriterio por etiquetas** (costo, caminata total, caminata continua, tiempo, transbordos) con **dominancia**, **poda por restricciones duras** y **tope `K` de etiquetas por estado**.
5. **Selección** de 3 representativas: *más barata*, *menos caminata*, *equilibrada* (relación metros ahorrados / soles gastados).
6. **Infactible →** reejecutar relajando **una restricción a la vez** y reportar los deltas mínimos (RF-10).
7. **Replanificación:** misma búsqueda desde la posición actual con `presupuesto − gastado_confirmado`; si está a bordo, solo bajadas en paraderos de esa ruta.

### 6.4 Estimaciones locales (MVP: sin OSRM)
| Magnitud | Cálculo MVP | Certidumbre | Tolerancia objetivo |
|---|---|---|---|
| Caminata | `haversine × 1,3` (factor de circuitidad) | `ESTIMATED` | ≤ 25 % (RNF-08) |
| Tiempo a pie | `distancia / 1,25 m/s` | `ESTIMATED` | — |
| Tiempo en vehículo | `distancia / velocidad_media_por_modo` | `ESTIMATED` | — |
| Espera | `headway_estimado / 2` por modo y franja | `ESTIMATED` | — |
| Taxi | `max(5,00; 3,50 + 1,25·km + 0,25·min) × factor_hora` | **siempre** `ESTIMATED` | — |

🔻 Refinamiento con un servicio de rutas (OSRM) solo para los **recorridos finalistas** y con caché, en un incremento; **no es prerrequisito** del MVP.

### 6.4.1 Honestidad de resultados
Cada `Alternative` lleva la lista de `warnings` (p. ej. "espera estimada", "paradero comunitario no verificado"); la UI **no puede ocultarlas** (RF-09). Una prueba automática verifica que **ningún importe ni paradero salga sin `Certainty`** (RNF-09, RNF-21).

### 6.5 Rendimiento y web (el detalle que más puede fallar en la demo)
- **Presupuesto de tiempo:** búsqueda ≤ **800 ms p50 / 2 s p95** en el dataset del eje (RNF-01), con tope duro de **3 s** y resultado parcial `degraded: true`.
- **En web no hay isolates:** el cálculo bloquearía la interfaz. → La búsqueda es **cooperativa**: procesa en lotes de ~8 ms y hace `await Future.delayed(Duration.zero)` entre lotes, de modo que la UI sigue respondiendo (RNF-04). En Android se puede usar un `Isolate`.
- **Presupuesto de memoria:** el grafo de un eje (≲ 5.000 paraderos) debe caber en **≲ 100 MB** en el dispositivo; medirlo (RNF-23).
- **Determinismo:** misma entrada → misma salida (desempates definidos), necesario para la demo y las pruebas.

> 🤖 **Reglas para el agente constructor:** (1) implementar y probar el motor **antes** que la UI; (2) los **10 viajes de oro** y los 6 casos obligatorios de RNF-21 son pruebas de aceptación del motor; (3) cero `print`/red/Firebase dentro del paquete; (4) cualquier umbral va en un objeto de configuración, no incrustado.

---

## 7. Datos estáticos de transporte

### 7.1 Por qué empaquetados y no en la base de datos
- Son **datos casi inmutables** (cambian de a pocos), pequeños y de lectura masiva: ponerlos en Firestore costaría **lecturas** (cuota) y latencia sin beneficio.
- Empaquetados: **cero lecturas**, **arranque instantáneo**, **funcionan sin conexión**, versionados en Git y **reproducibles** (el jurado ve de dónde vienen).
- Firestore queda para lo que **sí** necesita estado compartido.

### 7.2 Tubería de ingesta (offline, la corre el equipo)

```
 Overpass (OSM) ─┐
 Datos ATU ──────┼─▶ tools/ingest ──▶ normaliza ──▶ valida ──▶ data/build/lima_axis_vYYYYMMDD.json
 Curado a mano ──┘   (Dart/script)     (IDs, dedupe,   (informe)   (+ informe de calidad en data/build/REPORT.md)
 data/curated/*.json                    orden, simplifica)
```

**Pasos:**
1. Consulta Overpass sobre el bbox del eje y guarda el JSON **crudo con fecha** en `data/raw/`.
2. Normaliza rutas y paraderos (ids estables, orden de paradas, geometría simplificada).
3. Fusiona con `data/curated/` (rutas/paraderos curados a mano con `source`).
4. Valida (rutas sin paradas ordenadas, paraderos duplicados, tarifas sin fuente → `ESTIMATED`).
5. Genera el **dataset** y un **informe** (nº de rutas/paraderos, descartes) → se incluye en el repo.

### 7.3 Esquema del dataset (JSON)

```jsonc
{
  "dataVersion": "2026-10-17",
  "coverage": { "type": "Polygon", "coordinates": [ ... ] },
  "stops":  [ { "id": "s_001", "name": "...", "lat": -12.09, "lng": -77.03,
                "kind": "OFFICIAL_ATU|OSM_COMMUNITY", "source": "osm:node/123",
                "verifiedAt": "2026-10-17" } ],
  "routes": [ { "id": "r_az301", "code": "301", "name": "Corredor Azul", "mode": "CORREDOR",
                "fareCents": 250, "fareCertainty": "ESTIMATED", "fareSource": null,
                "headwayMin": 6, "avgSpeedKmh": 18,
                "stopIds": ["s_001","s_002", "..."],
                "polyline": "<codificada>" } ],
  "landmarks": [ { "id": "l_01", "name": "PUCP", "lat": -12.07, "lng": -77.08 } ],
  "demoTrips": [ { "id": "d1", "origin": {...}, "destination": {...}, "constraints": {...} } ]
}
```

- **Tamaño objetivo:** ≤ **1 MB** comprimido (gzip); se carga **después del primer pintado** (sec. 12.1).
- **Versionado:** `dataVersion` visible en la app (RNF-10); cada viaje del historial guarda la versión con la que se calculó (RF-34).

> 🤖 **Riesgo nº 1 técnico:** la calidad de rutas OSM en Lima. **Antes de escribir el motor completo**, correr Overpass sobre el eje y medir cobertura. Si es pobre, curar **4–8 rutas clave a mano** y documentarlo en `docs/DATA_SOURCES.md`. Datos curados y declarados **valen más** que datos "completos" inventados.

---

## 8. Firebase

### 8.1 Productos y para qué se usan

| Producto | Uso | Hito |
|---|---|---|
| **Authentication** | Invitado (anónimo), registro/login con correo, (opcional) proveedor externo | MVP-0 |
| **Cloud Firestore** | Perfil, historial, preferencias, eventos de tracción, reportes, paraderos inferidos, alertas | MVP-0/1; A/B |
| **Cloud Messaging (FCM)** | Notificaciones push por tema de ruta (alertas) | Incremento B |
| **Security Rules + Emulator Suite** | Autorización, pruebas locales de reglas | MVP-0 |
| **(Hosting)** | Alojamiento estático de la web (cualquier host estático sirve) | MVP-0 |

### 8.2 Identidad: invitado → cuenta (RF-31/32/33)

```
 Primera visita ──▶ inicio de sesión ANÓNIMO ──▶ uid_A  (invitado, usa todo el flujo)
                                                │
                  ┌─────────────────────────────┴───────────────────────────┐
                  ▼                                                         ▼
     Crea cuenta (correo/clave)                          Inicia sesión en cuenta EXISTENTE
     = VINCULAR credencial a uid_A                       = la cuenta ya tiene otro uid_B
     ✅ el uid NO cambia → el historial                  ⚠️ hay que MIGRAR los viajes de uid_A a uid_B
        de invitado ya es de la cuenta                      (copia por lote, con consentimiento)
```

- ✅ Con identidad anónima, **convertir a cuenta conserva el mismo `uid`**: por eso en Firebase **no hace falta** una tabla `AnonLink` salvo para el caso de "cuenta ya existente" (migración).
- ⚠️ Persistencia en incógnito: la sesión puede no recordarse al cerrar; **el flujo funciona igual** (RNF-17).
- **Correo verificado:** se solicita, **no bloquea** (RF-31).
- **Cuentas del equipo:** `isTeamMember = true` se marca **manualmente** (consola), nunca desde el cliente.

### 8.3 Modelo de datos de Firestore

> **Principios:** documentos pequeños; dinero en céntimos enteros; marcas de tiempo del servidor; **nada de datos personales en colecciones públicas**; lo que alimenta métricas es mínimo y seudónimo.

```
users/{uid}                              # privado: solo el dueño
  displayName?, email?, isAnonymous, isTeamMember, createdAt,
  privacyVersion, consent{guidance,telemetry,updatedAt},
  prefs{ defaultBudgetCents?, defaultMaxWalkM?, halfFare?, ... }

users/{uid}/trips/{tripId}               # historial (RF-34): privado
  createdAt, status(ACTIVE|COMPLETED|ABANDONED), dataVersion,
  origin{lat,lng,label}, destination{lat,lng,label},
  constraints{budgetCents,maxContinuousWalkM,maxTotalWalkM,allowTaxi,priority},
  selected{ ...instantánea de la Alternative... }, spentCents, replanCount,
  completedAt?, feedback{completed,fareMismatch?,stopMismatch?,comment?}?

users/{uid}/devices/{deviceId}           # Incremento B (push)
  fcmToken, platform, updatedAt

traction_users/{uidHash}                 # público de lectura; creación/actualización restringida
  firstSeen, lastSeen, activeDays, trips, replans, completed, external(bool), source(GUEST|ACCOUNT)

reports/{reportId}                       # solo creación: paradero/tarifa incorrectos (RF-14)
  kind(FARE|STOP), refId, text(≤300), createdAt, uidHash

config/app                               # lectura pública; escritura solo equipo
  dataVersion, minAppVersion, featureFlags{...}, teamHashes[...]

# Incremento A
telemetry_batches/{batchId}              # crear: sí (con consentimiento); leer: solo backend
  tripPseudonym, points[...≤200], isSimulated, createdAt, expireAt(TTL 7 días)
inferred_stops/{stopId}                  # lectura pública (solo visibles); escribe solo backend
  lat, lng, status(CANDIDATE|VISIBLE|QUARANTINED), confidence, nEff, routes[], updatedAt

# Incremento B
alerts/{alertId}                         # lectura pública; escribe solo backend
  routeCode?, title, summary, sourceUrl, publishedAt, verified, expireAt
```

**Notas de diseño:**
- **`uidHash`** = SHA-256 del `uid` calculado en el cliente: permite contar usuarios únicos **sin exponer el `uid`** en colecciones públicas.
- **Tracción sin servidor (MVP):** el cliente actualiza sus propios contadores en `traction_users/{uidHash}` con **reglas que solo permiten incrementos de 1 y un máximo por día**. El panel usa **consultas de agregación** (`count()`, `sum()`) — ⚠️ confirmar disponibilidad en la versión del SDK — sin leer documentos individuales.
- ⚠️ **Limitación honesta:** en el MVP un cliente malicioso podría falsear contadores. Se mitiga con reglas estrictas y se **declara**; en el **Incremento A/B** el backend pasa a validar y escribir los contadores (RF-36, "otras superficies").
- **Índices:** solo los necesarios (`trips` por `createdAt` descendente). Definidos en `firestore.indexes.json`.
- **TTL:** `telemetry_batches.expireAt` con política de TTL de Firestore (retención 7 días, RNF-13).

### 8.4 Reglas de seguridad (borrador; se prueba con el Emulator Suite)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {

    function signedIn()      { return request.auth != null; }
    function isOwner(uid)    { return signedIn() && request.auth.uid == uid; }
    function untouched(keys) { return !request.resource.data.diff(resource.data).affectedKeys().hasAny(keys); }

    match /users/{uid} {
      allow read:   if isOwner(uid);
      allow create: if isOwner(uid) && request.resource.data.isTeamMember == false;
      allow update: if isOwner(uid) && untouched(['isTeamMember','createdAt']);
      allow delete: if isOwner(uid);

      match /trips/{tripId} {
        allow read, delete: if isOwner(uid);
        allow create, update: if isOwner(uid)
          && request.resource.data.spentCents is int && request.resource.data.spentCents >= 0
          && request.resource.data.status in ['ACTIVE','COMPLETED','ABANDONED'];
      }
      match /devices/{id} { allow read, write: if isOwner(uid); }
    }

    match /traction_users/{h} {
      allow read: if true;                                   // solo contiene contadores y bandera
      allow create: if signedIn() && request.resource.data.keys().hasOnly(
        ['firstSeen','lastSeen','activeDays','trips','replans','completed','external','source']);
      allow update: if signedIn() && /* solo incrementos de +1 por escritura */ true;  // detallar y probar
      allow delete: if false;
    }

    match /reports/{id}   { allow create: if signedIn() && request.resource.data.text.size() <= 300;
                            allow read, update, delete: if false; }
    match /config/{doc}   { allow read: if true; allow write: if false; }

    // Incremento A/B: solo el backend (cuenta de servicio) escribe. El cliente no puede.
    match /inferred_stops/{id} { allow read: if resource.data.status == 'VISIBLE'; allow write: if false; }
    match /alerts/{id}         { allow read: if true; allow write: if false; }
    match /telemetry_batches/{id} { allow create: if signedIn() && request.resource.data.points.size() <= 200;
                                    allow read, update, delete: if false; }

    match /{document=**} { allow read, write: if false; }    // por defecto TODO denegado
  }
}
```

> 🤖 **Obligatorio:** reglas **versionadas en el repo** (`firebase/firestore.rules`) y **pruebas automatizadas con el Emulator Suite** de casos negativos: A no lee a B; invitado no lee cuentas; cliente no escribe `isTeamMember`, `confidence`, `nEff`, `status` de paraderos inferidos ni `config`; ráfagas rechazadas. **Todo denegado por defecto.** (RNF-29)

### 8.5 Notificaciones

**Dos mecanismos distintos, dos incrementos:**

| Mecanismo | Para qué | ¿Necesita servidor? | Plataforma | Hito |
|---|---|---|---|---|
| **Notificaciones locales** | "Siguiente paso", "Estás cerca de tu bajada", "¿Cómo te fue?" (30 min después, **programada en el dispositivo**) | **No** | Solo Android | **MVP-1** |
| **Push FCM por tema de ruta** | **Alertas de contingencia** (desvío/cierre) para quien tiene un viaje activo en esa ruta | **Sí** (quien envía debe ser de confianza) | Android (web poco fiable) | Incremento B |

- **Por qué locales primero:** la guía paso a paso no debe depender de red ni de un servidor; y el aviso "¿cómo te fue?" aporta **feedback y tracción** sin infraestructura.
- **FCM por temas:** al elegir una alternativa, la app se suscribe a `route_{code}` de cada ruta del viaje; el backend publica en el tema cuando crea una alerta verificada. **No se almacenan tokens en un servidor** (mínimo de datos). Se cancela la suscripción al terminar el viaje.
- ⚠️ En **web/incógnito** el push no es fiable: la demo de notificaciones se hace **en el teléfono** y el flujo web muestra la alerta **dentro de la pantalla** (RF-21).
- **Contenido de las notificaciones:** corto, sin datos personales, con acción "Abrir viaje".
- **Opt-in:** se pide permiso en un momento con contexto ("¿Quieres que te avise si hay desvíos en tu ruta?"), nunca al abrir la app.

### 8.6 Cuotas, costos y rendimiento de Firestore
- ⚠️ El plan gratuito tiene **cuotas diarias de lecturas/escrituras** (del orden de decenas de miles) y **las funciones en la nube suelen requerir plan de pago**: verificarlo **hoy** y decidir. Por eso: backend externo y datos estáticos fuera de Firestore.
- **Presupuesto de operaciones por viaje (MVP):** ≤ **10 escrituras** (viaje, actualizaciones de estado, contadores) y ≤ **5 lecturas** (perfil, config). Con 100 usuarios × 3 viajes ≈ 3.000 escrituras: holgado.
- **Evitar:** escuchar colecciones completas, escribir un documento por ping GPS, contar documentos en el cliente (usar agregaciones).
- **Telemetría (Incremento A):** **lotes de hasta 200 puntos por documento**, no un documento por ping; o envío directo al backend.

---

## 9. Backend ligero (Incrementos A/B)

### 9.1 Por qué existe (y por qué no antes)
Solo lo que **no se puede hacer con seguridad en el cliente**:

| Necesidad | Por qué no puede ir en el cliente |
|---|---|
| **Inferencia de paraderos de facto con defensas (RF-36)** | Un cliente puede mentir; la confianza debe calcularse donde nadie la pueda alterar |
| **Claves de Tavily/Exa/LLM/Zavu** | Las claves del cliente no son secretas |
| **Envío de push FCM** | Quien envía debe estar autenticado como servicio |
| **Agregados de tracción confiables** | Los contadores del cliente son falsificables |
| **Revertir lotes y bloquear fuentes** | Acción administrativa |

### 9.2 Tecnología y alojamiento
- **Recomendado:** **Dart** (servidor ligero con `shelf` o `dart_frog`) para **reutilizar** `routing_engine`, `cyberon_domain` y `stop_inference`; contenedor Docker alojado en **Maritime** (créditos del evento) u otro PaaS.
- **Acceso a Firebase desde el servidor:** cuenta de servicio con **mínimo privilegio**, a través de las APIs REST de Firestore y FCM. ⚠️ **Verificar** madurez de las librerías de Dart para estas APIs y verificación de tokens; **plan B:** backend en Node/TypeScript con el SDK oficial de administración (a costa de duplicar la lógica de `stop_inference`).
- **Hasta el Incremento A** el backend puede ser **un solo servicio** con dos tareas periódicas; no microservicios.

### 9.3 Endpoints (propuesta mínima)
| Endpoint | Auth | Función | Incremento |
|---|---|---|---|
| `GET /health` | pública | estado de grafo, Firestore e integraciones (RNF-19) | A |
| `POST /telemetry/batches` | ID token | recibe lotes, valida, descarta imposibles, guarda | A |
| `POST /plan`, `/replan` | ID token | mismo motor, respaldo del `LocalPlanner` | A (opcional) |
| `GET /alerts?route=` | ID token | alertas con fuente (caché 10–30 min) | B |
| `POST /nlp/parse-constraints` | ID token | LLM → JSON validado (RF-04) | B |
| `POST /admin/revert-batch`, `/admin/block-source` | rol admin | reversión (RF-36) | A |

- **Verificación de token** en cada llamada: firma, expiración, emisor y audiencia; claves públicas en caché (**≤ 50 ms** extra, RNF-28).
- **Límites de tasa y tamaño** (RNF-12), CORS restringido, errores con código estable.

### 9.4 Tareas periódicas
| Tarea | Frecuencia | Qué hace |
|---|---|---|
| `stop_inference` | 1–5 min | Procesa lotes → eventos de abordaje → agrupa (DBSCAN) → aplica filtros RF-36 → actualiza `inferred_stops` |
| `traction_rollup` | 5 min | Recalcula agregados validados (excluye simulados/equipo) |
| `alerts_refresh` | 15–30 min | Consulta Tavily/Exa, normaliza, guarda con fuente y caducidad |
| `ttl_cleanup` | diaria | Garantiza retención (RNF-13) |

### 9.5 Tubería de inferencia con defensas (RF-36 mapeado a etapas)

```
 lotes de telemetría
      │
      ▼
 [1] Higiene ───────────▶ descarta pings imposibles / mala precisión / desordenados   (Capa 2)
      ▼
 [2] Detección espera→abordaje ─▶ exige espera estática + salto + alineación con ruta (Capa 2)
      ▼
 [3] Independencia ─────▶ fusiona sesiones casi idénticas → n_eff (el "carrito" cuenta 1) (Capa 3)
      ▼
 [4] Agrupamiento ──────▶ DBSCAN en metros; topes por fuente y por día                (Capa 3)
      ▼
 [5] Cuarentena ────────▶ CANDIDATE hasta n_eff ≥ 3 + dispersión + persistencia        (Capa 4)
      ▼
 [6] Publicación ───────▶ VISIBLE (siempre "inferido", con confianza que decae)        (Capa 4)
      ▼
 [7] Auditoría ─────────▶ REASON_CODE por descarte; reversión por lote                 (Capa 4)
```

- **Garantía de diseño (Capa 1):** el **ruteo no usa velocidades ni densidades de usuarios**; los paraderos inferidos nunca reemplazan a los oficiales y entran al ruteo solo con aceptación del usuario.
- Cada etapa es una **función pura** en `packages/stop_inference`, con pruebas de ataque ("carrito", "carrito + auto", "bots dispersos") y control positivo (RNF-30).

> 🤖 **Si el tiempo no alcanza para el backend:** el detector se muestra como **simulador en la UI** (rotulado `SIMULADO`, ejecutando `stop_inference` localmente sobre trazas sintéticas) y se declara explícitamente "inferencia en producción = alcance futuro". **No** se acepta telemetría real sin las defensas [P0] de RF-36.

---

## 10. Flujos clave

### 10.1 Planificar (MVP, sin red salvo el dataset)
```
Usuario ─▶ S1 origen/destino ─▶ S2 condiciones ─▶ [Ver opciones]
   UI ─▶ PlannerGateway.plan(req) ─▶ LocalPlanner ─▶ routing_engine.search(dataset, req)
   routing_engine ─▶ Feasible(3 alternativas) | Infeasible(relajaciones)
   UI ─▶ S3 comparar (o S4 infactible) ; registra evento PLAN (traction_users +1)
```
Sin llamadas de red en el cálculo → **latencia local** (RNF-01) y funciona sin conexión.

### 10.2 Seleccionar y seguir (RF-11/12)
```
S3 ─▶ [Elegir] ─▶ trips_repo.create(status=ACTIVE, selected=snapshot, dataVersion)
S5 revisión ─▶ [Empezar] ─▶ S6 seguimiento (avance manual o por proximidad si hay GPS)
S6 ─▶ notificación local programada: "¿Cómo te fue?" (+30 min)  [solo móvil]
```

### 10.3 Replanificar con saldo restante (RF-13)
```
S6 ─▶ [Algo cambió] ─▶ S7 (monto gastado + posición)
UI ─▶ gastado confirmado ─▶ saldo = presupuesto − gastado
UI ─▶ PlannerGateway.replan(posición, saldo, aBordo?) ─▶ motor ─▶ nuevas alternativas
trips_repo.update(replanCount+1, spentCents) ; evento REPLAN
```
Idempotencia: `request_id` por acción; doble toque no duplica descuentos (RNF-25).

### 10.4 Invitado → cuenta (RF-33)
```
Arranque ─▶ sign-in anónimo ─▶ uid_A
Tras 1.er viaje completado ─▶ invitación NO bloqueante "Guarda tu historial"
 a) Crear cuenta   ─▶ vincular credencial a uid_A (mismo uid) ─▶ historial intacto
 b) Entrar a cuenta existente (uid_B) ─▶ preguntar "¿fusionar viajes de invitado?"
      sí ─▶ copiar users/uid_A/trips/* a users/uid_B/trips/* (lote) ─▶ listo
```

### 10.5 Historial (RF-34)
```
"Mis viajes" ─▶ trips_repo.list(uid, orderBy createdAt desc, limit 20, cursor)
Detalle ─▶ muestra snapshot + dataVersion (no cambia aunque el dataset cambie)
"Repetir" ─▶ precarga S1/S2 ─▶ recalcula con dataset ACTUAL
```

### 10.6 Notificación push de alerta (Incremento B)
```
alerts_refresh ─▶ Tavily/Exa ─▶ normaliza + fuente ─▶ alerts/{id} (verified según dominio oficial)
backend ─▶ FCM al tema route_{code} ─▶ app (móvil) ─▶ notificación "Desvío en Corredor Azul" ─▶ abre viaje
App web ─▶ muestra la alerta en la tarjeta de la alternativa (sin push)
```

### 10.7 Telemetría → paradero inferido (Incremento A)
```
Cliente (con consentimiento) ─▶ lotes ≤ 200 pings ─▶ POST /telemetry/batches (ID token)
backend ─▶ higiene ─▶ guarda lote (TTL 7 d) ─▶ [tarea 1–5 min] pipeline 9.5 ─▶ inferred_stops
Cliente ─▶ lee inferred_stops (status=VISIBLE) ─▶ capa 🟡 "inferido (confianza X %)"
```

---

## 11. Seguridad y privacidad

### 11.1 Mapa de amenazas resumido (detalle en `docs/THREAT_MODEL.md`, RNF-30)

| Amenaza | Vector | Defensa en la arquitectura |
|---|---|---|
| **Envenenamiento con ubicaciones falsas** ("carrito de teléfonos") | Muchos teléfonos simulando espera/abordaje | Ruteo **sin** señal colaborativa; plausibilidad física; `n_eff`; cuarentena; reversión (RF-36) |
| **Falsificar tracción** | Contadores o eventos inventados | Reglas estrictas en MVP; backend valida desde Incremento A; exclusión de equipo/simulados |
| **Acceso cruzado a datos** | Cliente intenta leer viajes de otro | Reglas por `uid`, todo denegado por defecto, pruebas negativas |
| **Fuga de secretos** | Claves en repo/cliente | Claves solo en servidor; escáner de secretos; `.env.example` |
| **Inyección vía texto** | Texto libre/NL/alertas web | Esquemas estrictos; el texto externo es **dato**, no instrucción |
| **Abuso de la API** | Ráfagas, cuerpos enormes | Límites de tasa y tamaño; `429` controlado |
| **Reidentificación por GPS** | Cruzar trazas con cuenta | Trazas con **seudónimo de viaje**, nunca `uid`; agregados con `n_eff ≥ 3`; TTL 7 días |

### 11.2 Privacidad por diseño
- **Datos mínimos:** correo (si hay cuenta), viajes (origen/destino/recorrido), preferencias. **Sin** teléfono ni trazas en el historial.
- **Dos consentimientos separados:** usar ubicación para guiar ≠ compartir trazas para mejorar el mapa (RF-29).
- **Colecciones públicas** solo con contadores o datos agregados (`traction_users`, `inferred_stops` visibles, `alerts`, `config`).
- **Borrado:** MVP → cierre de sesión y procedimiento documentado; Incremento C → eliminación de cuenta con cascada (RF-35).
- **App Check:** ⚠️ opcional en Incremento B (reduce tráfico no proveniente de la app, pero añade fricción en web/incógnito; evaluar antes de activar).

### 11.3 Gestión de secretos
| Secreto | Dónde vive | Dónde **nunca** |
|---|---|---|
| Cuenta de servicio de Firebase | Secreto del backend | Repo, cliente, bitácora |
| Claves Tavily/Exa/LLM/Zavu | Variables de entorno del backend | Cliente |
| Códigos de `andes credits` | Gestor local del equipo | Repo, descripción, avances |
| Configuración pública de Firebase (cliente) | Código/`dart-define` | — (no es secreta, **por eso** la seguridad está en las reglas) |

---

## 12. Rendimiento, resiliencia y degradación

### 12.1 Presupuestos (ajustes frente a los requerimientos por Flutter web)

> **Ajuste de RNF-03:** el motor de Flutter web es pesado; las metas originales (≤ 1,5 MB, TTI ≤ 5 s) eran para web "ligera". Para Flutter web se redefine: **pantalla de carga HTML visible en ≤ 1,5 s**, **TTI ≤ 8 s en 4G simulada** y **≤ 4 s en banda ancha** (equipo del jurado), peso inicial **≲ 4 MB comprimido**, dataset y mapa **diferidos** tras el primer pintado. ⚠️ **Medir con Lighthouse** y registrar el valor real (RNF-24).

| Magnitud | Meta (MVP) | Cómo se logra |
|---|---|---|
| `plan` (local) | p50 ≤ 800 ms · p95 ≤ 2 s · tope 3 s | Grafo en memoria, `K` acotado, índice espacial |
| `replan` (local) | p95 ≤ 2 s | Misma búsqueda, saldo reducido |
| Cambio de alternativa en el mapa | ≤ 300 ms | Sin recalcular |
| FPS del mapa | ≥ 30 fps | Marcadores ≤ 300; polilíneas simplificadas en ingesta |
| Arranque del dataset | ≤ 2 s tras primer pintado | Carga diferida + `compute` en móvil |
| Escrituras Firestore por viaje | ≤ 10 | Lotes; contadores acotados |

### 12.2 Modos de degradación (qué se ve cuando algo falla)

| Falla | Efecto | Comportamiento |
|---|---|---|
| Sin red | Sin Firestore/Auth | La **planificación sigue** (motor local); el viaje se guarda local y se sincroniza al volver |
| Firestore caído / cuota agotada | Sin historial/tracción | Planificar y seguir **funcionan**; aviso discreto "no se guardará tu historial ahora" |
| Auth no disponible | Sin cuenta | Modo **invitado/demo** local; el flujo P0 completo opera |
| Backend caído (Inc. A/B) | Sin alertas/NLP/inferencia nueva | `LocalPlanner` responde; alertas ocultas; controles manuales; paraderos inferidos en caché |
| Dataset corrupto | No hay motor | La app **rechaza** el dataset (validación al cargar) y muestra error claro; nunca calcula con datos inválidos |
| GPS denegado | Sin ubicación | Entrada manual / modo demo |

> 🎯 **Prueba obligatoria antes de entregar:** con **Firebase y el backend desactivados**, el flujo "planificar → comparar → infactible → seguir → replanificar" en **modo demo** debe funcionar completo (RNF-07).

---

## 13. Pruebas y calidad

### 13.1 Pirámide

| Nivel | Qué | Herramienta | Obligatorio |
|---|---|---|---|
| **Unitarias del motor** | Pareto, relajación, replan, taxi que **no** debe aparecer, caminata > límite, presupuesto < tarifa | `test` (Dart puro) | ✅ MVP-0 (cobertura ≥ 80 % del paquete) |
| **Viajes de oro** | 10 viajes con resultado esperado | `test` | ✅ MVP-0 |
| **Honestidad de datos** | Ningún importe/paradero sin `Certainty`; simulado rotulado | `test` | ✅ MVP-0 |
| **Reglas de Firestore** | Casos negativos de acceso cruzado y campos protegidos | Emulator Suite | ✅ MVP-0 |
| **Widgets** | Formularios, estados vacío/error/carga, chips de certidumbre | `flutter_test` | ✅ MVP-1 |
| **Humo extremo a extremo** | Plan → seleccionar → replan → completar, en modo demo, contra el despliegue | `integration_test` o guion manual | ✅ antes de entregar |
| **Ataque (Inc. A)** | "carrito", "carrito + auto", "bots dispersos" + control positivo | `test` | ✅ si se activa Motor 2 |
| **Rendimiento** | Medición de `plan` y de carga web (Lighthouse) | scripts | ✅ MVP-1 (RNF-24) |

### 13.2 Integración continua
`.github/workflows/ci.yml`: `flutter pub get` → `dart format --set-exit-if-changed` → `flutter analyze` (0 avisos) → `dart test` (motor) → `flutter test` → pruebas de reglas con el emulador → `flutter build web` → (en rama principal) despliegue.

### 13.3 Calidad del repositorio (lo que revisa el jurado)
Capas claras, tipado estricto, `analysis_options.yaml` estricto, commits pequeños y descriptivos, README con **diagrama de arquitectura**, `docs/` (ARQUITECTURA, DECISIONES, DATA_SOURCES, PRIVACY, THREAT_MODEL si hay Motor 2, PERFORMANCE), `.env.example`, **0 secretos**.

---

## 14. Despliegue y entornos

### 14.1 Entornos
| Entorno | Para qué | Datos |
|---|---|---|
| **Local (Emulator Suite)** | Desarrollo y pruebas de reglas | Sintéticos |
| **Producción** | Lo que ve el jurado | Reales del evento |

> 🔻 Un tercer entorno "staging" **no** vale la pena en 18 h; en su lugar, **proyecto de Firebase de pruebas separado** si hay tiempo.

### 14.2 Artefactos y publicación
| Artefacto | Cómo | Cuándo |
|---|---|---|
| **Web** (`flutter build web`) | Hosting estático HTTPS con compresión y caché de activos | Primer despliegue en **H+9–10**, luego continuo |
| **APK Android** | `flutter build apk` distribuido por enlace directo | Extra; no sustituye a la URL pública |
| **Reglas e índices** | `firebase deploy --only firestore` | Con cada cambio, tras pasar las pruebas |
| **Backend** (Inc. A/B) | Contenedor Docker en Maritime u otro PaaS | Con su incremento |

### 14.3 Lista de verificación de despliegue (todo verdadero antes de `submit`)
- [ ] URL pública HTTPS abre en **ventana privada, otro equipo, sin localhost**.
- [ ] Flujo P0 completo **sin registrarse** y **en modo demo sin GPS**.
- [ ] Reglas desplegadas; pruebas negativas en verde.
- [ ] `dataVersion` visible; dataset validado.
- [ ] Sin claves en el repo; `.env.example` presente.
- [ ] Panel de tracción lee datos reales y excluye equipo y simulados.
- [ ] Respaldo de configuración y **procedimiento de rollback** (volver al despliegue anterior en ≤ 10 min).
- [ ] **Congelamiento** de cambios arriesgados a las 07:00.

---

## 15. Registro de decisiones (ADR)

| # | Decisión | Alternativas | Por qué | Consecuencia / riesgo |
|---|---|---|---|---|
| ADR-01 | **Flutter** para móvil y web | Web aparte + app aparte | Un código; la regla del evento exige URL pública | Peso de Flutter web; sin push fiable en web |
| ADR-02 | **Motor en Dart puro compartido** | Motor en Node/Python | Un solo lenguaje; reutilizable en app y backend; testeable | Ecosistema de servidor Dart más joven (Inc. A) |
| ADR-03 | **Motor en el cliente en el MVP** | Backend desde el día 1 | Menos piezas, sin latencia de red, funciona offline, sin hosting que falle | Datos viajan al cliente; la validación fuerte vendrá con backend |
| ADR-04 | **Dataset empaquetado**, no en Firestore | Datos en la base | Cero lecturas, versionado, reproducible | Actualizar datos exige nueva publicación (aceptable) |
| ADR-05 | **Sin PostGIS/OSRM/geocodificador remoto** en MVP | Pila geoespacial completa | No hacen falta para el corte vertical | Estimaciones `ESTIMATED` de caminata/taxi (honestas) |
| ADR-06 | **Firestore** para usuario, historial y tracción | Postgres | Decisión del equipo; encaja con Auth y reglas | Sin geoconsultas ni agregados complejos → se resuelven con diseño |
| ADR-07 | **Tracción con contadores del cliente + reglas** en MVP | Backend desde ya | Evita servidor en MVP | **Falsificable**; se declara y se pasa al backend en Inc. A |
| ADR-08 | **Notificaciones locales** en MVP; **FCM por temas** en Inc. B | FCM desde el inicio | El valor de MVP no necesita servidor | Push solo demostrable en teléfono |
| ADR-09 | **Backend externo** (Maritime/PaaS) | Funciones en la nube | ⚠️ Las funciones suelen requerir plan de pago; créditos de Maritime | Una pieza más de operación (solo Inc. A/B) |
| ADR-10 | **`flutter_map`** | Mapas de un proveedor con clave | Sin clave obligatoria; web y móvil | Cumplir política de teselas; cambio fácil de proveedor |
| ADR-11 | **Búsqueda local + toque en mapa** | Geocodificación remota | Los servicios gratuitos no permiten autocompletar a este uso | Menos cómodo; suficiente para un eje |
| ADR-12 | **Riverpod + go_router** | Bloc / Navigator 1.0 | Menos *boilerplate*, fácil de probar, URLs web | Curva si el equipo no lo conoce |
| ADR-13 | **Identidad anónima → cuenta** | Login obligatorio | El jurado no se registrará; conserva historial | Caso "cuenta existente" exige migración |
| ADR-14 | **Inferencia solo en servidor** | Detector en el cliente | El cliente no es confiable (RF-36) | Sin backend no hay Motor 2 real → simulador |

---

## 16. Trazabilidad requerimientos → arquitectura

| Requerimiento | Componente(s) | Hito |
|---|---|---|
| RF-01, 02 | `features/plan` + `core` (cobertura del dataset) | MVP-0 |
| RF-03 | `features/plan` (S2) | MVP-0 |
| RF-04 | `RemotePlanner`/`/nlp` en backend | Inc. B |
| RF-05, 06, 07, 10 | `routing_engine` | MVP-0 |
| RF-08, 09 | `features/plan` (S3, chips) + `Alternative` | MVP-0 |
| RF-11, 12, 13 | `features/trip` + `PlannerGateway.replan` | MVP-0/1 |
| RF-14 | `features/trip` (S8) + `reports` | MVP-1 |
| RF-15 | `features/plan` (mapa) + dataset | MVP-0 |
| RF-16, 17, 18, 19, 36 | `stop_inference` + backend + `telemetry_batches`/`inferred_stops` | Inc. A |
| RF-20 | `features/demo` + `demoTrips` | MVP-1 |
| RF-21 | backend `/alerts` + `alerts` + FCM | Inc. B |
| RF-22, 23 | `events_repo` + `traction_users` + `features/traction` | MVP-1 |
| RF-24, 25 | `tools/ingest` + dataset | MVP-0 |
| RF-26, 27, 28 | AtomicMemory / Zavu / n8n vía backend | Inc. B/C |
| RF-29 | `users.consent` + pantallas de consentimiento | MVP-1 |
| RF-30 | CI, `andes project …`, docs | MVP-1 |
| RF-31, 32, 33, 34 | `features/auth`, `features/history`, Firebase Auth + `trips` | MVP-0 |
| RF-35 | `features/auth` (cerrar sesión) · cascada de borrado | MVP-1 / Inc. C |
| RNF-01, 02, 04, 23 | Motor cooperativo, grafo en memoria | MVP-0 |
| RNF-03 | Carga diferida, ajuste Flutter web | MVP-0/1 |
| RNF-05, 06, 07 | Degradación (sec. 12.2), reglas, host estático | MVP-1 |
| RNF-08, 09 | Dinero en céntimos, `Certainty`, pruebas | MVP-0 |
| RNF-11, 12, 28, 29, 30 | Secretos, reglas, verificación de tokens, ataque | MVP-0 / Inc. A |
| RNF-13 | Seudónimos, TTL, consentimientos | MVP-1 / Inc. A |
| RNF-14, 15, 16, 26 | `core/ui`, `core/i18n` | MVP-0 |
| RNF-17 | Invitado sin persistencia, modo demo | MVP-0 |
| RNF-19, 20, 21, 22, 24, 25, 27 | CI, estructura, pruebas, docs | MVP-0/1 |

---

## 17. Plan de construcción (MVP primero)

> Referencia: **H0** = inicio de construcción tras las decisiones de la sec. 18. Hay ~**18 h** hasta las 09:00. Tres frentes en paralelo.

### 17.1 Frentes

| Frente | Responsabilidad | Paquetes |
|---|---|---|
| **A · Datos y motor** | Ingesta, dataset, `routing_engine`, pruebas de oro | `tools/ingest`, `routing_engine`, `cyberon_domain` |
| **B · App Flutter** | Pantallas S1–S8, mapa, estado, modo demo | `apps/cyberon_app` |
| **C · Firebase, calidad y entrega** | Auth, Firestore, reglas + emulador, tracción, CI, despliegue, docs, bitácora | `firebase/`, `.github/`, `docs/` |

### 17.2 Cronograma (con líneas de corte)

| Hora | Frente A | Frente B | Frente C | Salida verificable |
|---|---|---|---|---|
| **H0–H1** | Elegir eje; Overpass del eje; medir cobertura | Crear proyecto Flutter, estructura, tema, rutas | Crear proyecto Firebase, `flutterfire`, emulador; **aclarar rúbrica en Discord**; canjear créditos útiles | Decisiones en `DECISIONS.md`; 1.er `project update` |
| **H1–H4** | Dataset v1 + informe; curar rutas faltantes | Modelos de dominio (`cyberon_domain`), S1/S2 con mapa y búsqueda local | Auth anónima + registro/login; reglas v1 + pruebas negativas | Dataset en repo; formularios funcionando |
| **H2–H7** | **Motor**: grafo, búsqueda, Pareto, taxi, relajación; 10 viajes de oro | S3/S4 sobre **fakes** del motor, luego conectar `LocalPlanner` | `trips_repo`, historial, invitado→cuenta | **Motor con pruebas en verde** |
| **H7–H10** | Afinar con datos reales; rendimiento | S5, S3 completa, certidumbre, errores | **Primer despliegue web público**; CI; prueba en incógnito | 🚩 **Corte H+10: MVP-0 desplegado** |
| **H10–H13** | Replan con saldo, casos borde | S6/S7/S8, modo demo, notificaciones locales | Eventos + `traction_users` + panel S9; consentimiento; README | 🚩 **Corte H+13: MVP-1 completo** |
| **H13** | — | — | **`andes project submit` v1** + prueba en otro equipo | **Entrega v1 registrada** |
| **H13–H17** | Incremento A: `stop_inference` + pruebas de ataque | Capa 🟡 y simulador en UI | Backend ligero, `telemetry_batches`, reglas A | Motor 2 (o solo simulador) |
| **H17–H18** | Congelar; ensayo del pitch ×3 | Pulido de UI | Revisión de secretos, rollback, `submit` final | Todo en verde antes de las **07:00** |

### 17.3 Definición de "hecho" por hito
- **MVP-0 hecho** = viaje de ejemplo completo en la **URL pública en incógnito**, sin registrarse, con 3 alternativas o infactibilidad con relajación, certidumbre visible, historial guardado, pruebas del motor y de reglas en verde.
- **MVP-1 hecho** = lo anterior + seguimiento, replan con saldo, feedback, panel de tracción con datos reales, modo demo, README/descripción/slides, **entrega registrada**.

---

## 18. Riesgos y preguntas abiertas

### 18.1 Riesgos (ordenados por gravedad)
| # | Riesgo | Mitigación |
|---|---|---|
| 1 | **Calidad de datos de rutas** (OSM/ATU) | Medir cobertura en H0–H1; curar a mano; documentar fuentes |
| 2 | **Demo fallida** en PC ajena (URL, incógnito, permisos, peso de Flutter web) | Modo demo; prueba en otro equipo; carga diferida; ensayo |
| 3 | **Sobrealcance** | Líneas de corte (2.3); incrementos recortables |
| 4 | **Cuotas/costos de Firebase** (plan gratuito, funciones de pago) | Verificar hoy; datos estáticos fuera; backend externo |
| 5 | **Tracción falsificable en MVP** | Reglas estrictas + declararlo + backend en Inc. A |
| 6 | **Rúbrica ambigua** (guía vs. deck) | Preguntar a la organización; construir para ambas |
| 7 | **Motor 2 sin backend** | Simulador rotulado + declararlo alcance futuro |
| 8 | **Rendimiento del motor en web** (sin isolates) | Búsqueda cooperativa, `K` acotado, topes de tiempo |
| 9 | **Librerías de Dart para APIs de Firebase en servidor** | Verificar; plan B Node/TS |
| 10 | **Fuga de secretos** | Escáner, claves solo en servidor, rotación inmediata |

### 18.2 Preguntas abiertas (necesito respuesta del equipo)
1. **¿Qué eje de Lima?** (condiciona dataset, demo y tracción).
2. **¿Cuántas personas y qué dominan?** (reparto de frentes; ¿alguien conoce Dart en servidor?).
3. **¿Plan de Firebase** (gratuito o de pago)? Define si el backend va en Maritime y cuánto cuidar las cuotas.
4. **¿Qué rúbrica rige?** (guía vs. deck) y **¿pueden subir el PDF** a esta carpeta?
5. **¿Habrá teléfonos Android** para probar GPS y notificaciones locales en vivo?
6. **¿Política de invitados**: historial solo en el dispositivo o con retención (p. ej. 30 días)?

---

## 19. Reglas duras para el agente constructor

> Resumen operativo. Léelas antes de escribir código.

1. **Motor primero, con pruebas.** `routing_engine` es Dart puro; sin Flutter, red ni Firebase. Viajes de oro y casos de RNF-21 en verde antes de conectar la UI.
2. **Dinero en céntimos enteros.** Nunca `double` para importes.
3. **`Certainty` en todo importe y paradero**; lo simulado, rotulado `SIMULADO`. Prueba automática que lo verifique.
4. **El login nunca es obligatorio.** Invitado y modo demo funcionan sin registro, sin GPS y en incógnito.
5. **La UI no importa Firebase.** Todo pasa por repositorios (interfaces) y `PlannerGateway`.
6. **Reglas de Firestore: todo denegado por defecto**, versionadas y probadas con casos negativos.
7. **Nada de claves secretas en el cliente ni en el repo.** Las claves de terceros viven solo en el backend.
8. **Datos estáticos empaquetados y versionados**; mostrar `dataVersion`; rechazar dataset inválido.
9. **No aceptar telemetría real sin las defensas [P0] de RF-36.** Sin backend, solo simulador.
10. **No fabricar tracción.** Contadores solo por uso real; excluir equipo y simulados; declarar la limitación del MVP.
11. **Respetar las líneas de corte** (H+10, H+13). Nada de incrementos sin MVP desplegado.
12. **Entrega temprana (H+13)** y mejoras después; congelar a las 07:00.
13. **Medir antes de afirmar** (RNF-24): registrar en `docs/PERFORMANCE.md` las cifras reales.
14. **Documentar lo que no se hizo** (README: "qué quedó fuera") y las decisiones (`DECISIONS.md`).

---

*Fin del documento. Para el detalle de cada requerimiento ver [cyberon-requerimientos.md](cyberon-requerimientos.md); para el contexto del problema y los sponsors, [cyberon-contexto-completo.md](cyberon-contexto-completo.md).*
