# Cyberon — Especificación de requerimientos del sistema

**Proyecto:** Cyberon (Hack the Andes, track `transport`) · **Versión:** 3 (agrega cuentas, sesiones e historial: RF-31 a RF-35, RNF-28 y RNF-29; y resistencia a manipulación de datos colaborativos: RF-36 y RNF-30) · **Fecha:** 17/10/2026
**Documento hermano:** [cyberon-contexto-completo.md](cyberon-contexto-completo.md) (contexto, problema, solución, sponsors, notas para el agente constructor). Este archivo se enfoca **solo en requerimientos**.

---

## 0. Cómo leer este documento

### 0.1 Estructura de cada requerimiento
Cada requerimiento sigue exactamente este formato:
1. **Título**
2. **Descripción**
3. **Criterios de aceptación** (verificables; formato *Dado / Cuando / Entonces* o condición medible)
4. **Historia de usuario**
5. **Datos que intervienen**

Bajo el título se indica una línea de metadatos: **Prioridad** (P0 imprescindible · P1 diferenciador · P2 opcional), **Tipo** y **Trazabilidad** (a qué parte del contexto responde).

### 0.2 Convenciones
- **RF-xx** = requerimiento funcional. **RNF-xx** = requerimiento no funcional.
- **Prioridades:** P0 = sin esto no hay demo; P1 = fuerte diferenciador; P2 = solo si sobra tiempo.
- **Valores numéricos de los RNF** (latencias, tamaños, umbrales) son **metas propuestas** para un hackatón de ~18 h, **no mediciones**. Deben medirse y ajustarse (ver RNF-24).
- **Etiquetas de certidumbre:** `CONFIRMED` (con fuente y fecha) y `ESTIMATED`.
- **Entidades de datos** referidas (detalladas en la sección 4 y en el esquema SQL del documento de contexto, sec. 8.3): `TripSession`, `Alternative`, `Leg`, `TransitStop`, `TransitRoute`, `RouteStop`, `GpsPing`, `Event`, `TripFeedback`, `Alert`, `UserPreference`.

### 0.3 Glosario
| Término | Significado |
|---|---|
| Tramo puente | Segmento corto en taxi insertado entre dos puntos de transporte público para evitar una caminata o transbordo difícil |
| Caminata continua | Metros caminados sin interrupción en un solo tramo a pie |
| Costo hundido / saldo restante | Dinero ya gastado en el viaje; saldo = presupuesto inicial − gastado |
| Paradero de facto | Punto no oficial inferido por GPS donde usuarios esperan y abordan |
| Frontera de Pareto | Conjunto de alternativas no dominadas en costo, caminata, tiempo y transbordos |
| Relajación mínima | Menor cambio en una restricción que haría factible un viaje imposible |
| Usuario externo | Persona que no pertenece al equipo de desarrollo (cuenta para tracción) |
| Usuario registrado | Persona con cuenta (`user_id`); su historial y preferencias persisten entre dispositivos |
| Invitado | Persona que usa la app sin cuenta, con identidad anónima (`anon_session_id`) |

### 0.4 Índice
**Funcionales:** RF-01 Origen/destino · RF-02 Cobertura geográfica · RF-03 Condiciones del viaje · RF-04 Lenguaje natural · RF-05 Cálculo multimodal · RF-06 Tramo puente en taxi · RF-07 Tres alternativas · RF-08 Comparación y tradeoffs · RF-09 Certidumbre · RF-10 Infactibilidad y relajación · RF-11 Selección y revisión previa · RF-12 Seguimiento del viaje · RF-13 Replanificación con saldo · RF-14 Finalización y feedback · RF-15 Mapa de paraderos · RF-16 Telemetría GPS · RF-17 Detección de abordaje · RF-18 Paraderos de facto · RF-19 Simulador de trazas · RF-20 Modo demo · RF-21 Alertas de contingencia · RF-22 Eventos y sesiones · RF-23 Panel de tracción · RF-24 Ingesta de datos · RF-25 Tarifas · RF-26 Memoria de preferencias · RF-27 Canal de mensajería · RF-28 Refresco automático · RF-29 Consentimiento y privacidad · RF-30 Entrega y bitácora del proyecto · RF-31 Registro · RF-32 Inicio de sesión y sesión persistente · RF-33 Invitado y vinculación · RF-34 Historial de viajes · RF-35 Gestión de cuenta · RF-36 Integridad de telemetría y resistencia al envenenamiento de datos

**No funcionales:** RNF-01 Latencia de planificación · RNF-02 Latencia de recálculo · RNF-03 Carga inicial · RNF-04 Fluidez del mapa · RNF-05 Concurrencia · RNF-06 Disponibilidad de la demo · RNF-07 Tolerancia a fallos externos · RNF-08 Precisión de cálculos · RNF-09 Integridad y honestidad de datos · RNF-10 Frescura de datos · RNF-11 Seguridad de secretos · RNF-12 Validación y seguridad de entradas · RNF-13 Privacidad de ubicación · RNF-14 Usabilidad móvil · RNF-15 Claridad del lenguaje · RNF-16 Accesibilidad básica · RNF-17 Compatibilidad · RNF-18 Consumo de datos y batería · RNF-19 Observabilidad · RNF-20 Mantenibilidad y calidad de código · RNF-21 Pruebas · RNF-22 Despliegue y reproducibilidad · RNF-23 Escalabilidad del motor · RNF-24 Medición y benchmarks · RNF-25 Idempotencia y consistencia · RNF-26 Localización (es-PE) · RNF-27 Documentación · RNF-28 Seguridad de autenticación y sesiones · RNF-29 Autorización y aislamiento de datos · RNF-30 Resistencia a manipulación y acotación del daño

---

# PARTE I — REQUERIMIENTOS FUNCIONALES

## A. Definición del viaje

### RF-01 — Selección de origen y destino
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Flujo paso 1; pantalla S1.

**1. Título:** Selección de origen y destino.

**2. Descripción:** El sistema permite al usuario indicar el punto de salida y el de llegada mediante búsqueda por texto con autocompletado, toque directo en el mapa o uso de su ubicación actual. El usuario debe confirmar visualmente ambos puntos antes de continuar.

**3. Criterios de aceptación:**
- **Dado** que el usuario escribe al menos 3 caracteres, **cuando** pausa 300 ms, **entonces** se muestran sugerencias de lugares dentro del área cubierta.
- **Dado** que toca un punto del mapa, **cuando** suelta, **entonces** aparece un marcador con la dirección aproximada y un botón "Confirmar".
- **Dado** que concede permiso de ubicación, **cuando** pulsa "Usar mi ubicación", **entonces** el origen se fija en su posición con precisión mostrada (±m).
- **Dado** que rechaza el permiso o no hay GPS, **entonces** puede fijar el origen manualmente sin que la app falle.
- No se puede avanzar a la pantalla de condiciones sin origen **y** destino confirmados.
- Se puede intercambiar origen y destino con un solo control.
- El origen y el destino iguales (o a < 100 m) muestran el mensaje "Puedes ir caminando (X m)" y no inician el cálculo multimodal.

**4. Historia de usuario:** *Como pasajera que sale de clases, quiero indicar de dónde salgo y adónde voy con pocos toques, para empezar a comparar mis opciones de viaje sin escribir direcciones largas.*

**5. Datos que intervienen:** `origin {lat, lng, label, accuracy_m, source: GPS|MAP|SEARCH}`, `destination {lat, lng, label}`, resultados de geocodificación (nombre, coordenadas), permiso de ubicación (`granted|denied`), `session_id` anónimo.

---

### RF-02 — Cobertura geográfica y validación de zona
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Alcance negativo (el sistema cubre un eje acotado).

**1. Título:** Validación de cobertura geográfica.

**2. Descripción:** El sistema define un área de cobertura (eje de Lima acotado por un polígono/bounding box) y rechaza o advierte cuando origen o destino quedan fuera, indicando qué zona sí está cubierta.

**3. Criterios de aceptación:**
- **Dado** un origen o destino fuera del polígono de cobertura, **cuando** el usuario intenta continuar, **entonces** se muestra un mensaje claro ("Aún cubrimos el eje X–Y") y el área cubierta resaltada en el mapa; no se ejecuta el cálculo.
- **Dado** un punto dentro del área pero a > 800 m del paradero más cercano, **entonces** se informa que la caminata inicial será larga y se continúa el cálculo.
- El polígono de cobertura es configurable sin recompilar (archivo o variable de entorno).
- El servidor valida la cobertura de forma independiente al cliente (no se confía en la validación del cliente).
- La respuesta de error usa un código estable (`OUT_OF_COVERAGE`).

**4. Historia de usuario:** *Como usuario, quiero saber de inmediato si mi viaje está fuera de la zona que la app cubre, para no perder tiempo esperando una respuesta que no puede darme.*

**5. Datos que intervienen:** `coverage_polygon` (GeoJSON), `origin`, `destination`, `distance_to_nearest_stop_m`, código de error `OUT_OF_COVERAGE`.

---

### RF-03 — Captura de condiciones del viaje (entrada manual)
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Flujo paso 2; pantalla S2.

**1. Título:** Definición de condiciones del viaje.

**2. Descripción:** El usuario establece las restricciones y preferencias propias de **ese viaje**: presupuesto máximo (S/), caminata máxima seguida (m), caminata total máxima (m), aceptación de taxi en algún tramo y prioridad (ahorro, menor caminata, tiempo, menos transbordos). Las preferencias se definen por viaje, no por perfil.

**3. Criterios de aceptación:**
- El formulario contiene los 5 controles con valores por defecto razonables (p. ej. S/ 8; 300 m seguidos; 800 m totales; taxi sí; prioridad equilibrada).
- La caminata se muestra en metros y su equivalencia aproximada en cuadras (≈ 100 m = 1 cuadra).
- **Dado** un presupuesto ≤ 0, no numérico o > un máximo configurable (p. ej. S/ 200), **entonces** se muestra un error de validación y no se envía.
- **Dado** una caminata seguida mayor que la total, **entonces** se ajusta automáticamente la total o se advierte, sin perder el valor ingresado.
- Todos los valores se envían al backend en unidades SI/monetarias normalizadas (metros, soles con 2 decimales).
- El usuario puede modificar cualquier condición después de ver resultados y recalcular sin volver a ingresar origen/destino.
- Un solo toque en atajos de presupuesto (S/ 6, 8, 10, 15) completa el campo.

**4. Historia de usuario:** *Como trabajadora con S/ 8 y una mochila pesada, quiero indicar cuánto puedo gastar y cuánto puedo caminar seguido, para que solo me muestren recorridos que de verdad puedo hacer hoy.*

**5. Datos que intervienen:** `budget_soles`, `max_continuous_walk_m`, `max_total_walk_m`, `allow_taxi_bridge`, `priority_mode ∈ {SAVINGS, LESS_WALK, TIME, FEWER_TRANSFERS, BALANCED}`, límites configurables de validación.

---

### RF-04 — Interpretación de condiciones en lenguaje natural
**Prioridad:** P1 · **Tipo:** Funcional · **Trazabilidad:** Flujo paso 2 (lenguaje propio); sección 5.7.

**1. Título:** Interpretación de condiciones en lenguaje natural.

**2. Descripción:** El usuario puede describir sus condiciones con sus propias palabras (texto, o voz transcrita) y el sistema las convierte en parámetros estructurados, **mostrándolos como etiquetas editables para que confirme** antes de usarlos. Es una alternativa, nunca la única vía.

**3. Criterios de aceptación:**
- **Dado** el texto "Tengo 10 soles, llevo cajas y no quiero caminar más de 2 cuadras seguidas", **entonces** se extraen `budget=10`, `max_continuous_walk_m≈200`, y se muestran etiquetas editables antes de calcular.
- La salida del intérprete se valida contra un esquema estricto; si no cumple, se descarta y se pide usar los controles manuales.
- **Dado** que el intérprete falla, excede 5 s o no está disponible, **entonces** la pantalla muestra los controles manuales sin bloquear al usuario.
- Los valores ambiguos o ausentes **no se inventan**: se dejan vacíos o con el valor por defecto visible.
- La conversión de "cuadras" a metros se muestra explícitamente.
- El texto del usuario nunca se concatena directamente a consultas SQL ni a instrucciones privilegiadas; su longitud máxima está limitada (p. ej. 500 caracteres).
- Ningún cálculo se ejecuta hasta que el usuario confirme las etiquetas interpretadas.

**4. Historia de usuario:** *Como usuaria con las manos ocupadas, quiero contar mis condiciones con mis palabras y revisar que me entendieron bien, para no tener que mover varios controles en la calle.*

**5. Datos que intervienen:** `raw_text`, `parsed {budget_max, max_continuous_walk_m, max_total_walk_m?, allow_taxi, priority, spent_so_far?}`, `confirmation_labels[]`, `parse_status ∈ {OK, PARTIAL, FAILED}`, tiempo de respuesta del LLM.

---

## B. Cálculo y comparación de alternativas

### RF-05 — Cálculo de alternativas multimodales con restricciones duras
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Motor 1; sección 5.5.

**1. Título:** Cálculo de recorridos multimodales con restricciones duras.

**2. Descripción:** A partir de origen, destino y condiciones, el motor calcula recorridos que combinan caminata y transporte público (Metropolitano, Metro, corredores, líneas tradicionales cargadas) sobre datos reales de la zona cubierta. La tarifa se cobra **por cada abordaje**. Las restricciones del usuario son **duras**: ningún recorrido las viola.

**3. Criterios de aceptación:**
- Todo recorrido devuelto cumple simultáneamente: `Σ costos ≤ presupuesto`, **cada** tramo a pie ≤ `max_continuous_walk_m`, `Σ caminata ≤ max_total_walk_m`.
- El costo total cuenta una tarifa por cada abordaje; un trasbordo implica una segunda tarifa salvo que la tabla de tarifas indique lo contrario (con fuente).
- Cada tramo indica tipo (`WALK|RIDE|TAXI_BRIDGE`), origen, destino, distancia, duración, costo (si aplica) y certidumbre.
- **Dado** un conjunto de 10 viajes de referencia ("viajes de oro") con resultado esperado, **entonces** el motor reproduce el resultado esperado (costos y caminatas dentro de la tolerancia definida en RNF-08).
- El motor no depende de llamadas de red dentro del bucle de búsqueda (solo datos precargados en memoria).
- **Dado** que el cálculo excede el tiempo máximo (RNF-01), **entonces** devuelve el mejor conjunto parcial con una advertencia, sin error genérico.
- La caminata inicial hacia el primer paradero y la final desde el último se incluyen en los totales.

**4. Historia de usuario:** *Como pasajero con un tope de gasto, quiero que el sistema solo me proponga recorridos cuya suma de pasajes y cuya caminata respeten mis límites, para no descubrir a mitad de camino que me quedé sin dinero.*

**5. Datos que intervienen:** `TransitStop` (id, geom, tipo, confianza), `TransitRoute` (código, modo, geometría, tarifa, certidumbre de tarifa, headway estimado, velocidad media), `RouteStop` (orden), parámetros de RF-03, grafo en memoria, `data_version`.

---

### RF-06 — Inserción de tramo puente en taxi
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Motor 1; sec. 5.5.1; problema "movilidad binaria".

**1. Título:** Inserción de tramos puente en taxi.

**2. Descripción:** Cuando un transbordo exige caminar más que el límite del usuario (o encadena conexiones de alta fricción), y el usuario acepta taxi, el sistema genera un tramo puente en taxi entre dos puntos de conexión, estima su costo y lo evalúa junto a las demás opciones. El taxi solo se usa donde aporta ventaja.

**3. Criterios de aceptación:**
- **Dado** `allow_taxi_bridge=false`, **entonces** ningún recorrido contiene `TAXI_BRIDGE`.
- **Dado** un transbordo cuya caminata > `max_continuous_walk_m` y `allow_taxi_bridge=true`, **entonces** se evalúa una arista de taxi entre los dos paraderos.
- El costo del taxi se calcula con **una única fórmula documentada** (`max(5.00, 3.50 + 1.25·d_km + 0.25·t_min) × factor_hora`) y se marca **siempre `ESTIMATED`**.
- **Dado** que un taxi no reduce la caminata ni el tiempo, o que rompe el presupuesto sin beneficio, **entonces** NO se muestra como alternativa y se explica el motivo ("Descartamos el taxi: no reduce tu caminata en este tramo").
- El tramo puente nunca supera una distancia máxima configurable (p. ej. 3 km).
- La interfaz indica que la cotización debe confirmarse en el servicio de taxi externo; **el sistema no contrata ni cobra taxis**.
- La distancia y el tiempo del taxi se obtienen de un servicio de rutas con caché; si no está disponible, se usa una aproximación local y se avisa.

**4. Historia de usuario:** *Como persona cansada, quiero que la app me diga en qué tramo exacto me conviene pagar un taxi corto y cuánto más me costará, para no tener que elegir entre caminar mucho o pagar un taxi completo.*

**5. Datos que intervienen:** `taxi_fare_params {base, per_km, per_min, min_fare, peak_factor}`, `d_km`, `t_min`, `walk_distance_replaced_m`, `extra_cost_soles`, `allow_taxi_bridge`, `max_bridge_km`, hora del día.

