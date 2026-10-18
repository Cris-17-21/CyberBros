# Plan de implementación — Cyberon completo

## Objetivo

Convertir el prototipo Flutter actual en Cyberon funcional conforme a `cyberon-requerimientos.md`, `cyberon-arquitectura.md`, `cyberon-diseno.md` y las decisiones vigentes de `docs/DECISIONS.md`: cobertura objetivo de todo Lima (sin afirmarla hasta medir datos) e integración Zavu en el MVP mediante un backend que proteja secretos. El flujo principal debe ser utilizable sin cuenta ni GPS y desplegable en web; Android también debe funcionar.

## Estado inicial verificado

- La app contiene Login, planificador, condiciones, opciones y detalle; varias tarifas, tramos y tiempos son valores fijos ilustrativos.
- Usa `flutter_map` y OpenStreetMap; aún no hay buscador geográfico local, ubicación, motor, persistencia, autenticación, seguimiento, historial ni tracción.
- `data/` no contiene dataset de transporte. La auditoría Overpass del bbox provisional falló antes de obtener conteos (timeouts/500, 2026-10-17).
- `pubspec.yaml` no integra Firebase, Riverpod ni go_router; no se encontró configuración de Firebase ni credenciales Zavu.
- El repo estaba en `main`; el trabajo continúa en `codex/complete-cyberon`.

## Decisiones vigentes y límites

- Toda Lima es el objetivo de cobertura; se usará un límite administrativo reproducible y se mostrará la cobertura real de los datos cargados. Nunca se inventarán rutas, tarifas, conteos ni certeza.
- Zavu es requisito MVP según `docs/DECISIONS.md`; las claves y verificación de webhooks van en backend. La app conserva todos sus flujos si el backend/Zavu no está configurado o falla.
- Mantener el motor de planificación como dominio Dart puro sin UI, red ni Firebase. La app, Firebase y Zavu serán adaptadores.
- OpenStreetMap es la base de mapas. La disponibilidad de teselas/geocodificación pública no se trata como SLA; atribución y caché/respaldo son obligatorios.
- El mapa debe abrirse en una vista independiente para no comprimir las pantallas de planificación y comparación. Leaflet en Web; capa Flutter nativa en Android.
- Dinero entero en céntimos; restricciones duras; taxis siempre estimados y no contratados por Cyberon; todo dato simulado debe decir `SIMULADO`.
- Autenticación opcional: invitado primero. No se bloquea la planificación por falta de Firebase, GPS, red o registro.
- Las fuentes de datos actuales no prueban que exista cobertura completa; el plan conserva ese requisito y prioriza obtener/validar datos abiertos antes de dar rutas reales.

## Fases y tareas

### Fase 0 — Base verificable y datos

- [ ] T0.1: Corregir documentación operativa, establecer la cobertura administrativa de Lima y registrar fuentes, licencias, fechas, calidad y límites. Reintentar auditoría Overpass segmentada o extraer una fuente reproducible; conservar respuestas crudas y no deducir rutas de simples conteos.
- [ ] T0.2: Construir pipeline de ingesta/validación que genere dataset versionado, informe de calidad y configuración de cobertura; descartar relaciones incompletas y degradar tarifas sin fuente a `ESTIMATED`.
- [ ] T0.3: Reorganizar Flutter en capas y tema/tokens; dejar navegación, estados vacíos/error/offline, diseño responsive (móvil/tablet/escritorio), accesibilidad básica y estructura de pruebas.

**Aceptación:** hay un dataset reproducible con origen/licencia/fecha/calidad documentados y polígono de Lima; la app nunca presenta geometría incompleta como una ruta válida; la shell visual se adapta a 360×800, 1366×768 y 1920×1080.

### Fase 1 — Núcleo de planificación (RF-01–11, 15, 24–25)

- [ ] T1.1: Modelos puros inmutables, dinero en céntimos, certidumbre, geometría/cobertura, restricciones, legs y alternativas.
- [ ] T1.2: Búsqueda local/geográfica con debounce, sugerencias, selección en mapa, origen GPS opcional con consentimiento, intercambio, validación y alternativa a pie para puntos cercanos.
- [ ] T1.3: Grafo peatonal/transporte a partir del dataset medido; motor con costes de abordaje, límites duros, caminatas inicial/final, tiempos con espera etiquetada, presupuesto y taxi puente con fórmula configurable y siempre estimada.
- [ ] T1.4: Pareto (barata, menos caminata, equilibrada/prioridad), deduplicación, tradeoffs deterministas, explicación de datos y diagnóstico de infactibilidad con hasta dos relajaciones consentidas.
- [ ] T1.5: Conectar S1/S2/S3/S4 al `PlannerGateway` local; vista de mapa independiente con tramos, fuente/fecha, marcadores tipados y alternativa textual completa.

**Aceptación:** viajes de oro y pruebas de restricciones demuestran que ninguna alternativa viola presupuesto/caminata; datos incompletos producen estado honesto y accionable, nunca cifras inventadas.

### Fase 2 — Viaje completo (RF-11–15, 20, 29)

