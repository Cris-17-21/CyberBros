# Cyberon — estado del desarrollo

**Corte:** 17 de octubre de 2026  
**Proyecto Flutter:** `app/cyber_bros`  
**Cobertura objetivo:** toda Lima. **Cobertura planificable actual:** piloto limitado de 13 rutas candidatas de corredores; no se debe anunciar como cobertura completa.

## Qué está implementado

### App y experiencia

- Flujo de planificación con origen, destino, presupuesto, límite de caminata, preferencia de viaje y opción de taxi puente.
- Modo de demostración separado de los viajes con datos del piloto. Sus rutas, costos y tiempos se identifican como ilustrativos.
- Opciones estimadas del piloto, detalle por etapas, costo y advertencias sobre datos sin verificar.
- Pantalla de mapa independiente. En Android usa `flutter_map`; en web usa Leaflet sobre OpenStreetMap. No requiere clave de Google Maps.
- El mapa permite buscar paraderos OSM, explorar trazos SIT publicados por ATU, tocar una coordenada para elegir origen o destino y ver ambos marcadores. La ubicación actual se solicita solo al pulsar el botón y otorgar permiso.
- La alternativa elegida se dibuja en ambos mapas con colores para caminata, bus y taxi. Los segmentos son líneas entre puntos conocidos; **no** son navegación detallada por calles.
- Inicio y avance **manual** por etapas de un viaje piloto; se puede marcar como terminado o abandonado. No hay seguimiento GPS continuo ni confirmación de que el vehículo circule.
- Historial local de invitado con copia del plan y su procedencia, retención de hasta 30 días, repetición con datos actuales, cambio de estado y borrado por viaje. No se sincroniza entre dispositivos.
- Pantalla de login visual; los botones de cuenta no simulan una autenticación real.

### Datos y motor

- 47 trazos direccionales SIT descargados y normalizados desde el geovisor ATU; sirven como capa informativa.
- 3 089 nodos OSM etiquetados como parada o plataforma en el área provisional Lima/Callao. Se midieron 2 910 en 38 de 43 distritos referenciales de Lima. Su presencia no confirma operación.
- 95 relaciones OSM con secuencia de paraderos; 13 coincidencias geométricas y de código con trazos ATU forman el piloto actual.
- Tarifas generales publicadas de los corredores Azul, Morado y Rojo, con fuente y advertencias. No se conocen todas las reglas de integración, promociones ni tarifas por tramo.
- Motor Dart local con costos en céntimos, límites de presupuesto y caminata, selección de hasta tres alternativas, caminata directa estimada y taxi puente corto estimado cuando se permite.

## Qué falta

1. **Cobertura real de toda Lima.** Definir y versionar el límite administrativo final; ampliar y validar red, secuencia de paraderos, abordaje, horarios, tarifas y vigencia. El piloto de 13 rutas no representa toda la red.
2. **Rutas y ubicación fiables.** Sustituir líneas rectas de caminata/taxi por trayectos sobre calles; conectar el recorrido a geometrías validadas; mejorar el manejo de puntos fuera del piloto. El GPS actual solo obtiene una posición puntual bajo permiso.
3. **Viaje completo.** Persistir la etapa actual, reanudar el seguimiento, replanificar según saldo o cambios de trayecto, y recoger feedback e incidencias.
4. **Identidad y nube.** Implementar autenticación real, vincular invitado con cuenta, sincronizar historial y definir reglas de acceso y consentimiento en Firebase.
5. **Zavu en el MVP.** Crear backend que guarde la clave, verifique firmas de webhooks, controle duplicados y límites, y use el mismo motor de planificación/replanificación que la app. Definir opt-in y fallback.
6. **Producto y entrega.** Terminar el rediseño de todas las vistas, accesibilidad y adaptación a escritorio; validar comportamiento en Android y navegador; preparar URL pública, privacidad, documentación, presentación y CI.

## Verificación y bloqueo actual

- `flutter analyze lib`: **sin problemas** después de la selección interactiva del mapa y la ubicación puntual.
- `flutter build web --release`: **compiló** con Leaflet y la nueva integración de ubicación. Esto confirma compilación, no una revisión visual completa en navegador.
- La versión nueva **aún no se instaló en el celular**. El ejecutor de Codex en Windows falla antes de compilar Android cuando Java abre un socket local: `Unable to establish loopback connection` / `UnixDomainSockets.connect0: Invalid argument`. El fallo se reproduce con `gradlew help`, sin llegar al código de la app. La versión anterior permanece instalada en el teléfono.
- Para compilar e instalar desde una PowerShell normal, fuera del ejecutor de Codex:

  ```powershell
  cd 'D:\Hackaton\Hack The Andes\app\cyber_bros'
  & 'E:\flutter\bin\flutter.bat' run -d rwlv8lrkeagy5tga
  ```

## Siguiente corte recomendado

1. Instalar la versión nueva en Android desde PowerShell y comprobar toques, marcadores, permiso de ubicación, opciones y avance manual.
2. Corregir cualquier problema observado en el dispositivo.
3. Persistir etapa y añadir replanificación del viaje piloto.
4. Ampliar los datos validados antes de prometer viajes por todo Lima.

## Documentos de referencia

- Requisitos: [`cyberon-requerimientos.md`](cyberon-requerimientos.md)
- Arquitectura: [`cyberon-arquitectura.md`](cyberon-arquitectura.md)
- Diseño: [`cyberon-diseno.md`](cyberon-diseno.md)
- Decisiones vigentes: [`docs/DECISIONS.md`](docs/DECISIONS.md)
- Seguimiento detallado: [`tasks/todo.md`](tasks/todo.md)