---

### RF-07 — Selección de tres alternativas (frontera de Pareto)
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Sec. 5.5.2; propuesta del compañero.

**1. Título:** Presentación de hasta tres alternativas comparables.

**2. Descripción:** De todas las soluciones no dominadas, el sistema presenta hasta tres: **Más barata**, **Menos caminata** y **Equilibrada** (mejor relación metros ahorrados por sol gastado). Solo se muestran las alternativas que realmente existan y difieran entre sí.

**3. Criterios de aceptación:**
- Se devuelven entre 0 y 3 alternativas; nunca se rellena con alternativas duplicadas.
- **Más barata** tiene el mínimo costo entre las factibles (desempate por menor caminata).
- **Menos caminata** tiene la mínima caminata total (o continua) entre las factibles.
- **Equilibrada** maximiza `Δmetros_ahorrados / Δsoles_gastados` respecto a la más barata, o es el punto de la frontera más cercano al ideal normalizado.
- **Dado** que dos alternativas coinciden en tramos y costo, **entonces** se muestra una sola con la etiqueta combinada.
- **Dado** `priority_mode=TIME` o `FEWER_TRANSFERS`, **entonces** el orden de presentación refleja esa prioridad.
- Cada alternativa expone `total_cost`, `total_walk_m`, `longest_continuous_walk_m`, `est_duration_min`, `transfers`.
- Todas las alternativas respetan las restricciones duras (RF-05).

**4. Historia de usuario:** *Como usuario, quiero ver pocas opciones realmente distintas (la más barata, la que menos camina y una intermedia), para decidir rápido sin comparar quince rutas casi iguales.*

**5. Datos que intervienen:** conjunto de etiquetas `(costo, caminata_total, caminata_continua, tiempo, transbordos)`, relación `Δmetros/Δsoles`, `label ∈ {CHEAPEST, LEAST_WALK, BALANCED}`, `priority_mode`, `K` máximo de etiquetas por estado.

---

### RF-08 — Comparación y explicación de tradeoffs
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Flujo paso 3; pantalla S3; objetivo "explicar qué se gana y qué se sacrifica".

**1. Título:** Comparación de alternativas y explicación de tradeoffs.

**2. Descripción:** El sistema muestra las alternativas en tarjetas y en el mapa, y para cada una explica en lenguaje llano qué se gana y qué se sacrifica frente a las otras. Al abrir una alternativa se ve el detalle tramo a tramo.

**3. Criterios de aceptación:**
- Cada tarjeta muestra: nombre, costo total (con chip de certidumbre), caminata total, caminata seguida más larga, tiempo estimado, transbordos y resumen de tramos con iconos.
- Cada alternativa incluye un `tradeoff_text` generado por plantilla determinista (ej. "Inserta un taxi de ~1,4 km entre A y B: +S/ 4,50 y tu caminata seguida baja de 850 m a 90 m").
- El `tradeoff_text` usa **solo** cifras presentes en el resultado del motor (no se inventan).
- El mapa dibuja los tramos con colores distintos por tipo (caminata, transporte, taxi) y muestra marcadores de abordaje/descenso.
- El usuario puede alternar entre alternativas sin recalcular.
- Los importes pendientes de confirmar se muestran como tales (RF-09).
- La pantalla permite volver a editar condiciones (RF-03) en un toque.

**4. Historia de usuario:** *Como usuario indeciso, quiero que cada opción me explique con claridad qué gano y qué pierdo, para elegir con conocimiento y no a ciegas.*

**5. Datos que intervienen:** `Alternative {id, label, total_cost{amount, certainty}, total_walk_m, longest_continuous_walk_m, est_duration_min, transfers, legs[], tradeoff_text, warnings[]}`, geometrías `polyline` de cada `Leg`.

---

### RF-09 — Transparencia de incertidumbre (confirmado vs. estimado)
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Principio de honestidad de datos; sec. 5.5.5.

**1. Título:** Etiquetado de certidumbre de los datos.

**2. Descripción:** Todo dato mostrado que pueda no ser exacto lleva una etiqueta visible de certidumbre: tarifas (`CONFIRMED`/`ESTIMATED`, con fuente y fecha), costo del taxi (siempre estimado), espera/frecuencia (estimada) y tipo de paradero (oficial / comunitario OSM / inferido con %).

**3. Criterios de aceptación:**
- Ningún importe monetario aparece sin etiqueta de certidumbre.
- Una tarifa `CONFIRMED` expone, al tocarla, **fuente y fecha**; si no las tiene, el sistema la degrada a `ESTIMATED`.
- El costo de taxi **nunca** se muestra como `CONFIRMED`.
- Los paraderos se muestran con semáforo: 🟢 oficial, ⚪ comunitario (OSM), 🟡 inferido (con porcentaje de confianza).
- Los datos de espera/frecuencia se muestran como estimados.
- Los datos generados con el simulador llevan la etiqueta `SIMULADO` en pantalla.
- Existe un indicador visible de la fecha de los datos (`data_version`).

**4. Historia de usuario:** *Como usuario, quiero distinguir de un vistazo qué información está confirmada y cuál es solo una estimación, para saber qué debo verificar antes de salir.*

**5. Datos que intervienen:** `fare_certainty`, `fare_source`, `fare_checked_at`, `stop_type`, `confidence_score`, `is_simulated`, `est_headway_min`, `data_version`.

---

### RF-10 — Diagnóstico de infactibilidad y relajación mínima
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Flujo paso 4; pantalla S4; sec. 5.5.3.

**1. Título:** Diagnóstico de restricciones incompatibles y relajación mínima.

**2. Descripción:** Si ninguna alternativa cumple las condiciones, el sistema no responde "sin rutas": identifica qué condición lo impide, calcula la relajación mínima necesaria y la ofrece como opción de un toque. **Nunca modifica una restricción sin consentimiento.**

**3. Criterios de aceptación:**
- **Dado** que no hay solución, **entonces** la respuesta incluye `infeasible.blocking[]` y `infeasible.relaxations[]` (al menos una relajación válida si existe alguna solución al relajar).
- Las relajaciones se calculan relajando **una sola restricción a la vez** (presupuesto, caminata seguida, permitir taxi) y se reportan los deltas mínimos (`+S/ X`, `+Y m`).
- Se ofrecen como máximo las 2 relajaciones más favorables para el usuario.
- El texto está en lenguaje llano (ej. "Con S/ 4,00 y máx. 200 m no hay recorrido. Opciones: (A) +S/ 2,50 para incluir un taxi en [lugar], o (B) caminar +320 m en [lugar]").
- **Dado** que el usuario no pulsa ninguna opción, **entonces** sus límites permanecen intactos.
- **Dado** que acepta una relajación, **entonces** solo esa restricción cambia y el cálculo se repite automáticamente.
- **Dado** que ni relajando existe viaje, **entonces** se informa que no hay recorrido con los datos actuales y se sugiere cambiar origen/destino.

**4. Historia de usuario:** *Como usuario con poco dinero, quiero saber exactamente cuánto me falta o cuánto más tendría que caminar cuando no hay opciones, para decidir yo qué límite estoy dispuesto a mover.*

**5. Datos que intervienen:** `infeasible {blocking[], relaxations[{type, delta, message}]}`, `budget_soles`, `max_continuous_walk_m`, `allow_taxi_bridge`, costo mínimo sin límite de presupuesto, caminata mínima sin límite de caminata.

---

## C. Seguimiento del viaje

### RF-11 — Selección y revisión previa al viaje
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Flujo paso 5; pantalla S5.

**1. Título:** Selección de alternativa y revisión previa.

**2. Descripción:** Al elegir una alternativa, el usuario revisa una lista previa a salir: primer punto al que dirigirse, servicio a abordar, dónde bajar, cómo llegar a la conexión, gasto total estimado y saldo previsto. Si incluye taxi, se avisa que la cotización se confirma externamente.

**3. Criterios de aceptación:**
- Elegir una alternativa registra la selección en la sesión de viaje (`status=ACTIVE` al iniciar).
- La revisión muestra, en orden, cada acción con distancia y nombre del punto.
- **Dado** una alternativa con `TAXI_BRIDGE`, **entonces** se muestra el aviso "Precio estimado; confirma la cotización en tu app de taxi antes de subir" y un acceso opcional para abrir esa app.
- Si la cotización real difiere, el usuario puede volver a comparar sin perder sus condiciones.
- El usuario puede cancelar y elegir otra alternativa sin recalcular.
- La selección queda almacenada para poder reanudar si la app se cierra.

**4. Historia de usuario:** *Como usuaria nueva en la zona, quiero revisar el recorrido completo antes de salir, para saber dónde ir primero, qué tomar y cuánto gastaré.*

**5. Datos que intervienen:** `selected_alternative`, `trip_id`, `status`, secuencia de `Leg`, `estimated_total_cost`, `expected_remaining_budget`, enlace de salida al servicio de taxi.

---

### RF-12 — Seguimiento guiado del viaje (tramo actual y siguiente acción)
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Flujo paso 6; pantalla S6.

**1. Título:** Seguimiento del viaje por tramos.

**2. Descripción:** Durante el viaje, el sistema muestra el tramo actual y la siguiente acción concreta ("Camina 150 m hacia Av. X y espera el Corredor Azul"), el progreso, el saldo restante y las limitaciones de información. El usuario puede avanzar manualmente de tramo si no hay GPS.

**3. Criterios de aceptación:**
- La pantalla muestra una sola acción principal a la vez, con texto corto y botones ≥ 48 px.
- **Dado** que hay GPS, **entonces** el avance de tramo puede detectarse por proximidad (radio configurable) y confirmarse con un toque.
- **Dado** que no hay GPS o el permiso fue denegado, **entonces** el usuario avanza con "Listo, siguiente paso".
- El saldo restante visible se actualiza al confirmar cada pago.
- Cuando falta información (paradero inferido, tarifa estimada), la limitación es visible junto a la instrucción.
- El botón "Algo cambió" (RF-13) siempre está accesible.
- La app puede reanudar el viaje activo tras cerrarse o perder conexión; si el usuario tiene cuenta, el viaje activo se puede **reanudar desde otro dispositivo** (RF-34).

**4. Historia de usuario:** *Como pasajero en la calle, quiero ver solo el siguiente paso y cuánto dinero me queda, para guiarme con un vistazo sin quedarme mirando el celular.*

**5. Datos que intervienen:** `trip_id`, `current_leg_index`, `current_position`, `leg {type, instruction_text, polyline, distance_m}`, `spent_budget_soles`, `remaining_budget_soles`, `status`.

---

### RF-13 — Replanificación con saldo restante (costo hundido)
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Flujo paso 7; pantalla S7; sec. 5.5.4.

**1. Título:** Replanificación durante el viaje con el saldo restante.

**2. Descripción:** El usuario puede informar un cambio ("ya no quiero caminar tanto", "el taxi cuesta más", "me bajé en otro punto", "tengo menos dinero", "gasté S/ X") y el sistema recalcula alternativas **desde su ubicación actual** con el **dinero restante**, descontando lo ya gastado cuando el usuario lo confirme.

**3. Criterios de aceptación:**
- **Dado** `presupuesto_inicial=9.00` y `gastado_confirmado=2.50`, **entonces** el recálculo usa `6.50` como presupuesto.
- El gasto descontado requiere confirmación del usuario (puede aceptar el monto sugerido por el plan o editarlo).
- El recálculo parte de la posición actual (GPS o seleccionada manualmente).
- **Dado** que el usuario indica estar a bordo de una línea, **entonces** solo puede bajarse en paraderos de esa ruta.
- Cada replanificación incrementa `replan_count` y registra un evento.
- El tiempo de respuesta cumple RNF-02.
- Si no hay solución con el saldo restante, se aplica el diagnóstico de RF-10.
- La entrada duplicada (doble toque) no genera dos recálculos (RNF-25).

**4. Historia de usuario:** *Como pasajero que ya pagó el primer bus y se bajó antes por el tráfico, quiero recalcular mi ruta con los soles que me quedan desde donde estoy parado, para llegar sin quedarme sin dinero.*

**5. Datos que intervienen:** `trip_id`, `position`, `spent_soles`, `new_budget?`, `remaining_budget_soles`, `on_board_route?`, `replan_count`, `note`, `request_id` (idempotencia).

---

### RF-14 — Finalización del viaje y retroalimentación
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Flujo paso 8; pantalla S8; evidencia de validación.

**1. Título:** Cierre del viaje y feedback.

**2. Descripción:** Al terminar (o abandonar), el sistema pregunta brevemente si el recorrido fue realizable y permite señalar diferencias en tarifas, puntos de embarque o indicaciones. Esa información alimenta la confianza de los datos y la evidencia de tracción.

**3. Criterios de aceptación:**
- El cierre muestra como máximo 2 preguntas obligatorias (¿pudiste completarlo? Sí/No/Parcial; ¿coincidieron tarifas y paraderos?) y campos opcionales.
- El feedback queda asociado al `trip_id` y a la sesión anónima.
- Una diferencia de tarifa o paradero reportada se almacena para revisión; **no** modifica los datos oficiales automáticamente.
- `status` pasa a `COMPLETED` o `ABANDONED`.
- Un viaje abandonado sin feedback sigue siendo contabilizado como sesión.
- El feedback puede omitirse sin bloquear la app.

**4. Historia de usuario:** *Como usuario, quiero poder avisar en segundos si el recorrido funcionó o si algo no coincidió, para ayudar a mejorar la información de los siguientes viajeros.*

**5. Datos que intervienen:** `TripFeedback {trip_id, completed, fare_mismatch, stop_mismatch, comment, created_at}`, `trip_sessions.status`, `Event (type=COMPLETE|FEEDBACK)`.

---

## D. Paraderos y detección de paraderos de facto

### RF-15 — Mapa de paraderos con tipo y confianza
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Sec. 8.4; matriz de decisión.

**1. Título:** Visualización de paraderos por tipo y confianza.

**2. Descripción:** El mapa muestra los paraderos de la zona cubierta diferenciando **oficial (ATU)**, **comunitario (OSM)** e **inferido por GPS** (con porcentaje de confianza), y al tocarlos muestra las rutas que los sirven.

**3. Criterios de aceptación:**
- Cada paradero muestra su tipo con color/icono y leyenda visible.
- Al tocar un paradero se lista: nombre, tipo, rutas que lo sirven, fuente y fecha de verificación; si es inferido, también el nº de sesiones distintas y la confianza.
- Los paraderos inferidos solo aparecen si cumplen el umbral de RF-18.
- La consulta por área (`bbox`) devuelve solo los paraderos visibles y respeta un límite de resultados.
- Los paraderos no cargan miles de marcadores a la vez (agrupamiento visual a bajos niveles de zoom).

**4. Historia de usuario:** *Como visitante, quiero ver en el mapa qué paraderos son oficiales y cuáles son solo "probables", para saber en qué punto exacto esperar el bus.*

**5. Datos que intervienen:** `TransitStop {id, name, geom, stop_type, confidence_score, detected_boardings_count, distinct_sessions_count, routes_serving[], source, last_verified_at}`, `bbox`, `zoom`.

---

### RF-16 — Captura de telemetría GPS (con consentimiento)
**Prioridad:** P1 · **Tipo:** Funcional · **Trazabilidad:** Motor 2; sec. 5.6.1.

**1. Título:** Captura de trazas GPS durante el viaje.

**2. Descripción:** Durante el seguimiento, y solo con consentimiento explícito, la app registra la posición, velocidad, rumbo y precisión del dispositivo y las envía por lotes al servidor mediante un identificador de sesión anónimo.

**3. Criterios de aceptación:**
- La captura **no inicia** sin consentimiento explícito y revocable en pantalla.
- Se muestra de forma visible cuándo se está enviando ubicación.
- Los pings se toman cada 2–5 s y se envían en lotes (≈ cada 10 s); los pings con `accuracy_m` > 40 se descartan antes de guardarse.
- El envío continúa de forma tolerante a la pérdida de conexión (cola local con reintento, límite de tamaño).
- El servidor rechaza lotes > tamaño máximo y valores fuera de rango (lat/lng inválidos, velocidad > 70 m/s).
- No se asocia ningún dato personal (teléfono, nombre, correo) a las trazas.
- El usuario puede detener la captura sin afectar el seguimiento guiado.

**4. Historia de usuario:** *Como pasajero que quiere ayudar a mejorar el mapa, quiero compartir mi ubicación de forma anónima y controlarla, para aportar sin exponer mi privacidad.*

**5. Datos que intervienen:** `GpsPing {anon_session_id, lat, lng, speed_mps, heading_deg, accuracy_m, is_simulated, recorded_at}`, `consent {granted, granted_at}`, tamaño de lote, estado de cola local.

---

### RF-17 — Detección de eventos de espera y abordaje
**Prioridad:** P1 · **Tipo:** Funcional · **Trazabilidad:** Motor 2; sec. 5.6.2.

**1. Título:** Detección de transición espera → abordaje vehicular.

