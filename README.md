# Cyberon

Planificador de viajes multimodales para Lima. El producto compara combinaciones de transporte público, caminata y taxi puente según el presupuesto y los límites de caminata de cada viaje.

## Alcance y arquitectura acordados`n`n- Cobertura objetivo: toda Lima; el límite geográfico exacto se fijará antes de afirmar cobertura completa. No es un producto para todo el Perú.`n`n## Arquitectura acordada

- Cliente Flutter para Android y web.
- Motor de planificación local en Dart puro.
- Firebase para identidad opcional, historial y evidencia de uso.
- Zavu está previsto para el MVP; requiere un backend de confianza para guardar la clave y validar webhooks, y debe reutilizar el planificador.
- La demo debe funcionar en web, en incógnito, sin registro ni GPS.

## Estado de arranque

Este repositorio contiene los documentos de contexto, requerimientos, arquitectura y diseño. El primer paso de implementación es medir qué datos de transporte público están disponibles en OpenStreetMap para Lima. El bbox del auditor es provisional y los conteos todavía no se han obtenido: el endpoint público de Overpass respondió que está saturado.

Ejecuta el auditor desde la raíz del repositorio cuando Overpass esté disponible:

```powershell
python tools/check_osm_coverage.py
```

El informe se guarda en `data/reports/osm-lima-coverage.json`. Los conteos sirven para evaluar cobertura; no demuestran que las rutas tengan geometría completa ni paraderos ordenados.

## Documentos

- [Contexto completo](cyberon-contexto-completo.md)
- [Requerimientos](cyberon-requerimientos.md)
- [Arquitectura](cyberon-arquitectura.md)
- [Diseño UX/UI](cyberon-diseno.md)