- [ ] T2.1: Revisión antes de salir, selección y estado activo; acciones secuenciales por tramo.
- [ ] T2.2: Seguimiento manual utilizable sin permiso GPS; GPS opcional y revocable; siguiente acción y progreso del tramo.
- [ ] T2.3: Replanificar desde posición confirmada y saldo restante, descontar solo gasto confirmado, conservar condiciones y registrar cambios.
- [ ] T2.4: Finalizar viaje y capturar feedback sobre tarifa/paraderos; reportes sin ubicación exacta ni datos personales.
- [ ] T2.5: Viaje demo determinista de ≤2 min, aislado de tracción, con insignias `DEMO`/`SIMULADO` visibles y salida sencilla.

### Fase 3 — Identidad, historial y tracción (RF-22, 23, 29, 31–35)

- [ ] T3.1: Firebase opcionalmente configurable por FlutterFire; auth anónima, registro, login, recuperación, sesión y enlace anónimo→cuenta; fallback invitado local cuando falte configuración.
- [ ] T3.2: Repositorios de viajes/perfil con persistencia local invitada y Firestore autenticado, aislamiento por UID, copia inmutable de alternativas, retención, borrar/repetir/reanudar viaje.
- [ ] T3.3: Consentimiento de guía/telemetría y políticas breves; manejo de permisos, anonimización y borrado disponible según capacidad real.
- [ ] T3.4: Eventos idempotentes de planificación/selección/replan/completado/feedback; excluir DEMO y equipo; panel de tracción agregado y con limitaciones declaradas.
- [ ] T3.5: Reglas Firestore denegadas por defecto, índices y pruebas negativas; nunca confiar al cliente secreto, identidad ajena ni contadores arbitrarios.

### Fase 4 — Zavu y capacidades integradas (decisión D-002; RF-27)

- [ ] T4.1: Backend de confianza mínimo con configuración por variables de entorno, adaptador Zavu, rate-limit, firma de webhook, deduplicación, normalización de identidad y permisos explícitos de mensajería.
- [ ] T4.2: Flujo WhatsApp/SMS opt-in para crear/consultar plan y pedir replanificación, enlazado a un usuario/sesión mediante código de un solo uso; misma API/dominio que la app.
- [ ] T4.3: Pruebas del webhook (firma válida/inválida, repetición, payload hostil, proveedor caído) y fallback humano/app. No almacenar conversaciones más tiempo del necesario.
- [ ] T4.4: Documentar configuración Zavu con `ZAVU_API_KEY` solo servidor y pasos para activar proveedor; funcionamiento local completo aunque no haya credenciales.

### Fase 5 — Incrementos complementarios (RF-04, 16–21, 26, 28, 36)

- [ ] T5.1: Parser opcional de lenguaje natural en backend, esquema estricto, confirmación de campos y fallback manual.
- [ ] T5.2: Alertas con fuente/fecha/expiración y verificación visible; no alteran rutas sin consentimiento.
- [ ] T5.3: Consentimiento y simulador de telemetría etiquetado. Detección de paraderos solo servidor, protecciones anti-envenenamiento (sesiones efectivas, cuarentena, plausibilidad); datos inferidos públicos solo agregados tras los umbrales.
- [ ] T5.4: Refresco/ingesta automatizados con control de licencias y frescura; AtomicMemory solo si se muestra valor, consentimiento, acceso y borrado; Zavu ya pertenece a fase 4.

### Fase 6 — Diseño, calidad y entrega

- [ ] T6.1: Rediseñar todas las pantallas según `cyberon-diseno.md`, no según mockups genéricos; tokens tipográficos y de color, semántica de certeza, accesibilidad, vacío/error/offline y modo oscuro.
- [ ] T6.2: Pruebas unitarias de motor/dataset/parser; widgets de flujos y estados; reglas Firebase; contrato/webhooks backend; viajes de oro y rendimiento.
- [ ] T6.3: CI, documentación de instalación/datos/privacidad, `.env.example`, modelo de amenazas y checklist de publicación; escanear secretos.
- [ ] T6.4: Build Android y Web, desplegar URL pública, probar demo en incógnito y responsive en escritorio/teléfono; preparar README de entrega, presentación, bitácora y submit una vez estén disponibles las URLs/datos faltantes.

## Dependencias / orden

Datos y dominio preceden al motor. El motor precede a UI conectada. La ruta S1→S5 precede a seguimiento. Identidad precede a historial multi-dispositivo y tracción protegida. Backend y contrato preceden a Zavu/parser/alertas/inferencia. Demo/web y pruebas de incógnito preceden a declarar terminado.

## Riesgos críticos

| Riesgo | Respuesta |
|---|---|
| OSM/Overpass no entrega datos útiles o completos de tránsito en Lima | Segmentar consultas, buscar datasets públicos alternativos, medir geometría/secuencia; no sintetizar rutas. Si no hay cobertura suficiente, mostrar cobertura parcial y no marcar el requisito cumplido. |
| Firebase y Zavu requieren proyectos, credenciales y habilitación del equipo | Código por configuración y fallback; nunca crear ni publicar credenciales inventadas. |
| Teselas/geocodificación públicas limitadas | Debounce/caché/atribución, alternativas manuales y configuración de proveedor. |
| El alcance completo excede una sola tanda | Mantener este plan y continuar por el próximo corte verificable hasta cubrir el objetivo; no redefinir `completo`. |

## Próximo corte

Resolver T0.1: medir datos reales de transporte de Lima, incluyendo rutas con geometría y orden de paradas. No construir aún una red de transporte a partir de marcadores o líneas ficticias.