**2. Descripción:** El sistema analiza las trazas por sesión y detecta una transición cuando el usuario espera quieto un tiempo mínimo y luego alcanza velocidad vehicular alineada con una ruta o avenida, lejos de paraderos oficiales. Los umbrales son configurables y deben calibrarse con datos reales.

**3. Criterios de aceptación:**
- Una transición se marca solo si se cumplen: espera ≥ T1 (por defecto 40 s) en radio ≤ R1 (por defecto 15–25 m) con v < 1,2 m/s; luego v > 4,5 m/s sostenida; rumbo alineado (±20–30°) con una ruta/avenida conocida; punto a > 50 m de paradero oficial.
- Los umbrales (T1, R1, velocidades, tolerancia de rumbo, distancia a paradero) están en configuración, no en código fijo.
- No se marcan transiciones cuando el usuario declaró un tramo en taxi activo ni con velocidad > 70 m/s.
- Los pings con precisión insuficiente no participan en la detección.
- **Dado** una traza simulada con la firma esperada, **entonces** se registra exactamente un evento de abordaje.
- **Dado** una traza de peatón que cruza una calle esperando un semáforo sin abordar, **entonces** no se registra abordaje.
- Cada evento guarda su procedencia (`is_simulated`).

**4. Historia de usuario:** *Como equipo del proyecto, queremos detectar automáticamente cuándo la gente aborda en un punto donde no hay paradero oficial, para descubrir paraderos informales sin que nadie los reporte a mano.*

**5. Datos que intervienen:** `GpsPing[]`, umbrales configurables, rutas/avenidas (geometrías), paraderos oficiales, `boarding_event {anon_session_id, geom, heading, ts, is_simulated}`.

---

### RF-18 — Agrupamiento y publicación de paraderos de facto
**Prioridad:** P1 · **Tipo:** Funcional · **Trazabilidad:** Motor 2; sec. 5.6.3–5.6.4.

**1. Título:** Agrupamiento de abordajes y creación de paraderos inferidos.

**2. Descripción:** Un proceso periódico agrupa espacialmente los eventos de abordaje (DBSCAN en coordenadas proyectadas, radio en metros) y promueve un grupo a **paradero de facto visible** solo cuando cumple un mínimo de abordajes y de **sesiones distintas**, asignándole un puntaje de confianza.

**3. Criterios de aceptación:**
- El agrupamiento usa coordenadas proyectadas en metros (p. ej. EPSG:32718) con `eps` configurable (por defecto ≈ 25–30 m) y `minpoints` ≥ 3.
- Un grupo solo se publica si tiene **≥ 3 sesiones distintas** (un solo usuario repetido no basta).
- Cada paradero inferido guarda `detected_boardings_count`, `distinct_sessions_count` y `confidence_score` con fórmula documentada (si se llama "bayesiano", debe serlo; si no, "puntaje heurístico").
- La confianza se actualiza cuando llegan nuevos eventos y puede decaer con el tiempo sin evidencia.
- El proceso se ejecuta de forma periódica (1–5 min) sin bloquear la API.
- Los paraderos inferidos se identifican siempre como "inferido", nunca como "ilegal" ni "legal".
- **Dado** 5 eventos simulados de 5 sesiones distintas en un punto no oficial, **entonces** aparece un paradero inferido con confianza > 0 en ≤ 2 ciclos del proceso.

**4. Historia de usuario:** *Como pasajero en zona desconocida, quiero ver dónde la gente realmente aborda aunque no sea paradero oficial, para esperar en el lugar correcto.*

**5. Datos que intervienen:** `boarding_event[]`, `eps`, `minpoints`, `distinct_sessions_count`, `detected_boardings_count`, `confidence_score`, `TransitStop (stop_type=INFERRED_DE_FACTO)`, `last_verified_at`.

---

### RF-19 — Simulador de trazas para la demostración
**Prioridad:** P1 · **Tipo:** Funcional · **Trazabilidad:** Sec. 5.6.5; honestidad en la demo.

**1. Título:** Simulador de trazas de abordaje.

**2. Descripción:** Un mecanismo protegido genera trazas sintéticas (peatones esperando en un punto no oficial y un vehículo que pasa) para demostrar el detector sin depender de usuarios reales. Todo dato simulado queda **rotulado**.

**3. Criterios de aceptación:**
- El simulador se activa solo mediante un endpoint/comando protegido por token (`ADMIN_DEMO_TOKEN`) o modo demo.
- Todo ping/evento/paradero generado lleva `is_simulated=true` y se muestra como `SIMULADO` en la interfaz.
- Los datos simulados **no se cuentan** en las métricas de tracción (RF-23).
- El simulador permite parametrizar: punto, número de peatones, instante de abordaje y velocidad final.
- Tras una ejecución, el paradero inferido aparece en el mapa en ≤ 10 s (RNF de demo).
- Existe una acción para **borrar** los datos simulados.

**4. Historia de usuario:** *Como presentador en la demo, quiero inyectar unas trazas simuladas y ver aparecer un paradero inferido en vivo, para mostrar el detector con claridad y sin depender de gente real.*

**5. Datos que intervienen:** parámetros del simulador `{point, n_pedestrians, boarding_at, final_speed}`, `GpsPing (is_simulated=true)`, `boarding_event`, `ADMIN_DEMO_TOKEN`.

---

## E. Demo, alertas y tracción

### RF-20 — Modo demo sin GPS y viajes de ejemplo
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Regla R3 (la demo corre en la PC del jurado).

**1. Título:** Modo demo reproducible sin GPS.

**2. Descripción:** La app incluye un modo demo que permite fijar la posición tocando el mapa y cargar viajes de ejemplo ensayados, de modo que la demostración funcione en un computador ajeno, en ventana privada y sin permisos de ubicación.

**3. Criterios de aceptación:**
- Desde la pantalla inicial se puede abrir un viaje de ejemplo con un solo toque (origen, destino y condiciones precargados).
- En modo demo, "Mi ubicación" puede fijarse tocando el mapa sin solicitar permisos del navegador.
- El modo demo funciona **sin registro, sin iniciar sesión** (RF-33) y sin datos locales previos; el jurado nunca necesita crear una cuenta.
- El modo demo está visible/identificable (distintivo) pero no cambia los resultados del motor.
- Todo el recorrido P0 (planificar → comparar → infactible → seguir → replanificar) puede completarse en modo demo en ≤ 2 minutos.
- Los viajes de ejemplo producen resultados idénticos en cada ejecución (determinismo).

**4. Historia de usuario:** *Como jurado que abre la app desde otro computador, quiero probar un viaje de ejemplo sin instalar nada ni dar permisos, para evaluar el producto en pocos segundos.*

**5. Datos que intervienen:** definiciones de `demo_trips[]` (origen, destino, condiciones, resultado esperado), posición fijada manualmente, bandera `demo_mode`.

---

### RF-21 — Alertas de contingencia con fuente
**Prioridad:** P1 · **Tipo:** Funcional · **Trazabilidad:** Sponsors Tavily/Exa; sec. 7.3.

**1. Título:** Alertas de contingencias del día.

**2. Descripción:** El sistema consulta fuentes en línea para detectar desvíos, cierres de estaciones, marchas u obras que afecten las rutas de las alternativas y las muestra como avisos con **fuente y fecha**. Las alertas informan y reducen la confianza; **no cambian rutas por sí solas**.

**3. Criterios de aceptación:**
- Cada alerta muestra título, resumen corto, **URL de la fuente** y fecha/hora de publicación.
- Las alertas se marcan como "no verificadas" salvo que provengan de una fuente oficial configurada.
- Una alerta asociada a una ruta aparece en la tarjeta de las alternativas que usan esa ruta.
- Los resultados se cachean entre 10 y 30 minutos por consulta.
- **Dado** que el proveedor de búsqueda falla o excede 3 s, **entonces** la comparación se muestra sin alertas y con un aviso discreto, sin error.
- No se bloquea el cálculo de rutas esperando las alertas (carga asíncrona).
- Las alertas antiguas (> 24 h) se descartan o se marcan como caducadas.

**4. Historia de usuario:** *Como pasajero, quiero enterarme antes de salir si hay un desvío o cierre en mi ruta, con la fuente de la noticia, para no esperar un bus que hoy no va a pasar.*

**5. Datos que intervienen:** `Alert {id, route_code?, stop_id?, title, summary, source_url, published_at, verified, fetched_at, expires_at}`, consulta de búsqueda, caché.

---

### RF-22 — Registro de sesiones y eventos de producto
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Sec. 11 (tracción); rúbrica.

**1. Título:** Registro de eventos de uso.

**2. Descripción:** El sistema registra de forma anónima cada acción relevante (planificar, seleccionar, replanificar, completar, feedback, ver alerta) con marca de tiempo y bandera de **usuario externo vs. equipo**, para sostener la evidencia de tracción en la base de datos.

**3. Criterios de aceptación:**
- Cada plan, selección, replanificación, finalización y feedback crea un `Event` con `type`, `anon_session_id`, `user_id` (nulo si es invitado), `payload` y `created_at`.
- Las sesiones del equipo pueden marcarse (parámetro, clave o dispositivo) y quedan con `is_external_user=false`.
- Los eventos generados por el simulador o por pruebas automatizadas llevan `is_simulated=true` (o equivalente) y se excluyen de las métricas de tracción.
- El registro de eventos no afecta la latencia de la respuesta principal (escritura asíncrona o no bloqueante).
- Un fallo al registrar un evento no interrumpe la acción del usuario.
- Los eventos no contienen datos personales identificables.

**4. Historia de usuario:** *Como equipo, queremos que cada uso real quede registrado y distinguido del nuestro, para demostrar al jurado cuántas personas externas usaron el producto.*

**5. Datos que intervienen:** `Event {id, anon_session_id, user_id?, type, payload, is_external_user, is_simulated, created_at}`, `TripSession.is_external_user`, `User.is_team_member` (para excluir al equipo de la tracción).

---

### RF-23 — Panel público de tracción
**Prioridad:** P1 · **Tipo:** Funcional · **Trazabilidad:** Sec. 11.3; pantalla S9; rúbrica (tracción).

**1. Título:** Panel de tracción en vivo.

**2. Descripción:** Una pantalla de solo lectura muestra métricas **calculadas desde la base de datos**: viajes planificados por usuarios externos, replanificaciones, viajes completados, feedback recibido, paraderos inferidos y entrevistas registradas. No contiene datos personales.

**3. Criterios de aceptación:**
- Todas las cifras se calculan en la consulta; ninguna se escribe a mano.
- Las métricas **excluyen** sesiones del equipo (cuentas marcadas `is_team_member`) y datos simulados.
- Las métricas distinguen **cuentas registradas externas** de **invitados**, y cuentan "usuarios que volvieron" por `user_id` (más confiable que por sesión anónima) y por `anon_session_id` para invitados.
- Las cuentas de prueba creadas por el equipo no cuentan como externas; el sistema no cuenta cuentas con correos marcados como del equipo o de pruebas.
- El panel muestra "usuarios externos únicos" y "viajes de usuarios que volvieron" (uso repetido) usando identificadores anónimos.
- No expone trazas individuales, ubicaciones exactas de usuarios ni identificadores reversibles.
- Se actualiza al recargar (o cada ≤ 30 s) y responde en ≤ RNF-01 para consultas agregadas.
- Incluye la fecha/hora de corte de las cifras.
- **Dado** que no hay uso externo, **entonces** muestra 0 y no cifras inventadas.

**4. Historia de usuario:** *Como jurado, quiero ver en el propio producto cuánta gente real lo usó y volvió a usarlo, para valorar la tracción con evidencia verificable.*

**5. Datos que intervienen:** agregados de `Event`, `TripSession`, `TripFeedback`, `TransitStop (INFERRED)`, entrevistas registradas (`validation_records`), banderas `is_external_user`, `is_simulated`.

---

## F. Datos y operación

### RF-24 — Ingesta y carga de datos de transporte
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Sec. 6 (datos); regla R1.

**1. Título:** Ingesta de rutas y paraderos de la zona cubierta.

**2. Descripción:** El sistema carga rutas y paraderos desde fuentes abiertas (OpenStreetMap vía Overpass, datos abiertos de ATU si existen) y desde archivos **curados a mano**, los normaliza y los almacena con su fuente y fecha, dejando listo el grafo del motor.

**3. Criterios de aceptación:**
- Existe un comando reproducible que descarga/lee los datos del eje y los carga en la base.
- Cada registro de ruta y paradero guarda `source` y `last_verified_at`.
- Los datos curados manualmente están en archivos versionados del repositorio con un documento de fuentes (qué se curó y por qué).
- Tras la carga se emite un informe: nº de rutas, nº de paraderos, rutas sin geometría completa, paraderos duplicados descartados.
- Rutas incompletas o inconsistentes (sin paraderos ordenados) se excluyen del grafo y se listan en el informe.
- La carga es idempotente (volver a ejecutarla no duplica registros).
- El motor arranca cargando el grafo en memoria en ≤ RNF-03.

**4. Historia de usuario:** *Como equipo, queremos cargar con un solo comando los datos reales del eje y saber qué cubren y qué no, para construir el motor sobre información verificable.*

**5. Datos que intervienen:** respuestas de Overpass (relaciones `route`, nodos `bus_stop`), capas ATU, `TransitRoute`, `TransitStop`, `RouteStop`, archivos `data/curated/*.json`, `source`, `last_verified_at`, informe de ingesta.

---

### RF-25 — Gestión de tarifas con fuente
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Sec. 6.1; RF-09.

**1. Título:** Tabla de tarifas con certidumbre y fuente.

**2. Descripción:** El sistema mantiene una tabla de tarifas por ruta/modo con su certidumbre, fuente y fecha, usada por el motor para calcular costos. Las tarifas sin fuente se tratan como estimadas.

**3. Criterios de aceptación:**
- Cada ruta tiene `base_fare_soles`, `fare_certainty`, `fare_source` y `fare_checked_at`.
- **Dado** una tarifa sin fuente o sin fecha, **entonces** se registra como `ESTIMATED`.
- El motor lee las tarifas desde la base/configuración, no desde constantes en el código.
- Existe la posibilidad de aplicar medio pasaje u otra variante cuando se configure (si no está en alcance, se documenta como "fuera de alcance").
- Una actualización de tarifas se refleja en los cálculos tras recargar el grafo, sin recompilar.
- Se registra un historial mínimo del cambio de tarifas (fecha y valor anterior) cuando se modifiquen.

**4. Historia de usuario:** *Como usuario, quiero que los precios de pasaje provengan de una fuente identificable y estén fechados, para confiar en el costo total que me muestran.*

**5. Datos que intervienen:** `TransitRoute {base_fare_soles, fare_certainty, fare_source, fare_checked_at}`, resultados de Tavily/Exa (cuando se usen para verificar), historial de tarifas.

---

### RF-26 — Memoria de preferencias entre sesiones
**Prioridad:** P2 · **Tipo:** Funcional · **Trazabilidad:** Sponsor AtomicMemory; sec. 7.3.

**1. Título:** Recuerdo de preferencias del usuario.

**2. Descripción:** Con consentimiento, el sistema recuerda preferencias declaradas por el usuario (p. ej. "tiene medio pasaje", "de noche máximo 200 m", presupuesto típico) para precompletar las condiciones de futuros viajes. El usuario puede verlas y borrarlas.

**3. Criterios de aceptación:**
- Solo se guardan preferencias que el usuario declaró o confirmó; nunca se infieren datos sensibles.
- Las preferencias recordadas aparecen **precompletadas y editables** en la pantalla de condiciones, con la indicación "Recordamos tus preferencias".
- El usuario puede **ver y eliminar** sus preferencias desde la app.
- Si el servicio de memoria no está disponible, el formulario funciona con valores por defecto sin errores.
- Las preferencias se asocian al **perfil de la cuenta** (`user_id`) y viajan entre dispositivos; para invitados, a un identificador anónimo local. No se almacenan nombre ni teléfono en el servicio de memoria.
- Al vincular un invitado a una cuenta (RF-33), sus preferencias se **migran** a la cuenta; al eliminar la cuenta (RF-35) se borran.
- Borrar las preferencias elimina los registros en el servicio de memoria.

**4. Historia de usuario:** *Como usuaria frecuente, quiero que la app recuerde mis límites habituales, para no volver a ingresarlos en cada viaje.*

**5. Datos que intervienen:** `UserPreference {anon_id, key, value, source: DECLARED|CONFIRMED, updated_at}`, estado de consentimiento, identificador anónimo.

---

### RF-27 — Canal de mensajería (WhatsApp/SMS) para guía y replanificación
**Prioridad:** P2 · **Tipo:** Funcional · **Trazabilidad:** Sponsor Zavu; sec. 10.

**1. Título:** Guía y replanificación por mensajería.

**2. Descripción:** Como canal opcional, el usuario puede recibir instrucciones del viaje y pedir un nuevo plan escribiendo (o enviando audio) a un número de mensajería, reutilizando exactamente los mismos servicios de planificación y replanificación.

