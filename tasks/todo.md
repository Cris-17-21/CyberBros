# Cyberon — seguimiento del trabajo

La especificación completa vive en [plan.md](plan.md). Las decisiones D-001 y D-002 de `docs/DECISIONS.md` prevalecen sobre supuestos anteriores: toda Lima es objetivo y Zavu está en el MVP.

## Fase 0 — base y datos

- [x] Revisar los cuatro documentos, el estado actual del código y las decisiones vigentes.
- [x] Crear rama `codex/complete-cyberon`.
- [x] Correr auditoría Overpass; quedó `incomplete` sin conteos (errores 502/500/timeouts). Informe guardado en `data/reports/osm-lima-coverage.json`.
- [ ] Obtener un extracto OSM local, medir rutas/paraderos/geometría y establecer la cobertura administrativa documentada.
- [ ] Implementar normalización, validación y build del dataset versionado.
- [x] Descargar, verificar y normalizar los 47 trazos SIT publicados por ATU; generar activo versionado e informe de cobertura referencial.
- [x] Extraer 3 089 nodos OSM etiquetados como paraderos/plataformas; medir 2 910 en 38/43 distritos referenciales de Lima.
- [x] Extraer 95 relaciones OSM con secuencia de paraderos; medir 13 coincidencias geométricas de corredor con ATU y versionar tarifas generales oficiales.
- [ ] Corregir documentación de instalación/estado del producto.

## Fase 1 — motor y planificación

- [ ] Modelos Dart puros y validadores, en céntimos y con certidumbre.
- [ ] Motor de ruta multimodal con restricciones duras, taxi puente, Pareto e infactibilidad.
- [x] Implementar núcleo Dart puro con costo en céntimos, abordaje, dominancia, restricciones duras y selección de hasta tres rutas; conectarlo a un piloto de 13 corredores con incertidumbre visible.
- [x] Generar caminata directa estimada y taxi puente corto entre dos trayectos de transporte dentro del piloto, con costo señalado como estimado.
- [x] Mostrar desde la portada el alcance del piloto y fecha de los trazos; exigir transporte antes y después del taxi puente.
- [ ] Pruebas de motor y viajes de oro.
- [ ] Búsqueda local, mapa interactivo, GPS opcional y conexión de S1–S4 al motor.
- [x] Volver a separar el mapa de los formularios y las opciones; crear pantalla de mapa dedicada.
- [x] Habilitar Flutter Web y mostrar Leaflet + OpenStreetMap en navegador; mantener `flutter_map` en Android.
- [ ] Conectar puntos elegidos, geolocalización y rutas validadas a ambas vistas del mapa.
- [x] Permitir tocar Flutter Map o Leaflet para elegir coordenadas de origen/destino, ver marcadores y devolverlas al planificador. Geolocalización puntual bajo permiso con `geolocator`; no hay seguimiento GPS continuo.
- [x] Dibujar en Flutter Map y Leaflet los tramos de la alternativa piloto elegida, con colores por caminata, bus y taxi; se representan como líneas entre puntos OSM, no como navegación calle por calle.
- [x] Permitir seleccionar y visualizar los trazos ATU en Leaflet y Flutter Map, con procedencia y límites explícitos.
- [x] Buscar paraderos OSM localmente y centrarlos en ambos mapas, sin asumir operación ni vínculo a una ruta.
- [x] Fijar origen/destino desde búsqueda local o mapa, invalidar coordenadas al editar texto, intercambiar puntos y bloquear pares a menos de 100 m.
- [x] Aplicar presupuesto, caminata seguida/total y preferencia de taxi a las alternativas de demostración; hacer coherente su detalle y portapapeles.
- [x] Limitar las opciones con precios ilustrativos al viaje de ejemplo; las entradas libres muestran la falta de datos verificables.
- [ ] Rediseño visual de todo el flujo según `cyberon-diseno.md` y soporte escritorio.

## Fase 2 — completar viaje y demo

- [ ] Revisión, seguimiento, replanificación por saldo, feedback/reportes.
- [x] Añadir inicio y avance manual por etapas del viaje piloto, con estados activo/terminado/abandonado guardados en el historial local. El índice de etapa aún no persiste y se informa en pantalla.
- [ ] Demo determinista sin GPS y aislada de tracción.
- [x] Guardar copia local del viaje piloto elegido, listar historial de invitado, repetir con datos actuales, actualizar estado manual y borrar un viaje.

## Fase 3 — persistencia, cuentas y tracción

- [ ] Auth invitada/cuenta opcional; enlace de invitado a cuenta.
- [ ] Historial privado, repetir/reanudar/eliminar, copia de alternativa/datos.
- [x] Historial local de invitado con retención de 30 días y degradación a memoria si falla el almacenamiento; faltan aislamiento por cuenta y sincronización.
- [ ] Consentimiento, eventos idempotentes, analítica agregada real y reglas Firestore probadas.

## Fase 4 — integración Zavu

- [ ] Backend seguro, contrato de mensajería, verificación de webhook, idempotencia/rate-limit.
- [ ] Flujos de planificación/replanificación con opt-in y el mismo dominio del cliente.
- [ ] Fallback completo cuando el proveedor no esté configurado o falle.

## Fase 5 — capacidades adicionales

- [ ] Parser de lenguaje natural confirmado por el usuario.
- [ ] Alertas con fuente/fecha/fallback.
- [ ] Telemetría con consentimiento, simulador y protecciones anti-manipulación servidor.
- [ ] Refresco, memoria y gestión avanzada de cuenta según alcance de requisitos.

## Fase 6 — entrega

- [ ] Pruebas, CI, accesibilidad, rendimiento, Android + web.
- [ ] URL pública probada en incógnito, descripción, slides, privacidad, secretos y submit.

## Verificación del último corte

- `flutter analyze lib`: sin problemas tras añadir historial local y acceso de invitado explícito.
- `flutter test`: el test de acceso existente pasó.
- `flutter build web --release`: compilación completada con `shared_preferences` e historial local.
- No se hizo revisión visual en navegador porque la política de permisos rechazó abrir el servidor local; no se intentó otro mecanismo de navegador.
- `flutter build apk --debug`: bloqueado antes de compilar. Java 21 falla al abrir `Selector` con `Unable to establish loopback connection` incluso en una prueba aislada; `--no-daemon` y cambiar `java.io.tmpdir` no alteran el error. No parece originarse en el código Flutter.
