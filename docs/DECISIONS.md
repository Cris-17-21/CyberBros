# Decisiones de implementación

**Fecha:** 17/10/2026  
**Estado:** decisiones vigentes para el desarrollo; prevalecen sobre propuestas anteriores cuando difieren.

## D-001 — Cobertura objetivo: todo Lima

La cobertura objetivo del MVP es toda Lima, no todo el Perú ni un solo eje. El límite geográfico exacto se fijará con una delimitación administrativa y quedará versionado en los datos. No se anunciará cobertura completa hasta medir rutas, paraderos, geometrías y secuencia de paradas en el área elegida.

El bbox de `tools/check_osm_coverage.py` es provisional y solo sirve para una primera auditoría. No representa todavía el polígono final de la app.

## D-002 — Zavu forma parte del MVP

Zavu se integra como canal de mensajería para planificar y replanificar. La app y Zavu reutilizarán el mismo dominio de planificación; no se implementará un segundo motor.

La integración necesita un servicio de confianza para guardar la clave de Zavu, verificar la firma de los webhooks y aplicar límites de entrada. Ese servicio será un backend ligero del MVP. Si Zavu o el backend no responden, el flujo principal de la app seguirá disponible.

## Consecuencias

- Las secciones previas que limitan el P0 a un eje o sitúan Zavu en un incremento posterior describen el plan anterior. Se actualizarán al implementar cada módulo afectado.
- No se inventarán rutas, tarifas ni conteos para aparentar cobertura.
- La primera entrega técnica mide los datos abiertos disponibles antes de construir el grafo de ruteo.

## Estado del entorno al iniciar

- El directorio se inicializó como repositorio Git en `main`.
- El entorno actual no encuentra `flutter` ni `dart` en el PATH.
- Overpass devolvió `502` por saturación y `500` en un endpoint alternativo; aún no hay conteos de cobertura.