**3. Criterios de aceptación:**
- El canal reutiliza `/plan` y `/replan`; no existe lógica de ruteo duplicada.
- Cada mensaje entrante se valida (firma del webhook) antes de procesarse.
- El usuario debe aceptar expresamente recibir mensajes (opt-in); puede salir con una palabra clave.
- Una respuesta a un mensaje de replanificación llega en ≤ RNF-02 más el tiempo de entrega del proveedor.
- Si el proveedor falla, la app sigue funcionando sin cambios.
- El teléfono no se almacena junto a trazas GPS ni aparece en métricas públicas.
- Las interacciones externas reales por este canal se registran como eventos con `is_external_user=true`.

**4. Historia de usuario:** *Como pasajero que no quiere sacar el celular en la calle, quiero que me lleguen las indicaciones por mensaje y poder pedir un cambio de plan escribiendo, para viajar con más seguridad.*

**5. Datos que intervienen:** número/ID de chat (hash), mensaje entrante, `trip_id`, respuesta saliente, opt-in, firma del webhook, `Event (channel=MESSAGING)`.

---

### RF-28 — Refresco automático de datos y alertas
**Prioridad:** P2 · **Tipo:** Funcional · **Trazabilidad:** Sponsors n8n/Apify; sec. 7.3.

**1. Título:** Actualización automática programada de datos.

**2. Descripción:** Un proceso programado (flujo de automatización) refresca periódicamente rutas, paraderos y alertas desde sus fuentes y actualiza la base, registrando la fecha de cada actualización.

**3. Criterios de aceptación:**
- Los flujos están definidos como archivos exportables versionados (sin secretos).
- Cada ejecución registra inicio, fin, nº de registros nuevos/actualizados y errores.
- Un fallo en el refresco **no** borra ni invalida los datos existentes (se conserva la última versión buena).
- `data_version` se actualiza solo cuando una carga completa termina con éxito.
- La frecuencia del refresco es configurable.
- Los scrapers respetan los términos de uso de cada sitio y no extraen datos personales.

**4. Historia de usuario:** *Como equipo, queremos que los datos y alertas se actualicen solos, para que el sistema no dependa de cargas manuales.*

**5. Datos que intervienen:** definiciones de flujos, bitácora de ejecuciones, `data_version`, `source`, `last_verified_at`, `Alert`, credenciales en variables de entorno (no en el repo).

---

### RF-29 — Consentimiento y privacidad de ubicación
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Regla R7; guía del evento (excluir datos personales).

**1. Título:** Consentimiento informado y control de datos de ubicación.

**2. Descripción:** El sistema solicita consentimiento claro y específico antes de usar o enviar la ubicación, explica en lenguaje simple para qué se usa, permite revocarlo y garantiza que las trazas se tratan de forma anónima y solo se publican agregados.

**3. Criterios de aceptación:**
- Antes de pedir el permiso del dispositivo se muestra una explicación breve ("para guiarte; si lo permites, también para mejorar el mapa de paraderos, de forma anónima").
- El uso de ubicación para guiar y el envío de trazas para el mapa son **consentimientos separados**; se puede aceptar el primero sin el segundo.
- El usuario puede revocar el envío de trazas en cualquier momento y se detiene de inmediato.
- Existe una política de privacidad corta accesible desde la app y el repositorio.
- Ninguna API pública ni la galería del evento expone trazas individuales ni ubicaciones exactas de personas.
- El usuario puede solicitar borrar sus datos: si tiene cuenta, mediante **eliminar cuenta** (RF-35); si es invitado, mediante "borrar mis datos" ligado a su identificador anónimo. En ambos casos el sistema los elimina o anonimiza de forma irreversible.
- Cuando existe cuenta, el consentimiento (guía y telemetría) queda guardado en el perfil y se aplica en todos los dispositivos; revocarlo en uno lo revoca en todos.
- Los datos personales no aparecen en la bitácora ni en la descripción del proyecto.

**4. Historia de usuario:** *Como usuaria, quiero decidir si comparto mi ubicación y poder retirarla cuando quiera, para sentirme segura usando la app.*

**5. Datos que intervienen:** `consent {guidance, telemetry, granted_at, revoked_at}`, `anon_session_id`, política de privacidad, solicitud de borrado, registros asociados.

---

### RF-30 — Entrega y bitácora del proyecto
**Prioridad:** P0 · **Tipo:** Funcional (del proyecto) · **Trazabilidad:** Sec. 1.4–1.5 y 12; reglas del evento.

**1. Título:** Cumplimiento de entrega y bitácora pública.

**2. Descripción:** El proyecto debe poder entregarse con los cuatro elementos obligatorios y mantener una bitácora pública de avances, ambos con hechos verificables y sin secretos ni datos personales.

**3. Criterios de aceptación:**
- La entrega contiene: URL de despliegue funcional, URL de presentación, URL del repositorio y descripción en Markdown (problema, usuario, funcionamiento, limitaciones).
- `andes project` confirma que los cuatro datos están guardados.
- La URL de despliegue y la presentación funcionan en **ventana privada, sin sesión y sin localhost**, verificado en **otra máquina**.
- Hay un primer envío de entrega temprano (≈ hora 9) y se corrige después.
- Se publica al menos un `project update` por hito (datos cargados, motor listo, primera URL pública, pruebas con usuarios, bloqueos).
- La bitácora y la descripción no contienen claves, tokens, códigos de sponsors ni datos personales de usuarios.
- El repositorio no contiene archivos `.env` con valores reales y tiene `.env.example`.

**4. Historia de usuario:** *Como equipo, queremos cumplir todos los requisitos de entrega a tiempo y con la bitácora al día, para que el jurado pueda evaluar nuestro trabajo sin fricción.*

**5. Datos que intervienen:** `deployment_url`, `presentation_url`, `github_url`, `description.md`, historial `project updates`, `.env.example`, resultados de pruebas en incógnito.

---

## G. Cuentas, sesiones e historial

> **Nota de diseño (leer antes de G):** el equipo usará **Firebase** (decisión del equipo; este documento **no la impone**, solo la considera para ajustar requerimientos). Los requerimientos de esta sección están escritos de forma **neutral respecto al proveedor de identidad**, pero incluyen en cada caso las consecuencias prácticas de un proveedor gestionado (identificador de usuario estable, tokens, reglas de acceso, comportamiento en incógnito).
>
> **Tensión crítica con las reglas del evento:** la organización abre la app **en ventana privada, sin sesión iniciada**, y el jurado no va a registrarse para probarla. Por eso **el login nunca puede ser obligatorio** para el flujo principal: existe el modo **invitado** (RF-33) y el modo demo (RF-20). Las cuentas aportan **historial, continuidad entre dispositivos y mejor evidencia de tracción**, no una barrera de entrada.
>
> **Efectos de las cuentas en otros requerimientos** (ya aplicados en este documento): RF-12/RF-13 (reanudar viaje), RF-20 (demo sin registro), RF-22 y RF-23 (eventos y tracción por usuario), RF-26 (preferencias en el perfil), RF-29 (consentimiento y borrado ligados a la cuenta), RNF-11, RNF-13 y RNF-17 (secretos, privacidad e incógnito).

### RF-31 — Registro de cuenta
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Pedido del equipo (mantener sesiones y asociar historial); tracción por usuario.

**1. Título:** Registro de usuario.

**2. Descripción:** El sistema permite crear una cuenta con correo y contraseña (y opcionalmente con un proveedor externo como Google) para conservar el historial de viajes y las preferencias. El registro es **opcional** y se ofrece sin bloquear el uso de la app.

**3. Criterios de aceptación:**
- El formulario solicita solo lo mínimo: correo, contraseña y (opcional) nombre para mostrar.
- **Dado** un correo con formato inválido, **entonces** se muestra un error de validación inmediato, antes de enviar.
- **Dado** una contraseña de menos de 8 caracteres, **entonces** se rechaza con un mensaje que explica el requisito (la política es propia del sistema, aunque el proveedor admita menos).
- **Dado** un correo ya registrado, **entonces** se informa con un mensaje claro y se ofrece iniciar sesión o recuperar la contraseña.
- La aplicación **nunca almacena ni registra contraseñas**; la custodia de credenciales la realiza el proveedor de identidad.
- Al registrarse se crea un **perfil de usuario** con identificador estable (`user_id`), correo, nombre (opcional), fecha de alta y versión de la política de privacidad aceptada.
- El usuario debe aceptar la política de privacidad antes de crear la cuenta (checkbox no premarcado).
- La verificación de correo **puede** solicitarse, pero **no bloquea** planificar ni ver historial reciente.
- Los errores del proveedor se traducen a mensajes en español claro (RNF-15, RNF-26) sin exponer códigos técnicos.
- El registro se completa en **p95 ≤ 3 s** (RNF-28) y deja al usuario con sesión iniciada.

**4. Historia de usuario:** *Como pasajera frecuente, quiero crear una cuenta en pocos pasos, para que mis viajes queden guardados y no tener que empezar de cero cada vez.*

**5. Datos que intervienen:** `User {user_id, email, display_name?, provider (PASSWORD|GOOGLE|...), email_verified, created_at, privacy_policy_version, last_login_at}`, credenciales (en poder del proveedor, **no** en la base propia), resultado del registro, mensajes de error traducidos.

---

### RF-32 — Inicio de sesión y sesión persistente
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Pedido del equipo ("mantener sesiones").

**1. Título:** Inicio de sesión y mantenimiento de la sesión.

**2. Descripción:** Un usuario registrado puede iniciar sesión y mantenerla entre visitas y dispositivos. Las solicitudes a datos personales (historial, preferencias, viaje activo) se autentican con un token que el servidor verifica en cada llamada.

**3. Criterios de aceptación:**
- **Dado** credenciales correctas, **entonces** el usuario entra y vuelve a la pantalla donde estaba (o a S1).
- **Dado** credenciales incorrectas, **entonces** el mensaje es **genérico** ("Correo o contraseña incorrectos") y **no revela** si el correo existe.
- La sesión **persiste** al cerrar y reabrir la app o el navegador (hasta que el usuario cierre sesión o expire la renovación del token).
- El token de acceso se **renueva automáticamente** sin pedir de nuevo la contraseña mientras la sesión sea válida.
- Toda ruta de datos personales (`/me/*`, historial, preferencias) exige token válido; sin él responde `401` con código estable `UNAUTHENTICATED`.
- El servidor **verifica firma, expiración y audiencia** del token en cada solicitud protegida (RNF-28); no confía en datos de identidad enviados por el cliente.
- Tras **5 intentos fallidos seguidos** se aplica un retraso o bloqueo temporal (limitación de intentos).
- **Dado** que el almacenamiento del navegador está bloqueado (incógnito), **entonces** el inicio de sesión funciona durante esa visita y se informa que no se recordará al cerrar (o se ofrece continuar como invitado).
- Existe indicador visible de "sesión iniciada como …" y acceso a cerrar sesión.
- El usuario puede iniciar sesión desde **más de un dispositivo** y ve el mismo historial.

**4. Historia de usuario:** *Como usuario registrado, quiero seguir con mi sesión abierta cada vez que vuelva a la app, para ver mis viajes anteriores sin volver a escribir mi clave.*

**5. Datos que intervienen:** credenciales (en el proveedor), token de identidad y de renovación, `user_id`, fecha/hora de caducidad del token, contador de intentos fallidos, estado de persistencia del almacenamiento local, código `UNAUTHENTICATED`.

---

### RF-33 — Uso como invitado y vinculación posterior a una cuenta
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Reglas del evento (demo en incógnito sin sesión); tracción.

**1. Título:** Acceso como invitado y conversión a cuenta.

**2. Descripción:** Cualquier persona puede usar el flujo completo de planificar, comparar, seguir y replanificar **sin registrarse**. El sistema le asigna una identidad anónima. Si luego decide crear cuenta, **su historial de invitado se conserva** y pasa a su cuenta.

**3. Criterios de aceptación:**
- Al abrir la app por primera vez **no se exige** login ni registro para ningún paso del flujo P0.
- El invitado recibe un identificador anónimo estable (`anon_session_id`) mientras el almacenamiento lo permita.
- **Dado** que el almacenamiento está bloqueado, **entonces** el flujo funciona igualmente durante la visita (la identidad vive en memoria) y se informa que el historial no se guardará.
- **Dado** un invitado con 3 viajes que crea una cuenta, **entonces** esos 3 viajes aparecen en su historial (vinculación `anon_session_id → user_id`), sin duplicarse.
- **Dado** que el usuario inicia sesión en una cuenta que ya existe estando como invitado con viajes, **entonces** se le pregunta si desea **fusionar** el historial de invitado con la cuenta; si acepta, se fusiona sin pérdida; si rechaza, el historial de invitado se descarta o se conserva separado según su elección.
- Después del **primer viaje completado** se muestra una invitación **no bloqueante** a crear cuenta ("Guarda tu historial"), descartable.
- Los viajes de invitados cuentan como **uso externo** en la tracción (RF-23) pero se distinguen de los de cuentas registradas.
- El modo demo (RF-20) funciona sin registro, y el jurado puede completarlo en ≤ 2 min sin crear cuenta.
- Un invitado tiene una **retención de historial limitada** (p. ej. 30 días o solo en el dispositivo) documentada en la política de privacidad.

**4. Historia de usuario:** *Como jurado o visitante que abre el enlace por primera vez, quiero probar la app sin crear una cuenta, y si me gusta, guardar lo que hice después.*

**5. Datos que intervienen:** `anon_session_id`, `user_id` (al vincular), `link_event {anon_session_id, user_id, linked_at}`, `TripSession.user_id` (nulo para invitados), decisión de fusión, plazo de retención de invitados.

---

### RF-34 — Historial de viajes asociado al usuario
**Prioridad:** P0 · **Tipo:** Funcional · **Trazabilidad:** Pedido del equipo ("asociar historial de rutas con el usuario").

**1. Título:** Historial de rutas del usuario.

**2. Descripción:** El sistema guarda cada viaje del usuario (planificado, en curso, completado o abandonado) con una **copia fija** del recorrido elegido, y permite consultarlo, repetirlo o eliminarlo. Cada usuario ve **solo su propio** historial.

**3. Criterios de aceptación:**
- Cada viaje con alternativa seleccionada se asocia a `user_id` (o a `anon_session_id` si es invitado).
- La pantalla "Mis viajes" lista, de más reciente a más antiguo: fecha/hora, origen y destino (nombres), alternativa elegida, costo estimado y gastado, estado (`COMPLETED|ABANDONED|ACTIVE`) y número de replanificaciones.
- Al abrir un viaje se ve el **detalle por tramos** tal como se eligió, **con su fecha de datos** (`data_version`), de modo que no cambia aunque las rutas se actualicen después.
- La acción **"Repetir este viaje"** precarga origen, destino y condiciones del viaje antiguo y **recalcula con los datos actuales** (no reutiliza el resultado viejo).
- Hay paginación o carga progresiva (p. ej. 20 por página); la lista inicial carga en **p95 ≤ 1,5 s** (RNF-01).
- El usuario puede **eliminar un viaje individual** del historial; el borrado es efectivo de inmediato para el usuario y definitivo en ≤ 24 h.
- Un viaje **activo** puede **reanudarse** desde el historial en cualquier dispositivo de la cuenta (RF-12).
- **Dado** un usuario A autenticado, **cuando** intenta acceder al viaje de un usuario B por su identificador, **entonces** recibe `403/404` y no se filtra información (RNF-29).
- El historial **no incluye trazas GPS** ni coordenadas exactas de paso; solo origen, destino y recorrido planificado (RNF-13).
- Un historial vacío muestra un mensaje útil ("Aún no tienes viajes") y un acceso a planificar.

**4. Historia de usuario:** *Como trabajador que hace el mismo trayecto cada semana, quiero ver y repetir mis viajes anteriores, para planificar en dos toques lo que ya hice antes.*

**5. Datos que intervienen:** `TripSession {id, user_id, anon_session_id, origin label/geom, destination label/geom, initial_budget_soles, spent_budget_soles, status, replan_count, selected_alternative (snapshot JSON), data_version, created_at, completed_at}`, `TripFeedback`, paginación (cursor), filtros opcionales por estado/fecha.

---

### RF-35 — Gestión de la cuenta (cerrar sesión, recuperar contraseña, eliminar cuenta)
**Prioridad:** P1 · **Tipo:** Funcional · **Trazabilidad:** Privacidad (RF-29); cuentas.

**1. Título:** Gestión de la cuenta y de los datos asociados.

**2. Descripción:** El usuario puede cerrar sesión, recuperar su contraseña, editar su nombre y **eliminar su cuenta y sus datos asociados** de forma definitiva.

**3. Criterios de aceptación:**
- **Cerrar sesión** invalida el acceso en ese dispositivo de inmediato y limpia los datos locales sensibles.
- **Recuperar contraseña:** al ingresar un correo se envía un enlace de restablecimiento; la respuesta es **la misma exista o no la cuenta** (no revela existencia).
- El usuario puede editar su nombre para mostrar; el correo solo se cambia tras re-autenticación.
- **Eliminar cuenta:** exige **re-autenticación reciente**, muestra qué se borrará y pide confirmación explícita.
- Al eliminar la cuenta se borran: perfil, historial de viajes, preferencias (incluida la memoria externa si existe) y vínculo con identificadores anónimos; los eventos de producto se **anonimizan** de forma irreversible (se quita `user_id`).
- Tras eliminar, el usuario no puede iniciar sesión con esas credenciales y las sesiones abiertas en otros dispositivos dejan de ser válidas.
- La eliminación se completa en **≤ 24 h** y el usuario recibe confirmación en pantalla.
- Cada acción de cuenta queda registrada en un log de auditoría **sin datos personales sensibles**.

