# Demo: condiciones recordadas (RF-26)

Capturas de la **app Flutter real** (`flutter build web --release`) en Chromium, con la cuenta
verificada por el **Firebase Auth Emulator** (`demo-rutealo`, sin producción) y
`services/preferences_api` hablando con el **fixture local de Atomic Memory**
(`services/preferences_api/test/support/atomic_memory_fixture.dart`). El fixture es un doble de prueba,
**no el servicio real**; los pasos para reproducirlo están en
[`services/preferences_api/README.md`](../../../services/preferences_api/README.md).

| Archivo | Qué muestra |
|---|---|
| `rutealo-condiciones.webm` | 31 s, 1280×800: guardar → recargar la app y recordar → usar → corregir → olvidar |
| `1-guardado.png` | Guardado confirmado tras pulsar "Guardar mis condiciones" |
| `2-recordado.png` | Tras recargar la app, la tarjeta recuerda S/ 6 · sin taxi · Ahorro; los controles aún no cambian |
| `3-usado-controles.png` | Después de "Usar estas": el presupuesto pasa a S/ 6 |
| `4-corregido.png` | "Guardar las actuales" reemplaza el recuerdo por S/ 10 · 200 m |
| `5-olvidado.png` | "Olvidar" confirmado por el servidor; vuelve a la tarjeta vacía |
| `6-fallo-no-confirmado.png` | Con el fixture en modo `failing`, la app dice "No pudimos confirmar que se guardó" |
| `430-*.png` | La misma pantalla a 430 px de ancho: tarjeta vacía, tarjeta con recuerdo y controles |