**4. Historia de usuario:** *Como usuaria que ya no quiere usar la app, quiero poder borrar mi cuenta y mis viajes, para sentir que controlo mis datos.*

**5. Datos que intervienen:** `User`, solicitud de borrado `{user_id, requested_at, completed_at}`, tokens de restablecimiento (gestionados por el proveedor), historial, preferencias, eventos a anonimizar, registro de auditoría.

---

## G. Integridad de los datos colaborativos (resistencia a manipulación)

> **Contexto de la amenaza.** En 2020 el artista Simon Weckert paseó ~99 teléfonos en un carrito por una calle vacía de Berlín y Google Maps la mostró como atascada: los teléfonos se movían a velocidad de caminata y el sistema interpretó "mucha gente lenta" como tráfico. La lección: **un sistema que infiere el mundo a partir de ubicaciones de usuarios es manipulable si cree todo lo que recibe.** En Cyberon, la única función que aprende de ubicaciones de usuarios es la inferencia de paraderos de facto (RF-17/RF-18); estos requerimientos la blindan. Ver el análisis completo en el chat del proyecto y el modelo de amenazas de RF-36.

### RF-36 — Integridad de la telemetría y resistencia al envenenamiento de datos
**Prioridad:** P1 (los puntos marcados "[P0]" en los criterios son obligatorios incluso si Motor 2 se recorta) · **Tipo:** Funcional (seguridad de datos) · **Trazabilidad:** Motor 2 (RF-16, 17, 18); RF-14 (feedback); RF-21 (alertas); RF-22/23 (tracción).

**1. Título:** Defensa contra manipulación de datos colaborativos (ataque del "carrito de teléfonos" y similares).

**2. Descripción:** El sistema debe asegurar que ningún actor pueda fabricar, borrar o alterar información del mapa (paraderos, confianza, alertas, métricas) simulando usuarios o ubicaciones. La estrategia es de **defensa en capas**: (1) limitar el **radio de impacto** de los datos colaborativos; (2) exigir que la señal sea **físicamente plausible**; (3) hacer **costoso** simular muchas fuentes; (4) **detectar y revertir** manipulaciones. No se promete invulnerabilidad absoluta: se promete que el daño posible es **acotado, visible y reversible**.

**3. Criterios de aceptación:**

*Capa 1 — Radio de impacto limitado (diseño)*
- **[P0]** Los datos colaborativos **nunca modifican ni eliminan** datos oficiales (rutas, paraderos ATU/OSM, tarifas). Solo pueden **añadir** puntos marcados como "inferido" (RF-18).
- **[P0]** El cálculo de rutas, costos, tiempos y esperas **no usa velocidades ni densidades de usuarios** (no hay "tráfico colaborativo"): el ataque del carrito no tiene un parámetro que mover. Si en el futuro se añade una señal colaborativa de congestión o espera, debe pasar por todas las capas de este requerimiento antes de afectar resultados.
- **[P0]** Un paradero inferido solo entra al ruteo como nodo de baja confianza **si el usuario lo acepta** (o con penalización explícita) y siempre rotulado "inferido"; nunca como paradero oficial.

*Capa 2 — Plausibilidad física de la señal*
- **[P0]** Un evento de abordaje exige **espera estática real** (permanencia en radio ≤ R durante ≥ T) **seguida** de salto a velocidad vehicular. Una nube de teléfonos que **avanza a velocidad de caminata** (≈ 1–1,5 m/s, desplazándose más que R en la ventana T) **no genera ningún evento** y se descarta como "movimiento peatonal sostenido".
- **[P0]** Tras el salto de velocidad, la trayectoria debe **seguir una ruta de transporte conocida** (alineación con su polilínea dentro de ≤ 25 m durante ≥ 300 m) y, cuando haya paraderos oficiales en el trayecto, mostrar **patrón parar-y-seguir** (desaceleración/permanencia cerca de ellos). Si no cumple, el evento recibe peso 0 (un auto cualquiera no cuenta como bus).
- **[P0]** Se rechazan pings físicamente imposibles (salto de posición > velocidad máxima plausible, aceleraciones irreales, precisión reportada < 3 m de forma sospechosamente constante, marcas de tiempo fuera de orden).
- **[P1]** *Corroboración por sensores:* cuando el dispositivo lo permita, la velocidad de caminata reportada por GPS debe ser coherente con **cadencia de pasos/acelerómetro**; teléfonos "sin pasos" que se mueven a velocidad peatonal (arrastrados en un carrito) pierden peso. Si el dispositivo no ofrece el sensor, el peso es neutro (no se penaliza ni se bonifica).
- **[P1]** En app nativa Android, descartar o reducir el peso de lecturas con la marca de **ubicación simulada** (`mock location`); en web, esta señal no existe y no se asume.

*Capa 3 — Encarecer la simulación de muchas fuentes (anti-Sybil)*
- **[P0]** **Independencia efectiva:** antes de contar sesiones para el umbral de RF-18, las sesiones se **fusionan en grupos** cuando sus trayectorias son casi idénticas (p. ej. a < 10 m entre sí durante ≥ 80 % del tiempo previo al abordaje) o llegan al punto **en el mismo instante** (dispersión de llegadas < 20 s). El umbral usa el **número de grupos independientes** (`n_eff`), no el de sesiones. 99 teléfonos en un carrito cuentan como **1**.
- **[P0]** **Dispersión temporal de llegadas:** un paradero legítimo recibe personas que llegan **escalonadamente**; el clúster debe mostrar llegadas distribuidas en ≥ 2 minutos y esperas de distinta duración. Llegadas sincronizadas ⇒ peso reducido.
- **[P0]** **Tope por fuente:** cada sesión/cuenta/dispositivo aporta **como máximo 1 evento por paradero candidato por día**; límites de sesiones nuevas por IP/dispositivo y por minuto (RNF-12).
- **[P1]** **Puntaje de confianza del aportante:** sesiones recién creadas pesan poco; ganan peso las cuentas con viajes completados, feedback coherente y trayectorias compatibles con rutas reales; pierden peso las que aportan datos descartados.
- **[P2]** Atestación de dispositivo/aplicación (p. ej. Play Integrity / App Attest) y verificación anti-bots (CAPTCHA ligero) en el registro: solo en app nativa y si el tiempo lo permite.

*Capa 4 — Cuarentena, detección y reversión*
- **[P0]** **Cuarentena:** un candidato a paradero inferido no es visible hasta cumplir **todas** estas condiciones: `n_eff ≥ 3`, dispersión temporal de llegadas, alineación post-abordaje válida y **persistencia** (observado en ≥ 2 ventanas de 30 min distintas; en producción, en ≥ 3 días distintos). Hasta entonces se mantiene como `CANDIDATE` y no aparece en la app.
- **[P0]** **Decaimiento:** la confianza de un paradero inferido disminuye con el tiempo sin evidencia nueva y se elimina por debajo de un mínimo.
- **[P1]** **Detección de anomalías:** alerta interna cuando una celda geográfica recibe un pico de sesiones (p. ej. > 5 desviaciones estándar sobre su línea base horaria), muchas sesiones desde la misma IP/ASN o trayectorias duplicadas; la celda pasa a **cuarentena automática** y se notifica al equipo.
- **[P0]** **Trazabilidad y reversión:** cada paradero inferido conserva la lista (con identificadores anónimos) de eventos que lo originaron, de modo que se puedan **invalidar en bloque** (por sesión, IP o ventana de tiempo) y **recalcular** el paradero. Existe una acción administrativa de "revertir lote" y de "bloquear fuente".
- **[P0]** **Retroalimentación humana:** si usuarios reales marcan un paradero inferido como incorrecto ("no subí aquí"), su confianza baja; con N reportes independientes pasa a cuarentena. El reporte de usuarios **nunca** altera por sí solo datos oficiales (RF-14).

*Otras superficies de manipulación (misma filosofía)*
- **[P0]** **Tracción:** las métricas del panel (RF-23) excluyen sesiones simuladas, del equipo y las que no completan una acción real; se descartan ráfagas desde una misma IP/dispositivo; el panel indica el criterio de conteo. **Prohibido** inflar la tracción (ver reglas del evento: "tráfico automatizado no cuenta").
- **[P0]** **Alertas (RF-21):** el texto recuperado de la web es **dato, no instrucción**; nunca se pasa sin saneamiento a un modelo de lenguaje con capacidad de acción; las alertas solo se etiquetan "verificada" si provienen de dominios oficiales en lista permitida; el resto se muestra como "no verificada" con su fuente.
- **[P0]** **Lenguaje natural (RF-04):** el texto del usuario solo puede producir los campos del esquema validado; no puede cambiar reglas del sistema ni acceder a otros datos.
- **[P0]** **Reportes de tarifa/paradero (RF-14):** se almacenan para revisión; ninguna tarifa oficial cambia sin verificación humana o fuente oficial.

*Verificación (pruebas obligatorias — sirven también como respuesta en vivo al jurado)*
- **[P0]** **Prueba "carrito":** 99 sesiones sintéticas co-ubicadas moviéndose a ~1,2 m/s durante 10 min ⇒ **0** eventos de abordaje, **0** paraderos candidatos.
- **[P0]** **Prueba "carrito + auto":** 99 sesiones co-ubicadas quietas y luego trasladadas en un vehículo fuera de cualquier ruta ⇒ `n_eff = 1`, el candidato **no** es visible.
- **[P0]** **Prueba "bots dispersos":** 20 sesiones desde la misma IP con llegadas simuladas escalonadas ⇒ topadas por fuente/IP; el candidato **no** supera cuarentena.
- **[P0]** **Prueba legítima (control positivo):** 5 sesiones independientes con llegadas escalonadas que abordan una ruta real ⇒ el paradero **sí** se promueve tras cumplir la persistencia configurada.
- **[P0]** **Prueba de reversión:** invalidar un lote de eventos elimina o degrada el paradero que originaron en ≤ 1 ciclo del proceso.
- Las pruebas corren en CI y sus resultados se incluyen en `docs/` (p. ej. `docs/THREAT_MODEL.md`).

**4. Historia de usuario:** *Como pasajera, quiero que nadie pueda inventar un paradero o falsear información del mapa usando muchos teléfonos o bots, para confiar en que lo que veo refleja la calle de verdad.*

**5. Datos que intervienen:** `GpsPing` (precisión, velocidad, rumbo, marca de tiempo, fuente), `boarding_event` (con `n_eff`, dispersión temporal, alineación a ruta, peso), grupos de sesiones co-móviles, `TransitStop (stop_type=CANDIDATE|INFERRED_DE_FACTO)`, lista de eventos de origen por paradero, contadores por fuente/IP/dispositivo, línea base de actividad por celda, puntaje de confianza del aportante, reportes de usuarios sobre paraderos, lista de dominios oficiales permitidos, bitácora de reversiones.

---

# PARTE II — REQUERIMIENTOS NO FUNCIONALES

> Todas las cifras son **metas propuestas** (ver RNF-24 para medirlas). "Medido en" indica dónde se verifica.

## A. Rendimiento y latencia

### RNF-01 — Latencia de planificación
**Prioridad:** P0 · **Categoría:** Rendimiento · **Trazabilidad:** RF-05, RF-07; demo de 3 min.

**1. Título:** Latencia de cálculo de alternativas.

**2. Descripción:** La planificación de un viaje debe responder lo bastante rápido para sostener una demostración en vivo y el uso en la calle, incluso con el motor calculando restricciones multicriterio.

**3. Criterios de aceptación:**
- `POST /api/trips/plan`: **p50 ≤ 800 ms, p95 ≤ 2 s, p99 ≤ 3 s**, medido en el entorno desplegado con el dataset real del eje (sin contar la latencia de red del cliente).
- Tiempo máximo de búsqueda del motor (*timeout*): **3 s**; al excederlo se devuelve el mejor conjunto parcial con advertencia.
- Las consultas agregadas del panel de tracción responden en **p95 ≤ 1 s**.
- La búsqueda no realiza llamadas de red síncronas en su bucle (los datos están en memoria).
- Las llamadas opcionales (alertas, geocodificación, OSRM) no bloquean la respuesta principal más de **1,5 s** (timeout con fallback).
- La métrica se registra por solicitud (duración, nº de etiquetas exploradas).

**4. Historia de usuario:** *Como usuario en la calle, quiero que las opciones aparezcan en pocos segundos, para decidir sin quedarme esperando con el celular en la mano.*

**5. Datos que intervienen:** duración de solicitud (ms), tamaño del grafo (nodos/aristas), nº de etiquetas exploradas, `K` por estado, timeouts configurables, resultado parcial (booleano).

---

### RNF-02 — Latencia de replanificación
**Prioridad:** P0 · **Categoría:** Rendimiento · **Trazabilidad:** RF-13.

**1. Título:** Latencia de recálculo durante el viaje.

**2. Descripción:** La replanificación ocurre en un momento de estrés (el usuario está parado en la calle), por lo que debe ser al menos tan rápida como la planificación inicial.

**3. Criterios de aceptación:**
- `POST /api/trips/:id/replan`: **p95 ≤ 2 s** y **p99 ≤ 3 s** con el mismo dataset.
- Desde el toque del usuario hasta ver las nuevas alternativas: **≤ 3 s en p95** en una red móvil 4G típica (medido en dispositivo o emulación de red).
- Mientras se calcula se muestra un indicador de progreso inmediato (< 100 ms tras el toque).
- Un fallo de recálculo conserva el plan anterior visible y ofrece reintentar.

**4. Historia de usuario:** *Como pasajero parado en un paradero colapsado, quiero que el plan nuevo salga rápido, para no perder tiempo mientras decido qué hacer.*

**5. Datos que intervienen:** duración de replan (ms), `replan_count`, saldo restante, posición, tipo de red (4G/3G) en pruebas.

---

### RNF-03 — Carga inicial y arranque
**Prioridad:** P0 · **Categoría:** Rendimiento · **Trazabilidad:** RF-20, RF-24.

**1. Título:** Tiempo de carga inicial de la app y arranque del motor.

**2. Descripción:** La primera visita (la del jurado en un computador ajeno) debe cargar rápido; el backend debe arrancar y estar listo sin demoras que arruinen la demostración.

**3. Criterios de aceptación:**
- Carga inicial de la versión web (**Flutter web**, ver [cyberon-arquitectura.md](cyberon-arquitectura.md) sec. 12.1): pantalla de carga HTML visible en **≤ 1,5 s**; **tiempo hasta interactivo ≤ 8 s** en 4G simulada y **≤ 4 s** en banda ancha (equipo del jurado).
- Peso total inicial de la página (**sin mapa teselado**): **≲ 4 MB** comprimido (el motor de Flutter web pesa ~1,5–2 MB); el dataset de transporte y el mapa se cargan **de forma diferida**, después del primer pintado. Medir con Lighthouse y registrar el valor real (RNF-24).
- Arranque en frío del backend (carga del grafo en memoria): **≤ 20 s**; la ruta `/health` indica `READY` solo cuando el grafo está cargado.
- Si el servicio se suspende por inactividad, el primer acceso no puede fallar: se mantiene **calentado** (ping periódico o plan sin suspensión) durante el horario de evaluación.
- Los recursos estáticos usan caché y compresión.

**4. Historia de usuario:** *Como jurado que abre el enlace por primera vez, quiero que la app cargue en segundos, para empezar a evaluar sin esperar.*

**5. Datos que intervienen:** métricas de carga (FCP, TTI), tamaño del bundle, tiempo de carga del grafo, estado `/health`.

---

### RNF-04 — Fluidez de mapa e interfaz
**Prioridad:** P0 · **Categoría:** Rendimiento · **Trazabilidad:** RF-08, RF-15.

**1. Título:** Fluidez del mapa y de la interfaz.

**2. Descripción:** Los mapas con rutas y paraderos deben moverse con fluidez en teléfonos de gama media, sin congelar la interfaz.

**3. Criterios de aceptación:**
- Desplazamiento y zoom del mapa a **≥ 30 fps** en un teléfono Android de gama media.
- Se renderizan **como máximo 300 marcadores** simultáneos; por encima se agrupan.
- Las polilíneas de rutas se simplifican (p. ej. tolerancia ≈ 2–5 m) antes de enviarse al cliente.
- Alternar entre alternativas actualiza el mapa en **≤ 300 ms**.
- Ninguna tarea de cliente bloquea el hilo principal más de **100 ms** de forma sostenida.
- Los textos y botones responden al toque en **≤ 100 ms**.

**4. Historia de usuario:** *Como usuaria con un teléfono modesto, quiero que el mapa se mueva sin trabas, para poder revisar mi ruta fácilmente.*

**5. Datos que intervienen:** nº de marcadores, tamaño de polilíneas (puntos), fps medidos, tiempos de render.

---

### RNF-05 — Concurrencia y capacidad
**Prioridad:** P0 · **Categoría:** Rendimiento / Capacidad · **Trazabilidad:** Tracción; demo con ~100 asistentes.

**1. Título:** Capacidad bajo uso simultáneo.

**2. Descripción:** Durante el evento, decenas de participantes podrían usar la app a la vez (más el jurado), por lo que el sistema debe mantener su rendimiento bajo esa carga.

**3. Criterios de aceptación:**
- Soporta **50 usuarios concurrentes** realizando planificaciones con las latencias de RNF-01 (**p95 ≤ 3 s**) en una prueba de carga.
- Soporta **100 solicitudes de `/plan` por minuto** sostenidas sin errores 5xx.
- Ingesta de telemetría: **≥ 200 pings/s** sin pérdida y sin afectar la latencia de `/plan` (p95 de `/plan` no sube > 25 %).
- Bajo sobrecarga, el sistema responde `429`/`503` controlados (no cuelgues) y se recupera sin reinicio manual.
- El uso de memoria del proceso del motor se mantiene por debajo del **75 %** del límite del plan de hosting.
- La conexión a la base de datos usa un *pool* con límites definidos.

**4. Historia de usuario:** *Como organizadores de la prueba, queremos que decenas de personas usen la app al mismo tiempo sin que se caiga, para que el jurado la vea funcionando en pleno uso.*

**5. Datos que intervienen:** usuarios concurrentes, tasa de solicitudes (req/min), pings/s, uso de CPU/memoria, tamaño del *pool* de conexiones, códigos de estado HTTP.

---

## B. Disponibilidad y fiabilidad

### RNF-06 — Disponibilidad durante la ventana de evaluación
**Prioridad:** P0 · **Categoría:** Disponibilidad · **Trazabilidad:** Reglas del evento; RF-30.

**1. Título:** Disponibilidad de la demo.

**2. Descripción:** La aplicación debe estar accesible y funcional durante todo el periodo en que la organización la abre y evalúa (sábado tarde a domingo ~14:00), con especial exigencia en el bloque de demos.

**3. Criterios de aceptación:**
- Disponibilidad **≥ 99 %** entre el primer despliegue y las 14:00 del domingo; **100 % objetivo** durante 10:00–13:30 del domingo (demos).
- Existe un *monitor externo* (ping cada ≤ 5 min a `/health`) con alerta ante caída.
- No hay despliegues arriesgados entre las 07:00 y el fin de las demos (**congelamiento**).
- Existe un procedimiento de **rollback** a la versión anterior en ≤ 10 min.
- El servicio no depende de un único plan que se suspenda por inactividad (RNF-03).
- La base de datos tiene copia de seguridad reciente (RNF-25) antes del congelamiento.

**4. Historia de usuario:** *Como jurado, quiero que el enlace funcione cuando lo abra, para poder evaluar el proyecto sin incidentes.*

**5. Datos que intervienen:** registros del monitor externo, `/health`, versión desplegada, historial de despliegues, copia de seguridad.

---

### RNF-07 — Tolerancia a fallos de servicios externos
**Prioridad:** P0 · **Categoría:** Fiabilidad · **Trazabilidad:** Regla R13; principio de degradación elegante.

**1. Título:** Degradación elegante ante fallos de terceros.

**2. Descripción:** Ningún servicio externo (rutas peatonales/vehiculares, búsqueda de alertas, modelo de lenguaje, mensajería, memoria) puede ser un punto único de falla de la demostración principal.

**3. Criterios de aceptación:**
- Cada integración externa tiene **timeout explícito** (≤ 1,5–3 s según el caso), **reintento limitado** (máx. 1) y **fallback** definido.
- **Dado** que OSRM no responde, **entonces** se usa la aproximación local de distancia/tiempo y se muestra "valores aproximados".
- **Dado** que la búsqueda de alertas falla, **entonces** la comparación se muestra sin alertas.
- **Dado** que el modelo de lenguaje falla, **entonces** se muestran los controles manuales.
- **Dado** que el servicio de memoria o mensajería cae, **entonces** el flujo P0 completo sigue funcionando.
- Se usa un *circuit breaker* simple: tras N fallos consecutivos se omite el servicio por un periodo breve.
- Las respuestas cacheadas válidas se sirven si el proveedor está caído.
- Con **todos** los servicios opcionales desactivados, el flujo P0 funciona de principio a fin (prueba obligatoria antes de entregar).

**4. Historia de usuario:** *Como jurado, quiero que la app siga funcionando aunque falle un servicio de terceros, para que mi evaluación no dependa de la suerte.*

**5. Datos que intervienen:** configuración de timeouts/reintentos, estado de cada proveedor, contador de fallos, caché, banderas `degraded:true` en respuestas.

---

### RNF-08 — Precisión y corrección de los cálculos
**Prioridad:** P0 · **Categoría:** Corrección · **Trazabilidad:** RF-05, RF-06, RF-13.

**1. Título:** Exactitud de costos, distancias y saldo.

**2. Descripción:** El usuario toma decisiones con dinero y esfuerzo reales; los números mostrados deben ser consistentes y calculados sin errores aritméticos.

**3. Criterios de aceptación:**
- Los importes se manejan en **céntimos enteros** o decimal exacto (nunca coma flotante binaria) y se muestran con 2 decimales.
- La suma de costos de tramos coincide **exactamente** con el costo total mostrado.
- La caminata total mostrada es igual a la suma de los tramos a pie; ninguna caminata continua mostrada supera el límite del usuario.
- La distancia a pie calculada (aproximación local) difiere **≤ 25 %** de la distancia real por calle en los viajes de referencia; la refinada por servicio de rutas, **≤ 10 %**.
- El saldo restante nunca es negativo; si el gasto confirmado supera el presupuesto, se informa y el saldo se muestra como S/ 0,00 con aviso.
- Los 10 viajes de referencia ("de oro") y los casos de prueba de RNF-21 pasan en cada despliegue.

**4. Historia de usuario:** *Como usuario con poco dinero, quiero que las cuentas que me muestran estén bien, para no quedarme sin saldo por un error de cálculo.*

**5. Datos que intervienen:** importes en céntimos, distancias (m), tolerancias de comparación, viajes de referencia con resultado esperado.

---

## C. Calidad y frescura de datos

### RNF-09 — Integridad y honestidad de datos
**Prioridad:** P0 · **Categoría:** Calidad de datos · **Trazabilidad:** Regla R4; RF-09.

**1. Título:** Trazabilidad y honestidad de los datos.

**2. Descripción:** Todo dato de transporte debe poder rastrearse a una fuente y fecha, y el sistema nunca presenta como hecho lo que es estimación o simulación.

**3. Criterios de aceptación:**
- **100 %** de las rutas, paraderos y tarifas tienen `source` y `last_verified_at` no nulos.
- **0** datos simulados o estimados se muestran sin su etiqueta correspondiente (comprobable por prueba automatizada sobre las respuestas de la API).
- Los datos curados a mano están declarados como tales en el documento de fuentes del repositorio.
- Las restricciones de la base de datos (`NOT NULL`, `CHECK`, claves foráneas) impiden registros inválidos (tipos de paradero, certidumbre de tarifa, presupuestos negativos).
- La API nunca devuelve valores `NaN`/`null` en campos monetarios o de distancia visibles.

**4. Historia de usuario:** *Como jurado técnico, quiero poder comprobar de dónde sale cada dato y que lo simulado esté claramente marcado, para confiar en la demostración.*

**5. Datos que intervienen:** `source`, `last_verified_at`, `fare_certainty`, `is_simulated`, restricciones del esquema, documento de fuentes.

---

### RNF-10 — Frescura de los datos
**Prioridad:** P1 · **Categoría:** Calidad de datos · **Trazabilidad:** RF-21, RF-28.

**1. Título:** Antigüedad máxima aceptable de los datos.

**2. Descripción:** El usuario debe saber cuán actuales son los datos y el sistema debe evitar servir información caducada como si fuera vigente.

**3. Criterios de aceptación:**
- La fecha del dataset (`data_version`) es visible en la interfaz.
- Las alertas de contingencia con más de **24 h** se ocultan o se marcan como caducadas.
- Las tarifas con más de **30 días** sin verificación se marcan `ESTIMATED`.
- Los paraderos inferidos sin nueva evidencia en **14 días** reducen su confianza de forma documentada.
- Una carga de datos fallida no sobrescribe la versión anterior válida.
- La caché de alertas expira entre **10 y 30 min**.

**4. Historia de usuario:** *Como usuario, quiero saber qué tan reciente es la información, para no confiar en un aviso o precio que ya cambió.*

**5. Datos que intervienen:** `data_version`, `last_verified_at`, `fare_checked_at`, `published_at`, `expires_at`, parámetros de caducidad.

---

## D. Seguridad y privacidad

### RNF-11 — Seguridad de secretos y credenciales
**Prioridad:** P0 · **Categoría:** Seguridad · **Trazabilidad:** Reglas R10, R7; guía del evento.

**1. Título:** Protección de claves, tokens y códigos.

**2. Descripción:** Ninguna credencial (claves de APIs, tokens, códigos de sponsors, contraseñas de base de datos) puede quedar en el repositorio, el cliente, la bitácora ni la descripción públicas.

**3. Criterios de aceptación:**
- **0** secretos en el historial de Git (verificado con un escáner de secretos antes de hacer público el repo y antes de la entrega).
- Las **credenciales administrativas del proveedor de identidad y de datos** (cuentas de servicio, claves privadas) nunca están en el repositorio ni en el cliente; viven solo como secretos del servidor. La configuración pública del cliente puede estar en el código, pero **no se confía en ella para la seguridad** (RNF-29).
- Las claves se leen solo de variables de entorno del servidor; **ninguna** clave de proveedor se envía al cliente (las llamadas a terceros se hacen desde el backend).
- Existe `.env.example` solo con nombres de variables.
- Los códigos de `andes credits` no aparecen en ningún archivo, commit, avance ni descripción.
- **Si una clave se expone**, se rota de inmediato y se registra la acción.
- Las claves de sponsors usan permisos mínimos (modo test cuando exista).
- Los endpoints administrativos y de simulación requieren token y no están enlazados en la interfaz pública.

**4. Historia de usuario:** *Como equipo, queremos asegurarnos de que ninguna clave se filtre al publicar el código, para no perder créditos ni comprometer cuentas.*

**5. Datos que intervienen:** variables de entorno, `ADMIN_DEMO_TOKEN`, historial de Git, resultado del escáner de secretos, `.env.example`.

---

### RNF-12 — Validación y seguridad de entradas
**Prioridad:** P0 · **Categoría:** Seguridad · **Trazabilidad:** RF-03, RF-04, RF-16.

**1. Título:** Validación de entradas y protección de la API.

**2. Descripción:** Toda entrada (formularios, texto libre, coordenadas, lotes de telemetría, mensajes entrantes) se valida en el servidor para evitar errores, abusos o inyecciones.

**3. Criterios de aceptación:**
- Todas las solicitudes se validan contra esquemas estrictos (tipos, rangos, longitudes); las inválidas devuelven `400` con código de error estable y sin detalles internos.
- Coordenadas fuera de rango o fuera de cobertura → error controlado (`OUT_OF_COVERAGE`/`INVALID_COORDINATES`).
- Texto libre limitado a **500 caracteres**; nunca se interpola en SQL ni en instrucciones privilegiadas (consultas parametrizadas).
- Tamaño máximo de cuerpo de solicitud (p. ej. **256 KB**) y de lote de telemetría (p. ej. **200 pings**).
- **Limitación de tasa**: p. ej. **60 solicitudes/min por IP o sesión** en `/plan` y **10/min** en el intérprete de lenguaje natural; exceder devuelve `429`.
- CORS restringido a los orígenes de la app; cabeceras de seguridad básicas (HSTS, `X-Content-Type-Options`).
- Los mensajes de error no revelan trazas de pila, rutas de archivos ni consultas.
- Tráfico solo por **HTTPS**.

**4. Historia de usuario:** *Como equipo, queremos que la API rechace datos malformados o abusivos, para que la app no se caiga ni sea explotada durante la demostración.*

**5. Datos que intervienen:** esquemas de validación, límites de tamaño, contadores de tasa por IP/sesión, orígenes CORS permitidos, códigos de error.

---

### RNF-13 — Privacidad de ubicación y datos personales
**Prioridad:** P0 · **Categoría:** Privacidad · **Trazabilidad:** RF-16, RF-29; guía (excluir datos personales).

**1. Título:** Minimización y anonimato de datos personales.

**2. Descripción:** El sistema recoge solo lo necesario, usa identificadores anónimos y publica únicamente datos agregados, cumpliendo la exigencia del evento de excluir datos personales de contenido público.

**3. Criterios de aceptación:**
- Las trazas GPS se guardan con un **identificador seudónimo de viaje**; **ningún** campo de la tabla de trazas contiene teléfono, nombre, correo **ni el `user_id` de la cuenta**. La relación cuenta↔viaje existe solo en el historial (RF-34), separada de las trazas, de modo que las trazas no permitan reidentificar a una persona.
- Ninguna API pública devuelve trazas individuales; solo agregados (clústeres, conteos).
- La precisión de coordenadas de agregados públicos no permite ubicar a una persona (los clústeres exigen **≥ 3 sesiones distintas**).
- Las trazas crudas tienen **retención máxima de 7 días** (o hasta fin del evento) y luego se eliminan o agregan.
- El identificador de mensajería, si se usa, se guarda **con hash** y separado de las trazas.
- Hay un mecanismo de borrado por identificador anónimo (RF-29).
- No hay *tracking* de terceros (analíticas externas) sin consentimiento.

**4. Historia de usuario:** *Como usuaria, quiero que mi ubicación sea anónima y que nadie pueda seguir mis movimientos, para usar la app con tranquilidad.*

**5. Datos que intervienen:** `anon_session_id`, trazas GPS, plazos de retención, umbral de sesiones distintas, hash de identificador de mensajería, registros de consentimiento.

---

## E. Usabilidad y compatibilidad

### RNF-14 — Usabilidad móvil y uso en calle
**Prioridad:** P0 · **Categoría:** Usabilidad · **Trazabilidad:** Principio de diseño 6; sec. 5.2.

**1. Título:** Diseño *mobile-first* para uso en movimiento.

**2. Descripción:** La interfaz debe poder usarse con una mano, con poca interacción, y bajo condiciones adversas (sol, prisa, atención dividida).

**3. Criterios de aceptación:**
- Diseño *mobile-first*: totalmente usable desde **360 px de ancho** sin desplazamiento horizontal; también correcto en escritorio.
- Objetivos táctiles de **≥ 48×48 px**; separación suficiente para evitar toques erróneos.
- Un viaje completo (de origen a ver alternativas) en **≤ 6 toques** usando ubicación actual y valores por defecto.
- En la pantalla de seguimiento se muestra **una sola acción principal** con texto ≤ 100 caracteres.
- Estados de carga, error y vacío definidos en **todas** las pantallas (sin pantallas en blanco).
- Los errores indican **qué pasó y qué hacer**.
- **≥ 80 %** de personas de prueba (n≥5) completan el flujo principal **sin ayuda** (medido en las pruebas con usuarios; ver RNF-24).

**4. Historia de usuario:** *Como pasajero que camina con una mano ocupada, quiero poder usar la app con pocos toques y textos cortos, para no distraerme del entorno.*

**5. Datos que intervienen:** anchos de pantalla, tamaños de controles, nº de toques por flujo, resultados de pruebas de usabilidad, textos de error.

---

### RNF-15 — Claridad del lenguaje
**Prioridad:** P0 · **Categoría:** Usabilidad / Contenido · **Trazabilidad:** Rúbrica (Claridad); RF-08.

**1. Título:** Lenguaje claro y sin jerga.

**2. Descripción:** Los textos de la interfaz deben ser comprensibles para cualquier persona, sin términos técnicos (Pareto, aristas, DBSCAN) y con explicaciones directas de costos y tradeoffs.

**3. Criterios de aceptación:**
- La interfaz está en **español de Perú** (RNF-26), con frases cortas y voz activa.
- **0** términos técnicos internos visibles para el usuario final (revisión de textos).
- Los tradeoffs se redactan con cifras concretas (soles, metros, cuadras).
- Las unidades son consistentes (S/ con 2 decimales; metros; "cuadras" como equivalencia aproximada).
- Los mensajes de infactibilidad indican **la acción posible** ("Puedes: …").
- Una persona ajena al proyecto entiende, sin explicación previa, qué significa "Estimado" y "Confirmado" (prueba con ≥ 3 personas).

**4. Historia de usuario:** *Como persona sin conocimientos técnicos, quiero entender los resultados con palabras simples, para decidir con seguridad.*

**5. Datos que intervienen:** catálogo de textos de la interfaz, glosario de términos permitidos/prohibidos, resultados de pruebas de comprensión.

---

### RNF-16 — Accesibilidad básica
**Prioridad:** P1 · **Categoría:** Accesibilidad · **Trazabilidad:** Track (accesibilidad); alcance negativo.

**1. Título:** Accesibilidad básica de la interfaz.

**2. Descripción:** La interfaz debe cumplir un nivel básico de accesibilidad (contraste, tamaño de texto, no depender solo del color), sin prometer accesibilidad física de los recorridos.

**3. Criterios de aceptación:**
- Contraste de texto **≥ 4,5:1** (WCAG AA) en texto normal.
- La información de certidumbre no depende **solo del color**: se acompaña de icono y/o texto.
- El texto puede ampliarse al **200 %** sin pérdida de contenido.
- Los controles tienen etiquetas accesibles (`aria-label`) y orden de foco lógico.
- La interfaz **no afirma** que un recorrido sea accesible para silla de ruedas, pendientes o escaleras; incluye una nota visible de esta limitación en la documentación y la descripción.
- Las animaciones respetan la preferencia de "reducir movimiento".

**4. Historia de usuario:** *Como persona con visión reducida, quiero textos legibles y señales que no dependan solo del color, para usar la app sin dificultad.*

**5. Datos que intervienen:** paleta de colores y ratios de contraste, etiquetas `aria`, tamaños de texto, nota de limitaciones.

---

### RNF-17 — Compatibilidad
**Prioridad:** P0 · **Categoría:** Compatibilidad · **Trazabilidad:** Regla R3; sec. 9.

**1. Título:** Compatibilidad de navegadores y dispositivos.

**2. Descripción:** La versión pública debe funcionar en el entorno del jurado (computador de la organización, ventana privada) y en teléfonos habituales de Lima.

**3. Criterios de aceptación:**
- Funciona en las **dos últimas versiones estables** de Chrome, Edge y Firefox de escritorio, y en Chrome Android y Safari iOS recientes.
- Funciona en **ventana privada/incógnito**: sin `localStorage` previo ni cookies de sesión y sin errores si el almacenamiento está bloqueado.
- En incógnito o con almacenamiento bloqueado, la **persistencia de sesión puede fallar**; el sistema debe seguir funcionando como **invitado** (RF-33) y el login, si se usa, vale solo para esa visita, sin errores visibles.
- Ningún paso del flujo P0 ni del modo demo exige iniciar sesión, verificar correo ni aceptar permisos del navegador.
- No requiere extensiones, instalación ni permisos para el flujo en modo demo.
- Funciona sin permisos de ubicación (RF-20).
- Verificado en **al menos un computador distinto** al de desarrollo antes de entregar.
- Si hay app móvil nativa, esta es un **extra**: no sustituye a la URL pública.

**4. Historia de usuario:** *Como jurado, quiero abrir el enlace en el computador de la organización y que funcione a la primera, para evaluarlo sin preparativos.*

**5. Datos que intervienen:** matriz de navegadores/dispositivos probados, resultados de prueba en incógnito, estado del almacenamiento local.

---

### RNF-18 — Consumo de datos y batería
**Prioridad:** P1 · **Categoría:** Eficiencia · **Trazabilidad:** RF-16; uso en calle.

**1. Título:** Uso eficiente de datos móviles y batería.

**2. Descripción:** En la calle, los datos móviles son caros y la batería limitada; el sistema debe minimizar ambos.

**3. Criterios de aceptación:**
- Una planificación típica transfiere **≤ 150 KB** (respuesta JSON comprimida, sin teselas del mapa).
- La telemetría usa lotes y envía **≤ 6 KB/min** durante el seguimiento.
- El muestreo de GPS se adapta: baja frecuencia cuando el usuario está parado en un tramo largo de transporte y aumenta cerca de un paradero o conexión.
- Una hora de seguimiento activo consume **≤ 10 %** de batería en un teléfono de gama media (medición aproximada).
- La respuesta de la API usa **compresión** (gzip/br).
- El usuario puede desactivar el envío de trazas sin perder la guía (RF-29).

**4. Historia de usuario:** *Como usuario con un plan de datos limitado, quiero que la app gaste pocos datos y poca batería, para llegar a casa con el teléfono encendido.*

**5. Datos que intervienen:** tamaño de respuestas (KB), bytes/min de telemetría, frecuencia de muestreo, consumo de batería estimado.

---

## F. Calidad de ingeniería y operación

### RNF-19 — Observabilidad
**Prioridad:** P1 · **Categoría:** Operación · **Trazabilidad:** Regla R12; RNF-06.

**1. Título:** Registro, métricas y diagnóstico.

**2. Descripción:** El equipo debe poder saber qué ocurre en producción durante la evaluación: errores, latencias y estado de integraciones.

**3. Criterios de aceptación:**
- **Logs estructurados** (JSON) con identificador de solicitud, ruta, duración y código de estado; sin datos personales ni secretos.
- Endpoint `/health` con estado de la base de datos, del grafo y de cada integración externa.
- Métricas por endpoint: conteo, **p50/p95/p99**, tasa de error.
- Los errores no controlados se registran con contexto suficiente para reproducirlos.
- Un panel o consulta rápida muestra las **últimas 50 solicitudes con error**.
- Se registra el modo `degraded` cuando se usa un fallback.

**4. Historia de usuario:** *Como equipo, queremos ver en tiempo real si algo falla o se vuelve lento, para corregirlo antes de que lo note el jurado.*

**5. Datos que intervienen:** logs estructurados, `request_id`, duraciones, códigos de estado, estado de integraciones, contadores de fallback.

---

### RNF-20 — Mantenibilidad y calidad del código
**Prioridad:** P0 · **Categoría:** Mantenibilidad · **Trazabilidad:** Regla R10; rúbrica (Calidad técnica, el jurado revisa el repo).

**1. Título:** Calidad estructural del repositorio.

**2. Descripción:** El jurado revisa el repositorio; el código debe ser legible, tipado, modular y con historial claro.

**3. Criterios de aceptación:**
- Lenguaje **tipado** (TypeScript estricto o tipos en Python); **0 errores** de compilación/tipado en el *pipeline*.
- Separación en capas: HTTP / servicios / dominio (`routing-engine`) / acceso a datos; **el dominio no importa código de red ni de base de datos**.
- Linter y formateador configurados; **0 errores de lint** en la rama principal.
- Commits **pequeños y descriptivos** (mensaje con verbo y alcance); sin commits de "arreglos varios" masivos.
- Sin código muerto, sin credenciales, sin archivos generados innecesarios en el repo.
- README con: problema, usuario, cómo ejecutar, diagrama de arquitectura, decisiones y tradeoffs, **qué quedó fuera**, fuentes de datos, limitaciones, privacidad.
- Documentos `ARCHITECTURE.md`, `DECISIONS.md`, `DATA_SOURCES.md` y `PRIVACY.md` presentes y coherentes con el código.
- Configuración (umbrales, tarifas, cobertura) externalizada, no incrustada.

**4. Historia de usuario:** *Como jurado técnico, quiero abrir el repositorio y entender su estructura y decisiones en pocos minutos, para valorar la calidad de la ingeniería.*

**5. Datos que intervienen:** estructura del repositorio, configuración del linter/tipado, historial de commits, documentos de arquitectura y decisiones.

---

### RNF-21 — Pruebas automatizadas
**Prioridad:** P0 · **Categoría:** Calidad · **Trazabilidad:** Nota del agente en sec. 5.5; RNF-08.

**1. Título:** Cobertura y tipos de prueba.

**2. Descripción:** El motor de ruteo y los cálculos críticos deben estar cubiertos por pruebas que se ejecutan automáticamente y evitan fallos en vivo.

**3. Criterios de aceptación:**
- Pruebas unitarias del `routing-engine` con **cobertura de líneas ≥ 80 %** en ese módulo.
- Casos de oro obligatorios: (1) solución única; (2) caso infactible con relajación esperada; (3) caso donde el taxi **no** debe aparecer; (4) recálculo con saldo reducido; (5) caminata continua que supera el límite; (6) presupuesto menor que cualquier tarifa.
- Pruebas de contrato de la API (formas de respuesta, códigos de error).
- Una **prueba de humo** end-to-end (planificar → seleccionar → replanificar → completar) contra el entorno desplegado.
- Prueba que verifica que **ningún importe/paradero se devuelva sin etiqueta de certidumbre** (RNF-09).
- Prueba con **todos los servicios externos opcionales desactivados** (RNF-07).
- Las pruebas corren en CI (o con un solo comando) y deben pasar antes de cada despliegue.
- Pruebas de detección de abordaje: caso positivo (simulado) y caso negativo (semáforo).

**4. Historia de usuario:** *Como equipo, queremos pruebas automáticas que nos avisen si rompimos algo, para no descubrir el fallo delante del jurado.*

**5. Datos que intervienen:** casos de prueba con entradas y salidas esperadas, viajes de oro, informe de cobertura, resultados de CI.

---

### RNF-22 — Despliegue y reproducibilidad
**Prioridad:** P0 · **Categoría:** Operación · **Trazabilidad:** Regla R3, R11; RF-30.

**1. Título:** Despliegue público reproducible.

**2. Descripción:** El sistema debe poder desplegarse de forma repetible en una URL pública y poder levantarse localmente con pocos pasos, con migraciones versionadas.

**3. Criterios de aceptación:**
- Existe una URL pública HTTPS con certificado válido, **sin pasos manuales** de login ni autorización previos.
- Primer despliegue funcional **antes de la hora 9** del plan; despliegues posteriores en **≤ 10 min**.
- Levantar el proyecto localmente requiere **≤ 5 comandos** documentados (p. ej. contenedores + migraciones + carga de datos + arranque).
- Las migraciones de base de datos están versionadas y son idempotentes.
- El estado inicial (datos del eje) se recrea con un comando (RF-24).
- Las variables de entorno requeridas están documentadas y el arranque falla con mensaje claro si falta alguna.
- Existe un procedimiento de **rollback** (RNF-06).

**4. Historia de usuario:** *Como equipo, queremos poder desplegar y reconstruir el sistema de forma rápida y repetible, para recuperarnos de cualquier problema sin perder horas.*

**5. Datos que intervienen:** configuración de despliegue, migraciones, variables de entorno requeridas, versión desplegada, comandos de arranque.

---

### RNF-23 — Escalabilidad del motor de ruteo
**Prioridad:** P1 · **Categoría:** Escalabilidad · **Trazabilidad:** Sec. 5.5; pregunta del jurado "¿escala a toda Lima?".

**1. Título:** Escalabilidad del motor frente al tamaño del grafo.

**2. Descripción:** Aunque el alcance sea un eje, el motor debe crecer razonablemente sin rediseño, y los límites deben conocerse y documentarse.

**3. Criterios de aceptación:**
- Con un grafo de **hasta 5.000 paraderos y 100 rutas**, `/plan` cumple RNF-01.
- El uso de memoria del grafo se mide y documenta (p. ej. **≤ 300 MB** para 5.000 paraderos).
- El número de etiquetas por estado está limitado (`K`) y configurable; el rendimiento y la calidad del resultado frente a `K` están medidos y documentados.
- El motor puede cargarse por **zonas** (particionado por cobertura) sin cambiar el código del dominio.
- El README documenta los límites conocidos y qué haría falta para cubrir más zonas (datos, memoria, particionado).
- La complejidad temporal de la búsqueda crece de forma documentada con nodos y aristas.

**4. Historia de usuario:** *Como equipo, queremos saber hasta dónde crece el motor y qué haría falta para cubrir más zonas, para responder con honestidad a la pregunta de escalabilidad.*

**5. Datos que intervienen:** nº de paraderos, rutas, aristas, memoria usada, parámetro `K`, tiempos medidos por tamaño.

---

### RNF-24 — Medición y pruebas de rendimiento
**Prioridad:** P0 · **Categoría:** Calidad / Verificación · **Trazabilidad:** Todos los RNF numéricos.

**1. Título:** Verificación medible de los requerimientos no funcionales.

**2. Descripción:** Las metas numéricas de este documento deben medirse, no suponerse. El sistema incluye guiones de prueba de carga y medición, y se registran resultados reales.

**3. Criterios de aceptación:**
- Existe un guion de **prueba de carga** reproducible (p. ej. con k6, Artillery u otra herramienta) para `/plan`, `/replan` y `/telemetry/pings`.
- Se ejecuta **al menos una vez en el entorno desplegado** antes del congelamiento y se guardan los resultados (p50/p95/p99, errores, memoria).
- Se mide la carga inicial (FCP/TTI) con una herramienta estándar (Lighthouse) en emulación de móvil y 4G.
- Se hace una **prueba de usabilidad con ≥ 5 personas** (RNF-14, RNF-15) y se registra el resultado.
- Cada RNF cuyo resultado real no cumpla la meta se documenta con la cifra real y el plan de mejora; **no se ajustan los resultados** para cumplir.
- Los resultados se incluyen en `docs/` (p. ej. `docs/PERFORMANCE.md`).

**4. Historia de usuario:** *Como equipo, queremos medir de verdad el rendimiento y la usabilidad, para afirmar ante el jurado solo lo que podemos demostrar.*

**5. Datos que intervienen:** guiones de prueba, resultados (latencias, errores, FCP/TTI, memoria), resultados de pruebas con usuarios, `docs/PERFORMANCE.md`.

---

### RNF-25 — Idempotencia, consistencia y respaldo
**Prioridad:** P1 · **Categoría:** Fiabilidad de datos · **Trazabilidad:** RF-13, RF-22.

**1. Título:** Idempotencia de operaciones y respaldo de datos.

**2. Descripción:** Las acciones repetidas por doble toque, reintentos o redes inestables no deben duplicar efectos, y los datos de tracción deben protegerse con respaldo.

**3. Criterios de aceptación:**
- Las operaciones que modifican estado (`select`, `replan`, `complete`, `feedback`) aceptan un `request_id`; **repetir la misma solicitud devuelve el mismo resultado** y no duplica registros ni descuentos de saldo.
- Una replanificación y una finalización concurrentes del mismo viaje no dejan el viaje en estado inconsistente (transiciones de estado válidas: PLANNING → ACTIVE → REPLANNED* → COMPLETED/ABANDONED).
- Los cambios de saldo se aplican de forma **transaccional**.
- **Respaldo** automático o manual de la base de datos **cada ≤ 2 h** y **uno inmediato** antes del congelamiento; restauración probada una vez.
- Los eventos de tracción no se pierden ante reinicios (persistidos en la base antes de confirmar).
- La cola local de telemetría del cliente descarta lo más antiguo al llenarse sin bloquear la app.

**4. Historia de usuario:** *Como usuario con mala señal, quiero que si mi toque se repite no se cobre ni se descuente dos veces, para que mi saldo sea siempre correcto.*

**5. Datos que intervienen:** `request_id`, estados de `TripSession`, transacciones de base de datos, copias de seguridad, cola de telemetría.

---

### RNF-26 — Localización (español de Perú)
**Prioridad:** P0 · **Categoría:** Localización · **Trazabilidad:** RNF-15.

**1. Título:** Idioma, formatos y zona horaria.

**2. Descripción:** La interfaz y los datos deben seguir las convenciones locales de Lima/Perú.

**3. Criterios de aceptación:**
- Idioma de la interfaz: **español (es-PE)**.
- Moneda: **sol peruano** con símbolo **S/** y dos decimales (separador decimal coherente en toda la app).
- Zona horaria **America/Lima (UTC−5)** para horas pico, alertas y registros mostrados.
- Distancias en **metros/kilómetros** (nunca millas); "cuadras" solo como equivalencia aproximada.
- Fechas en formato **dd/mm/aaaa** y hora de 24 h en toda la interfaz.
- La lógica de "hora punta" (factor del taxi, espera estimada) usa la hora local de Lima, no la del servidor.

**4. Historia de usuario:** *Como limeño, quiero ver soles, metros y horas en el formato que uso a diario, para no tener que convertir nada.*

**5. Datos que intervienen:** configuración regional (`es-PE`, `America/Lima`), formatos de moneda, fecha y distancia, definición de horas pico.

---

### RNF-27 — Documentación
**Prioridad:** P0 · **Categoría:** Documentación · **Trazabilidad:** Rúbrica (Claridad y Calidad); RF-30.

**1. Título:** Documentación completa, veraz y coherente.

**2. Descripción:** La documentación debe permitir entender el problema, el usuario, el funcionamiento, las limitaciones y la arquitectura, y debe coincidir con lo realmente construido.

**3. Criterios de aceptación:**
- La descripción de entrega (Markdown) cubre: problema, para quién, cómo funciona, limitaciones y qué quedó fuera.
- El README incluye un **diagrama de arquitectura** y la lista de integraciones con el motivo de cada una.
- Se distinguen explícitamente **lo que ya funciona** de lo que es **idea o alcance futuro**.
- `DATA_SOURCES.md` lista cada fuente con URL, fecha de descarga y qué se curó a mano.
- `PRIVACY.md` describe qué se recoge, cómo se anonimiza y cómo se borra.
- `DECISIONS.md` registra decisiones y tradeoffs (incluida la elección de rúbrica aclarada con la organización).
- No existen afirmaciones en la documentación que el sistema no pueda demostrar en vivo.
- La documentación se revisa contra el sistema desplegado antes de la entrega.

**4. Historia de usuario:** *Como jurado, quiero leer una descripción honesta que separe lo funcionando de lo planeado, para valorar con justicia lo que el equipo logró.*

**5. Datos que intervienen:** README, descripción de entrega, `ARCHITECTURE.md`, `DECISIONS.md`, `DATA_SOURCES.md`, `PRIVACY.md`, `PERFORMANCE.md`.

---

## G. Autenticación y autorización

### RNF-28 — Seguridad de autenticación y sesiones
**Prioridad:** P0 · **Categoría:** Seguridad · **Trazabilidad:** RF-31, RF-32, RF-35.

**1. Título:** Autenticación segura y gestión de sesiones.

**2. Descripción:** La identidad de los usuarios se gestiona con un proveedor de identidad confiable; el sistema propio nunca maneja contraseñas y verifica en el servidor cada token que protege datos personales.

**3. Criterios de aceptación:**
- **0** contraseñas almacenadas, registradas en logs o transmitidas a servicios propios; solo viajan al proveedor de identidad.
- Cada solicitud protegida valida en el servidor: **firma, expiración, emisor y audiencia** del token; un token inválido o vencido devuelve `401` sin detalles internos.
- La verificación del token añade **≤ 50 ms en p95** a la latencia de la solicitud (usando las claves públicas en caché), sin llamar al proveedor en cada petición.
- Los tokens **no se envían en URLs** ni se escriben en logs, métricas ni mensajes de error.
- Inicio de sesión y registro: **p95 ≤ 3 s** en red 4G (medido en cliente).
- Los mensajes de error de autenticación **no permiten enumerar cuentas** (mismo mensaje y tiempo de respuesta similar para "no existe" y "clave incorrecta").
- Limitación de intentos: tras **5 fallos consecutivos** en 15 min se aplica bloqueo/retraso progresivo.
- Las credenciales administrativas del proveedor (cuentas de servicio, claves privadas) existen **solo en el servidor** y nunca en el cliente ni en el repositorio (RNF-11). Las claves de configuración públicas del cliente no se consideran secretas, pero **su seguridad depende de las reglas de acceso** de RNF-29.
- Si la cuenta se elimina o se revoca, los tokens vigentes dejan de aceptarse en **≤ 1 h** (o inmediatamente en operaciones sensibles con re-autenticación).
- La autenticación multifactor queda **fuera de alcance** y se documenta como tal.

**4. Historia de usuario:** *Como usuaria, quiero que mi cuenta esté protegida y que nadie pueda adivinar si mi correo está registrado, para confiar mis datos de viaje a la app.*

**5. Datos que intervienen:** token de identidad (firma, `exp`, `iss`, `aud`, `sub`), claves públicas del proveedor en caché, contador de intentos, `user_id`, política de contraseñas, cuentas de servicio (solo en servidor).

---

### RNF-29 — Autorización y aislamiento de datos entre usuarios
**Prioridad:** P0 · **Categoría:** Seguridad · **Trazabilidad:** RF-34, RF-35, RF-26.

**1. Título:** Cada usuario accede solo a sus propios datos.

**2. Descripción:** Con la introducción de cuentas, el sistema debe garantizar que nadie lea o modifique el historial, preferencias o viajes de otra persona, tanto a través de la API propia como de cualquier acceso directo a un almacén de datos gestionado.

**3. Criterios de aceptación:**
- Toda consulta o modificación de datos personales filtra por el `user_id` del **token verificado**, nunca por un identificador enviado por el cliente.
- **Dado** el usuario A, **cuando** solicita un recurso de B (viaje, preferencia, perfil), **entonces** recibe `403/404` indistinguible de "no existe" (sin filtrar existencia).
- Si el cliente accede **directamente** a un almacén de datos gestionado, existen **reglas de seguridad** que restringen lectura y escritura al propietario; **por defecto todo está denegado** y solo se abre lo necesario.
- Las reglas de acceso están **versionadas en el repositorio** y probadas con casos negativos automatizados (A no lee B; invitado no lee cuentas; cliente no escribe `is_external_user`, `confidence_score`, estadísticas ni métricas).
- Los endpoints públicos (mapa de paraderos, panel de tracción) devuelven **solo datos agregados**; ninguno expone `user_id`, correo ni trazas.
- Los endpoints administrativos y del simulador exigen **rol/credencial separada**, no alcanzable con una cuenta de usuario normal.
- Los campos sensibles del sistema (banderas de tracción, confianza de paraderos, tarifas) **no son modificables** desde el cliente.
- Mínimo privilegio: cada componente usa credenciales con solo los permisos que necesita.

**4. Historia de usuario:** *Como usuario, quiero tener la certeza de que ninguna otra persona puede ver mis viajes, para sentirme segura al guardar mi historial.*

**5. Datos que intervienen:** `user_id` del token, reglas de seguridad del almacén, roles (usuario, invitado, administrador), pruebas de acceso cruzado, listado de campos protegidos.

---

### RNF-30 — Resistencia a manipulación y acotación del daño
**Prioridad:** P0 · **Categoría:** Seguridad / Integridad · **Trazabilidad:** RF-36; RNF-09, RNF-12, RNF-19.

**1. Título:** Resistencia medible a la manipulación de datos colaborativos.

**2. Descripción:** Las defensas de RF-36 deben ser **medibles y verificables**, con metas de tasa de falsos positivos/negativos, tiempos de detección y reversión, y garantía de que un ataque exitoso no degrada el servicio ni la veracidad del resto del mapa.

**3. Criterios de aceptación:**
- **Tasa de aceptación de ataques simulados = 0 %** en las pruebas "carrito", "carrito + auto" y "bots dispersos" de RF-36, en cada despliegue (prueba automatizada en CI).
- **Control positivo:** el detector promueve **≥ 90 %** de los paraderos legítimos sintéticos (≥ 3 grupos independientes escalonados con ruta real) dentro de la persistencia configurada.
- **Falsos positivos** del detector sobre un conjunto de trazas peatonales "ruidosas" (semáforos, filas, cruces): **≤ 2 %** de las trazas generan un evento de abordaje.
- **Tiempo de detección** de un pico anómalo por celda: **≤ 5 min** desde que cruza el umbral; cuarentena automática en ≤ 1 ciclo del proceso periódico.
- **Tiempo de reversión** de un lote de eventos invalidado: **≤ 1 ciclo** del proceso (≤ 5 min) hasta que el paradero se elimina o recalcula.
- **Acotación del daño:** ante un ataque, **0** datos oficiales cambian; el tiempo de respuesta de `/plan` no empeora más de **25 %** (se mide con carga de ataque simulada, ver RNF-05).
- Los parámetros anti-abuso (umbrales, topes, ventanas, pesos) son **configurables sin recompilar** y están documentados con su justificación.
- Cada decisión de descarte o cuarentena se **registra** con causa (`REASON_CODE`) sin datos personales, para auditar por qué un evento no contó.
- La honestidad hacia el usuario se mantiene: un paradero inferido siempre se muestra como "inferido" con su confianza; nunca se presenta como confirmado.
- `docs/THREAT_MODEL.md` describe: activos, atacantes, vectores, defensas, **riesgos residuales** (p. ej. un atacante con muchos dispositivos reales y paciencia puede aún aportar evidencia plausible) y qué se haría para producción.

**4. Historia de usuario:** *Como equipo, queremos demostrar con pruebas que un ataque barato no engaña al sistema y que, si algo se cuela, podemos verlo y deshacerlo, para responder con evidencia a la pregunta "¿y si alguien lo hackea?".*

**5. Datos que intervienen:** resultados de pruebas de ataque y control positivo, tasas de falsos positivos/negativos, tiempos de detección y reversión, umbrales configurables, `REASON_CODE` de descartes, línea base por celda, métricas de latencia bajo ataque, `docs/THREAT_MODEL.md`.

---

# PARTE III — SECCIONES DE APOYO

## 1. Matriz de prioridades

| Prioridad | Requerimientos funcionales | Requerimientos no funcionales |
|---|---|---|
| **P0** | RF-01, 02, 03, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, 15, 20, 22, 24, 25, 29, 30, 31, 32, 33, 34 | RNF-01, 02, 03, 04, 05, 06, 07, 08, 09, 11, 12, 13, 14, 15, 17, 20, 21, 22, 24, 26, 27, 28, 29, 30 |
| **P1** | RF-04, 16, 17, 18, 19, 21, 23, 35, 36 (los puntos [P0] de RF-36 son obligatorios aunque Motor 2 se recorte) | RNF-10, 16, 18, 19, 23, 25 |
| **P2** | RF-26, 27, 28 | — |

## 2. Trazabilidad con la rúbrica

| Criterio de evaluación | Requerimientos que lo sostienen |
|---|---|
| Complejidad / esfuerzo técnico | RF-05, 06, 07, 10, 13, 17, 18 · RNF-01, 07, 23 |
| Funciona en vivo | RF-20, 22, 24, 30 · RNF-03, 06, 07, 17, 22 |
| Calidad técnica (repo) | RNF-11, 20, 21, 22, 27 |
| Problema e impacto | RF-03, 08, 09, 11, 12, 13 · RNF-14 |
| Claridad / tradeoffs | RF-08, 09, 10 · RNF-15, 27 |
| Tracción | RF-14, 22, 23, 27, 31, 32, 33, 34 · RNF-13, 25, 29 |
| Pitch / demo | RF-19, 20 · RNF-01, 03, 06 |

## 3. Matriz de dependencias (resumen)

| Requerimiento | Depende de |
|---|---|
| RF-05 | RF-24, RF-25, RF-03 |
| RF-06 | RF-05, RF-25 |
| RF-07 | RF-05, RF-06 |
| RF-08 / RF-09 | RF-07 |
| RF-10 | RF-05, RF-06 |
| RF-13 | RF-05, RF-12, RF-11 |
| RF-17 | RF-16 |
| RF-18 | RF-17, RF-15 |
| RF-19 | RF-17, RF-18 |
| RF-23 | RF-22, RF-14 |
| RF-26 / RF-27 | RF-05, RF-13 (opcionales) |
| RF-32 | RF-31, RNF-28 |
| RF-33 | RF-22 (identidad anónima) |
| RF-34 | RF-11, RF-14, RF-32 o RF-33, RNF-29 |
| RF-35 | RF-32, RF-29 |

## 4. Entidades de datos (resumen)

| Entidad | Campos principales |
|---|---|
| `TripSession` | id, user_id (nulo si invitado), anon_session_id, origin_geom, destination_geom, initial_budget_soles, spent_budget_soles, remaining_budget_soles, max_total_walk_m, max_continuous_walk_m, allow_taxi_bridge, priority_mode, status, replan_count, selected_alternative, is_external_user, created_at |
| `Alternative` / `Leg` | id, label, total_cost{amount, certainty}, total_walk_m, longest_continuous_walk_m, est_duration_min, transfers, tradeoff_text, legs[{type, from, to, polyline, distance_m, duration_min, route_code, cost, certainty, boarding_stop}] |
| `TransitStop` | id, name, geom, stop_type, confidence_score, detected_boardings_count, distinct_sessions_count, routes_serving, source, last_verified_at |
| `TransitRoute` | id, code, name, mode, geom, base_fare_soles, fare_certainty, fare_source, fare_checked_at, est_headway_min, avg_speed_kmh |
| `RouteStop` | route_id, stop_id, seq |
| `GpsPing` | anon_session_id, geom, speed_mps, heading_deg, accuracy_m, is_simulated, recorded_at |
| `Event` | id, anon_session_id, type, payload, is_external_user, is_simulated, created_at |
| `TripFeedback` | trip_id, completed, fare_mismatch, stop_mismatch, comment, created_at |
| `Alert` | id, route_code, stop_id, title, summary, source_url, published_at, verified, fetched_at, expires_at |
| `UserPreference` | anon_id, key, value, source, updated_at |
| `Consent` | user_id o anon_session_id, guidance, telemetry, granted_at, revoked_at |
| `User` | user_id, email, display_name, provider, email_verified, is_team_member, privacy_policy_version, created_at, last_login_at |
| `AnonLink` | anon_session_id, user_id, linked_at |
| `DeletionRequest` | user_id, requested_at, completed_at |

## 5. Supuestos y puntos abiertos (afectan los requerimientos)

1. **Rúbrica vigente sin aclarar** (guía vs. deck). Afecta el peso de RF-14, RF-22, RF-23 y de la tracción. *Acción:* preguntar a la organización.
2. **Calidad de los datos de rutas** (OSM/ATU) sin verificar → condiciona RF-05, RF-24 y las promesas de cobertura.
3. **Frecuencias y horarios** de transporte tradicional no disponibles → las esperas serán siempre estimadas (RF-09).
4. **Fórmula de taxi** sin calibrar → siempre estimada (RF-06).
5. **Taxi compartido** (Problema 3) **no incluido** como requerimiento funcional por riesgo y plazo; queda como alcance futuro o simulado.
6. **Pago/reserva de taxi dentro de la app** fuera de alcance; el taxi se contrata en un servicio externo.
7. **Accesibilidad física** de recorridos (silla de ruedas, escaleras) fuera de alcance (RNF-16).
8. **Qatom** no genera requerimiento propio por encaje dudoso (ver documento de contexto, sec. 7.9).
9. **App nativa vs. web pública:** los requerimientos asumen una versión **web mobile-first pública** como entregable oficial (RNF-17); la app nativa es un extra.
10. **Las cifras de los RNF son metas**, no mediciones (RNF-24).
11. **El login nunca es obligatorio** para el flujo principal ni para la demo (RF-33); la organización evalúa en ventana privada sin sesión.
12. **Firebase es decisión del equipo** (no impuesta aquí). Falta definir **qué productos se usarán** (¿solo identidad, también base de datos, alojamiento, funciones?). De eso dependen: dónde vive el historial (RF-34), si hay servidor propio que verifique tokens (RNF-28), las reglas de acceso (RNF-29) y, sobre todo, **dónde se ejecutan el motor de ruteo, PostGIS y el agrupamiento DBSCAN** (RF-05, RF-18), que requieren cómputo y consultas geoespaciales que un almacén de documentos no resuelve por sí solo.
13. **Cuotas y límites del plan gratuito** del proveedor (autenticación, lecturas/escrituras, mensajes) pueden afectar la capacidad con ~100 usuarios simultáneos (RNF-05, RNF-06); deben revisarse y probarse antes del congelamiento.
14. **Historial de invitados:** retención limitada y vinculación posterior a cuenta (RF-33); la política exacta (30 días vs. solo en el dispositivo) está por decidir.

---
15. **Stack decidido:** cliente **Flutter**; **Firebase** para base de datos, notificaciones e identidad. La arquitectura resultante está en [cyberon-arquitectura.md](cyberon-arquitectura.md). En el **MVP no hay servidor propio** (el motor corre en la app); el backend ligero llega con los Incrementos A/B.
16. **Notificaciones:** en el MVP son **locales** (solo Android); el **push FCM** se deja para el Incremento B. En web/incógnito el push no es fiable.

## 6. Corte de MVP (resumen; detalle y cronograma en [cyberon-arquitectura.md](cyberon-arquitectura.md) sec. 2 y 17)

> **MVP = MVP-0 (Núcleo) + MVP-1 (Evidencia).** Todo lo demás son **incrementos recortables**.

| Hito | Requerimientos funcionales | Requerimientos no funcionales |
|---|---|---|
| **MVP-0 · Núcleo** (deploy público en H+10) | RF-01, 02, 03, 05, 06, 07, 08, 09, 10, 11, 15, 24, 25, 31, 32, 33, 34 | RNF-01, 02, 03, 04, 07, 08, 09, 12, 14, 15, 17, 20, 21, 22, 26, 28, 29 |
| **MVP-1 · Evidencia** (completo en H+13; **entrega v1**) | RF-12, 13, 14, 20, 22, 23, 29, 30, 35 (solo cerrar sesión) | RNF-05, 06, 11, 13, 19, 24, 27 |
| **Incremento A · Motor 2** (requiere backend ligero) | RF-16, 17, 18, 19, 36 | RNF-30, 13 (telemetría), 25 |
| **Incremento B · Integraciones** | RF-04, 21 (alertas + push FCM), 26 | RNF-10, 18 |
| **Incremento C · Extras** | RF-27, 28, 35 (eliminación de cuenta con cascada) | RNF-16, 23 |

**Ajustes de requerimientos por el MVP (ya aplicados):**
- **RF-05/06:** en el MVP, caminata y taxi se **estiman localmente** (`haversine × 1,3`; fórmula de taxi), siempre `ESTIMATED`; el refinamiento con un servicio de rutas es un incremento.
- **RF-01:** la búsqueda de lugares es **local** (lista de paraderos/hitos) más toque en el mapa; no hay geocodificación remota con autocompletado.
- **RF-22/23:** la tracción se registra con **contadores del cliente protegidos por reglas**; son **falsificables** y se declara; el backend los valida desde el Incremento A.
- **RF-33:** el invitado usa identidad anónima; convertirse en cuenta **conserva el mismo identificador**; entrar a una cuenta existente exige **migrar** los viajes.

---
*Fin del documento. Para contexto, historia de decisiones, sponsors y notas para el agente constructor, ver [cyberon-contexto-completo.md](cyberon-contexto-completo.md).*
