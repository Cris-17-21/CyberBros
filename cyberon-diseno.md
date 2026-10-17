# 🎨 Cyberon — Sistema de diseño UX/UI: **"Amanecer en los Andes"**

**Proyecto:** Cyberon · **Evento:** Hack the Andes (Lima, 17–18 oct 2026) · **Cliente:** Flutter (Android + web mobile-first)
**Documentos hermanos:** [requerimientos](cyberon-requerimientos.md) · [arquitectura](cyberon-arquitectura.md) · [contexto](cyberon-contexto-completo.md)

> **Qué es este documento:** la guía visual y de experiencia para construir la interfaz de Cyberon de forma **coherente, armoniosa y accesible**. Define concepto, identidad, color, tipografía, componentes, pantallas, estados, movimiento, microtextos y su implementación en Flutter. Es **el "cómo se ve y se siente"**; el "qué hace" está en los requerimientos.

| Marca | Significado |
|---|---|
| ✅ | Decisión firme |
| 🧮 | Valor **calculado y verificado** (contrastes WCAG medidos el 17/10/2026) |
| ⚠️ | Por verificar al implementar |
| 🤖 | Nota para el agente constructor |
| 🔻 | Se recorta si el tiempo aprieta |

---

## 1. Concepto creativo: **"Amanecer en los Andes"**

### 1.1 La idea
Hack the Andes dura **30 horas con pernocte**: arranca de día en Lima, se construye de noche y se **presenta al amanecer del domingo**. Cyberon cuenta esa misma historia: **del azul profundo de la noche andina al oro del primer sol sobre la cordillera**.

- **La noche** (azules profundos) = el problema: moverse en una ciudad grande sin información clara.
- **El amanecer** (dorado y terracota cálidos) = la solución: claridad, orientación, "ya sé cómo llego".
- **La cordillera** (siluetas escalonadas) = el recorrido: una línea que sube, baja, hace conexiones.

### 1.2 Por qué encaja con el producto
| Elemento del producto | Metáfora visual |
|---|---|
| Ruta con transbordos | Línea que **asciende por peldaños** (geometría escalonada andina) |
| Presupuesto restante | Un **sol que se va descubriendo** (el saldo es la luz que te queda) |
| Incertidumbre (estimado / inferido) | **Neblina**: lo borroso se muestra suave, lo confirmado nítido |
| Taxi puente | Un **puente** corto entre dos picos |
| Completar el viaje | **Amanecer**: el fondo pasa de noche a día al llegar |

### 1.3 Palabras clave de marca
**Claro · Honesto · Cercano · Andino · Confiable.** El tono visual es **cálido y sereno**, no "tecnológico frío": es una herramienta para gente cansada, con prisa, en la calle.

### 1.4 Respeto cultural
Se usa **geometría escalonada abstracta** inspirada en textiles y arquitectura andina como textura y ritmo. **No** se usan símbolos sagrados ni iconografía religiosa, ni se imitan trajes o personas como decoración. El motivo es **sutil** (fondos, divisores, estados vacíos), nunca invade el contenido.

---

## 2. Principios de UX/UI aplicados

| # | Principio | Cómo se concreta en Cyberon | Requerimientos |
|---|---|---|---|
| 1 | **Honestidad visible** | Todo importe y paradero lleva su chip de certidumbre; lo simulado se rotula | RF-09, RNF-09 |
| 2 | **Una acción principal por pantalla** | Un solo botón relleno por vista; el resto son secundarios | RNF-14 |
| 3 | **Ley de Hick** (menos opciones, decisión rápida) | Máximo **3 alternativas**; filtros ocultos tras "Ajustar" | RF-07 |
| 4 | **Divulgación progresiva** | Tarjeta resumida → toque → detalle por tramos | RF-08 |
| 5 | **Ley de Fitts / zona del pulgar** | Acciones clave **abajo**, objetivos ≥ 48 px, sin esquinas superiores para acciones | RNF-14 |
| 6 | **Reconocer antes que recordar** | Etiquetas interpretadas y editables; atajos de presupuesto | RF-03, RF-04 |
| 7 | **Prevención de errores** | Valores por defecto, validación inmediata, relajaciones **solo con consentimiento** | RF-03, RF-10 |
| 8 | **Feedback inmediato** | Respuesta táctil/visual < 100 ms; progreso visible en cálculos > 300 ms | RNF-02, RNF-04 |
| 9 | **Control y libertad del usuario** | Deshacer, volver, editar condiciones en un toque; nunca se cambian sus límites solos | RF-10, RF-13 |
| 10 | **Consistencia** | Un solo sistema de color/forma/icono para cada concepto en toda la app | — |
| 11 | **Jerarquía visual** | Costo y caminata son lo más grande; el detalle técnico, lo más pequeño | RF-08 |
| 12 | **Uso en calle** | Alto contraste, texto corto, una mano, mínimo de datos | RNF-14, RNF-18 |
| 13 | **Armonía (regla 60-30-10)** | 60 % neutros cálidos · 30 % azul andino · 10 % acentos (oro/terracota) | — |
| 14 | **Redundancia del color** | Forma + icono + texto además del color (nunca solo color) | RNF-16 |

---

## 3. Identidad

### 3.1 Nombre y tagline
- **Nombre:** **Cyberon** (se escribe en minúsculas en el logotipo: `cyberon`, con la **o** final como "sol").
- **Tagline principal:** *"Llega con lo que tienes."* (presupuesto + caminata reales).
- **Tagline técnico (pitch):** *"Rutas que respetan tu bolsillo y tus pasos."*
- **Etiqueta de evento (opcional, en splash):** *Hecho en Hack the Andes · Lima 2026*.

### 3.2 Logotipo (concepto + SVG base)
**Concepto:** una **línea de ruta** que sube formando **tres peldaños** (silueta de cordillera) y termina en un **círculo dorado** (el sol / el destino). Debe leerse a 24 px.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" role="img" aria-label="Cyberon">
  <rect width="64" height="64" rx="16" fill="#1E4D7B"/>
  <!-- ruta escalonada -->
  <path d="M10 46 H22 V36 H34 V26 H44" fill="none" stroke="#FBF7F0"
        stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
  <!-- destino / sol -->
  <circle cx="50" cy="20" r="6" fill="#E0A526"/>
</svg>
```
- **Icono de app:** el cuadrado redondeado azul con la ruta y el sol.
- **Variante monocromática** (blanco sobre azul / azul sobre blanco) para slides y favicon.
- **Zona de respeto:** margen = ½ del alto del icono. **Tamaño mínimo:** 24 px.
- ⚠️ Exportar a PNG/SVG y a los tamaños de ícono de Android y favicon al implementar.

### 3.3 Motivo gráfico: el **"escalón andino"**
Patrón geométrico de escalones (como una línea quebrada ascendente), usado con **opacidad baja (6–12 %)**:
- Banda decorativa en splash, cabecera del panel de tracción y estados vacíos.
- Divisor de sección (línea escalonada fina de 1 px).
- **Nunca** detrás de texto de lectura continua.

```
  Divisor escalonado (ilustrativo):

        ┌─┐   ┌─┐
      ┌─┘ └─┐ │ └─┐
    ┌─┘     └─┘   └─
```

---

## 4. Color

### 4.1 Paleta base (modo claro)

> 🧮 Todos los pares de texto de esta sección cumplen **WCAG AA (≥ 4,5:1)**; los gráficos del mapa, **≥ 3:1**. Ratios medidos con la fórmula de luminancia relativa de WCAG.

| Token | Nombre | Hex | Uso |
|---|---|---|---|
| `bg` | **Quinua** | `#FBF7F0` | Fondo general (60 %) |
| `surface` | Nieve | `#FFFFFF` | Tarjetas, hojas inferiores |
| `surfaceAlt` | Lana | `#F1EADF` | Fondos secundarios, campos |
| `ink` | **Noche** | `#1B2433` | Texto principal |
| `inkMuted` | Piedra | `#586274` | Texto secundario |
| `primary` | **Lago** | `#1E4D7B` | Marca, botones principales, ruta en transporte (30 %) |
| `primaryDark` | Cordillera | `#163A5C` | Cabeceras, estados presionados |
| `accent` | **Oro de ichu** | `#E0A526` | Resaltes, sol del logo, progreso (10 %) |
| `taxi` | **Teja** | `#B8452E` | Tramo puente en taxi, atención cálida |
| `ok` | Puna | `#2E7D5B` | Confirmado / oficial |
| `info` | Chicha | `#6B3FA0` | Inferido por GPS |
| `warn` | Ámbar | `#B7791F` | Estimado / advertencia |
| `error` | Rocoto | `#B3261E` | Errores |

**Contenedores suaves (para chips y avisos):**
| Token | Fondo | Texto |
|---|---|---|
| `okC` | `#DDF1E7` | `#1F5E43` |
| `warnC` | `#FCEBC8` | `#7A4A00` |
| `infoC` | `#EBE1F7` | `#4F2A85` |
| `taxiC` | `#FBE3DC` | `#8F3322` |
| `errorC` | `#FBE0DE` | `#8C1D18` |
| `neutralC` | `#E8E6E1` | `#3F4857` |

### 4.2 Contrastes verificados 🧮 (modo claro)

| Par (texto / fondo) | Ratio | Resultado |
|---|---|---|
| `ink` / `bg` | **14,60** | AAA |
| `ink` / `surface` | **15,59** | AAA |
| `inkMuted` / `bg` | **5,76** | AA |
| `inkMuted` / `surface` | **6,15** | AA |
| blanco / `primary` | **8,74** | AAA |
| blanco / `primaryDark` | **11,71** | AAA |
| `ink` / `accent` (texto sobre oro) | **7,11** | AAA |
| `primary` / `bg` (texto de enlace) | **8,18** | AAA |
| blanco / `taxi` | **5,35** | AA |
| blanco / `ok` | **5,00** | AA |
| blanco / `error` | **6,54** | AA |
| `okC` texto / fondo | **6,50** | AA |
| `warnC` texto / fondo | **6,36** | AA |
| `infoC` texto / fondo | **8,31** | AAA |
| `taxiC` texto / fondo | **6,43** | AA |
| `errorC` texto / fondo | **7,30** | AAA |
| `neutralC` texto / fondo | **7,40** | AAA |

> ⚠️ **Regla derivada:** el color `warn` (`#B7791F`) y `accent` (`#E0A526`) **no se usan como color de texto sobre fondos claros**; para texto de advertencia se usa el par `warnC` (texto oscuro sobre fondo ámbar suave).

### 4.3 Modo oscuro ("Noche andina")

| Token | Hex | Uso |
|---|---|---|
| `bg` | `#0F1724` | Fondo |
| `surface` | `#182234` | Tarjetas |
| `surfaceAlt` | `#223049` | Campos, secundarios |
| `ink` | `#EDEAE3` | Texto principal |
| `inkMuted` | `#A8B0BF` | Texto secundario |
| `primary` | `#8DB9E8` | Marca, ruta, botón principal (texto `#0F1724` encima) |
| `accent` | `#F0BE4A` | Resaltes |
| `taxi` | `#E58A73` | Taxi puente |
| `ok` / `info` / `warn` / `error` | `#5CC59A` / `#B79AE6` / `#E3B04B` / `#F2998F` | Estados |

**Contenedores oscuros:** `okC` `#16382B`/`#9FDDBF` · `warnC` `#43310C`/`#F5CF84` · `infoC` `#33224F`/`#CDB3F2` · `taxiC` `#4A2219`/`#F4B3A2`.

🧮 **Contrastes (oscuro):** `ink`/`bg` **14,96** · `inkMuted`/`bg` **8,24** · `ink`/`surface` **13,27** · `inkMuted`/`surface` **7,31** · `primary`/`bg` **8,76** · texto oscuro sobre `primary` **8,76** · `accent`/`bg` **10,42** · `okC` **8,30** · `warnC` **8,40** · `infoC` **7,64** · `taxiC` **7,70** → todos ≥ AA.

### 4.4 Significado del color (mapa semántico — **una sola vez, siempre igual**)

| Concepto | Color | **Forma / icono (obligatorio además del color)** |
|---|---|---|
| Confirmado / paradero oficial | `ok` (Puna) | ● círculo + ícono de bus + texto "Confirmado" |
| Estimado | `warn` (Ámbar) | ◐ medio círculo + texto "Estimado" |
| Inferido por GPS | `info` (Chicha) | ◆ rombo + borde punteado + "Inferido · 82 %" |
| Simulado (demo) | `neutral` + rayado | ▨ rayado + "SIMULADO" (siempre visible) |
| Tramo en transporte | `primary` (Lago) | línea **continua** gruesa |
| Caminata | gris piedra | línea **discontinua** corta |
| Taxi puente | `taxi` (Teja) | línea **discontinua larga** con punto |
| Error | `error` | ▲ triángulo + mensaje |

### 4.5 Distribución (regla 60-30-10)
**60 %** neutros cálidos (`bg`, `surface`, `surfaceAlt`) · **30 %** `primary` (cabeceras, botones, ruta) · **10 %** acentos (`accent` para resaltes/progreso, `taxi` para el puente). Los colores semánticos aparecen **solo** como chips y marcadores, no como fondos grandes.

---

## 5. Tipografía

| Rol | Fuente | Peso | Uso |
|---|---|---|---|
| **Títulos / cifras grandes** | **Sora** | 600–700 | Títulos, costo total, saldo restante |
| **Cuerpo / interfaz** | **Inter** | 400–600 | Texto, etiquetas, botones |
| **Cifras tabulares** | Inter con `tabular-figures` | 600 | Importes **S/ 8,50**, metros, tiempos (alinean verticalmente) |

> ✅ Razón: **Sora** aporta carácter geométrico y amable a los títulos; **Inter** es muy legible en pantallas pequeñas. Dos familias bastan.
> ⚠️ **Empaquetar las fuentes como *assets*** (no descargarlas en ejecución): evita parpadeo de texto y fallos en incógnito o sin red, y baja el riesgo en la demo.

### 5.1 Escala tipográfica (móvil, en `sp`)

| Estilo | Fuente | Tamaño / interlineado | Uso |
|---|---|---|---|
| `display` | Sora 700 | 32 / 40 | Saldo restante, costo en detalle |
| `headline` | Sora 600 | 24 / 32 | Título de pantalla |
| `title` | Sora 600 | 18 / 26 | Título de tarjeta |
| `body` | Inter 400 | 16 / 24 | Texto general (**mínimo 16** en contenido) |
| `bodyStrong` | Inter 600 | 16 / 24 | Datos clave |
| `label` | Inter 600 | 14 / 20 | Botones, chips |
| `caption` | Inter 400 | 12 / 16 | Fuente de datos, fechas (nunca para información crítica) |

- Longitud de línea ≤ **60 caracteres**; alineación a la izquierda; sin mayúsculas sostenidas salvo etiquetas cortas (`SIMULADO`).
- El texto debe poder **ampliarse al 200 %** sin romper la interfaz (RNF-16): contenedores flexibles, sin alturas fijas en texto.

---

## 6. Espaciado, forma y elevación

### 6.1 Cuadrícula y espaciado (base **4 pt**)
`4 · 8 · 12 · 16 · 24 · 32 · 48`
- **Margen lateral de pantalla:** 16 (móvil) · 24 (tablet) · contenedor de **máx. 1200** en escritorio.
- **Separación entre tarjetas:** 12. **Padding interno de tarjeta:** 16.
- **Objetivo táctil mínimo:** **48 × 48** (separación ≥ 8 entre objetivos).

### 6.2 Forma (radios)
| Elemento | Radio |
|---|---|
| Chips, etiquetas | 8 |
| Campos, botones | 12 |
| Tarjetas | 16 |
| Hojas inferiores (parte superior) | 24 |
| Marcadores y botones circulares | 50 % |

### 6.3 Elevación
**Tonal, no pesada:** se distingue por **color de superficie + borde de 1 px** (`outline` ≈ `#E3DACB` en claro / `#2D3B55` en oscuro). Sombra **solo** en hojas inferiores y elementos flotantes sobre el mapa (blur suave, 8–16 px, opacidad ≤ 16 %).

---

## 7. Iconografía e ilustración

- **Set de iconos:** **Material Symbols (redondeados)**, trazo 2 px, tamaño 24 (20 en chips). Consistencia sobre variedad.
- **Iconos clave:** 🚶 caminar · 🚌 bus/corredor · 🚇 metro/Metropolitano · 🚖 taxi · 📍 punto · 🏁 destino · ⏱ tiempo · 💰 dinero · ⚠ aviso · 🛈 info de dato · ✓ confirmado.
- **Ilustración:** líneas simples y **siluetas de cordillera escalonada** para estados vacíos, carga y éxito; paleta limitada (`primary`, `accent`, `surfaceAlt`). **Sin** fotos de personas ni stock.
- **Estados con personalidad:** vacío ("Aún no tienes viajes" + silueta de montaña), éxito (amanecer), error (neblina).

---

## 8. El mapa (estilo y capas)

**Objetivo:** que la **ruta** sea lo más legible; el mapa de fondo, **calmado**.

| Capa | Estilo |
|---|---|
| **Base** | Teselas **suavizadas** (poca saturación, `~#F2EFE9`); si el proveedor lo permite, estilo claro; en oscuro, estilo oscuro |
| **Tramo transporte** | `primary` · **5 px continua** · **contorno blanco de 8 px** (casing) para separar del fondo |
| **Caminata** | gris `#6B7280` · **4 px discontinua (6-6)** |
| **Taxi puente** | `taxi` · **5 px discontinua larga (12-6)** con un punto al centro |
| **Origen / destino** | Pin con letra **A / B** (blanco sobre `primaryDark`); destino con bandera |
| **Paradero oficial** | ● círculo `ok` con icono de bus |
| **Paradero comunitario (OSM)** | ○ círculo gris azulado con borde |
| **Paradero inferido** | ◆ rombo `info`, **borde punteado**, pulso lento (solo si `reduce motion` está apagado) |
| **Posición del usuario** | Punto azul con halo de precisión |

🧮 Contrastes de líneas contra el fondo del mapa (`#F2EFE9`): transporte **7,62** · taxi **4,66** · caminata **4,21** → todos **≥ 3:1** (mínimo de gráficos no textuales). Además se distinguen por **patrón de trazo**, no solo por color (RNF-16).

- **Atribución del proveedor de mapas** siempre visible (pequeña, esquina inferior).
- **Máx. 300 marcadores**; agrupar con contador a zoom bajo (RNF-04).
- **Encuadre automático** a la alternativa seleccionada con **margen** para que no la tape la hoja inferior.

---

## 9. Componentes

> Cada componente define **anatomía, estados y reglas**. Todos respetan: objetivo táctil ≥ 48, contraste AA, foco visible, etiqueta accesible.

### 9.1 Botones
| Tipo | Apariencia | Uso |
|---|---|---|
| **Primario** | Relleno `primary`, texto blanco, alto **52**, radio 12, ancho completo | **Una por pantalla**: "Ver opciones", "Empezar viaje" |
| **Secundario** | Borde `primary` 1,5 px, texto `primary` | "Ajustar condiciones", "Volver" |
| **Terciario** | Solo texto `primary` | "Cancelar", enlaces |
| **De peligro** | Relleno `error` | "Eliminar viaje" (con confirmación) |
**Estados:** normal · presionado (`primaryDark` + leve escala 0,98) · deshabilitado (50 % de opacidad **y** sin elevación) · cargando (indicador circular dentro; el texto se conserva para no saltar el diseño).

### 9.2 Campo de presupuesto
- Campo grande con **S/** fijo a la izquierda, cifra en `display`, teclado numérico.
- **Atajos**: chips `S/ 6 · 8 · 10 · 15` (un toque completa).
- **Validación en línea:** mensaje debajo, en lenguaje llano ("Pon un monto mayor a S/ 0").

### 9.3 Control de caminata
- **Slider** con valor visible en metros **y** equivalencia en cuadras (`300 m ≈ 3 cuadras`).
- Marcas en 100 · 200 · 300 · 500 · 800.
- Dos controles: "Caminata seguida" y "Caminata total".

### 9.4 Interruptor de taxi y prioridad
- **Toggle** "Acepto taxi en un tramo" con texto de ayuda: *"Solo lo usamos si te ahorra caminata."*
- **Prioridad**: control segmentado de 4 opciones con icono + texto (Ahorro · Menos caminata · Tiempo · Menos transbordos).

### 9.5 `CertaintyChip` (el componente más importante)
Variantes (forma + icono + texto + color, RF-09):

| Variante | Icono | Texto | Colores |
|---|---|---|---|
| `confirmed` | ✓ en círculo | "Confirmado" | `okC` |
| `estimated` | ◐ | "Estimado" | `warnC` |
| `inferred` | ◆ | "Inferido · 82 %" | `infoC` |
| `simulated` | ▨ | "SIMULADO" | `neutralC` + rayado |
- Altura 28, radio 8, texto `label` 12–14.
- **Toque** → mini-hoja con **fuente y fecha** del dato ("Tarifa verificada el 17/10 · fuente: …").
- Si el dato no tiene fuente, el chip **se degrada a `estimated`** automáticamente.

### 9.6 `AlternativeCard` (tarjeta de alternativa)

```
┌────────────────────────────────────────────┐
│  MENOS CAMINATA                  ⓘ         │  ← etiqueta (label) + info
│                                            │
│  S/ 8,50   ·  ◐ Estimado                   │  ← costo (display) + chip
│  🚶 250 m      ⏱ 38 min      🔁 1 trasbordo │  ← datos clave (iconos + cifras)
│                                            │
│  🚶 → 🚌 Corredor Azul → 🚖 → 🚶            │  ← resumen de tramos
│                                            │
│  Un taxi corto evita 850 m seguidos a pie. │  ← tradeoff en 1 línea
│                                  [ Ver ▸ ] │
└────────────────────────────────────────────┘
```
- **Jerarquía:** costo y caminata en tamaño grande; el resto, secundario.
- **Seleccionada:** borde `primary` 2 px + fondo `surface` + marca ✓ (no solo color).
- La **"rodilla"** (equilibrada) lleva una insignia pequeña **"Recomendada"** solo si el motor la determina; si no, no se muestra.
- **Estados:** normal · seleccionada · con advertencia (franja `warnC` superior) · deshabilitada (si pasa a infactible tras editar).

### 9.7 `LegTimeline` (detalle por tramos)
Línea vertical con nodos:

```
 ●─ A  Tu ubicación
 ┆   🚶 Camina 150 m · 2 min                     ◐ Estimado
 ●─ Paradero Av. Brasil  ● Oficial
 ┃   🚌 Corredor Azul · S/ 2,50 · 12 min          ✓ Confirmado
 ●─ Paradero Plaza Bolognesi  ◆ Inferido · 82 %
 ┄   🚖 Taxi puente ~1,4 km · S/ 5,50 · 6 min     ◐ Estimado
 ●─ B  Destino
```
- Línea **sólida** (transporte), **discontinua corta** (caminata), **discontinua larga** (taxi) — igual que en el mapa.
- Cada tramo muestra **costo**, **duración** y su **chip de certidumbre**.

### 9.8 `TradeoffCallout`
Caja `surfaceAlt` con borde izquierdo de 4 px en `accent`, icono de balanza y **dos líneas**: **Ganas** / **Sacrificas**.
> **Ganas:** tu caminata seguida baja de 850 m a 90 m.
> **Sacrificas:** +S/ 4,50 sobre la opción más barata.

### 9.9 `InfeasibleCard` (sin solución)
Tono **amable**, nunca de error: ilustración de neblina, título *"Con esos límites no encontramos un recorrido"* y **botones de relajación** (máx. 2):
- **[ +S/ 2,50 y usar taxi en Javier Prado ]**
- **[ Caminar +320 m en Av. Arequipa ]**
- Terciario: *"Mantener mis límites"*.
Cada botón muestra **el cambio exacto** y **solo** aplica esa restricción (RF-10).

### 9.10 `NextStepCard` (seguimiento, S6)
Tarjeta inferior fija: **una acción grande** ("Camina 150 m hacia Av. Brasil"), progreso `●──●○○`, **saldo restante** (`BalanceMeter`) y botón **"Algo cambió"** secundario.

### 9.11 `BalanceMeter` (saldo restante)
- Cifra grande `S/ 6,50` + **barra de sol**: un arco o barra que se **llena de oro** proporcional al saldo. Al bajar de 20 %, pasa a `taxi`/ámbar con texto "Te queda poco".
- Debe tener **texto** además del gráfico.

### 9.12 `StopMarker` y hoja de paradero
Marcadores según 4.4. Al tocar: hoja con nombre, **tipo (chip)**, rutas que lo sirven, fuente/fecha; si es inferido, "usuarios con GPS esperaron aquí" y botón **"No subí aquí"** (RF-36).

### 9.13 Navegación
- **Móvil:** barra inferior de **3 pestañas** — *Planificar · Mis viajes · Cuenta* (icono + texto). El panel de tracción vive en **Cuenta → "Impacto"** y también en una URL pública directa.
- **Escritorio (jurado):** barra lateral compacta + área de contenido (ver sec. 16).
- **Atrás** siempre disponible; **sin** menús ocultos para acciones principales.

### 9.14 Hojas inferiores (bottom sheets)
Asa visible, 3 alturas (peek / media / completa), contenido desplazable, fondo `surface`, radio 24. El **mapa queda visible** detrás en peek y media.

### 9.15 Avisos y mensajes
| Tipo | Componente | Ejemplo |
|---|---|---|
| Informativo no bloqueante | Snackbar (4 s, con acción) | "Guardado en tu historial" |
| Advertencia en contexto | Franja `warnC` dentro de la tarjeta | "Espera estimada: puede variar" |
| Error recuperable | Tarjeta con acción "Reintentar" | "No pudimos guardar. Reintentar" |
| Confirmación destructiva | Diálogo con texto claro y botón de peligro | "¿Eliminar este viaje?" |

### 9.16 Panel de tracción (S9) — `StatTile`
Mosaico de 2 columnas (móvil) / 4 (escritorio): **cifra grande** + etiqueta + variación. Siempre muestra **"Datos hasta [hora]"** y el **criterio de conteo** ("excluye al equipo y datos simulados"). Fondo con banda del **escalón andino** al 8 % de opacidad.

---

## 10. Pantallas (wireframes de 360 px)

> Convención: `▓` acción principal · `░` mapa · `[ ]` botón · `( )` control.

### S0 · Splash y primera visita
```
┌──────────────────────────┐
│  ▁▂▃▅▆▇ (cordillera)     │  ← degradado Noche → Oro
│                          │
│        [logo]            │
│       cyberon            │
│  Llega con lo que tienes │
│                          │
│  [ Probar sin registrarme ]│ ▓
│  [ Crear cuenta / Entrar ]│
│  Hecho en Hack the Andes │
└──────────────────────────┘
```
- **Invitado primero** (RF-33). Duración visible ≤ 1,5 s (RNF-03); el motor y el dataset cargan **detrás**.

### S1 · Origen y destino
```
┌──────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░  mapa  ░░░░░░░░░░ │
│ ░░░  (A)        (B) ░░░░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░ │
├──────────────────────────┤  ← hoja
│  ━━                      │
│  📍 Desde:  Mi ubicación │
│  🏁 Hasta:  ¿A dónde vas?│
│  [ Usar un viaje de ejemplo ]│ (modo demo)
│  [ Siguiente ▸ ]         │ ▓
└──────────────────────────┘
```

### S2 · Condiciones
```
┌──────────────────────────┐
│ ‹ Tus condiciones        │
│                          │
│ ¿Cuánto puedes gastar?   │
│  S/  [ 8,00 ]            │
│  ( 6 ) ( 8 ) ( 10 ) ( 15 )│
│                          │
│ ¿Cuánto caminas seguido? │
│  ──●─────  300 m ≈ 3 cuadras│
│                          │
│ ¿Aceptas un taxi corto?  │
│  Solo si te ahorra camino   [●]│
│                          │
│ Prioridad                │
│ (Ahorro)(Menos caminata)…│
│                          │
│ ✍ Cuéntalo con tus palabras│ (Inc. B)
│                          │
│ [ Ver opciones ]         │ ▓
└──────────────────────────┘
```

### S3 · Comparar alternativas
```
┌──────────────────────────┐
│ ░░░░ mapa con rutas ░░░░ │
│ ░░ ━━━ ┄┄┄ ╌╌╌ ░░░░░░░░ │
├──────────────────────────┤
│  ━━                      │
│ ┌──────────────────────┐ │
│ │ MÁS BARATA  S/ 5,00  │ │  ← tarjetas desplazables
│ └──────────────────────┘ │     (carrusel o lista)
│ ┌──────────────────────┐ │
│ │ MENOS CAMINATA S/ 8,50││ ✓ seleccionada
│ └──────────────────────┘ │
│ ┌──────────────────────┐ │
│ │ EQUILIBRADA  S/ 6,50 │ │
│ └──────────────────────┘ │
│ [ Elegir esta opción ]   │ ▓
│  ‹ Ajustar condiciones   │
└──────────────────────────┘
```

### S4 · Sin solución
```
┌──────────────────────────┐
│     (ilustración neblina)│
│ Con esos límites no      │
│ encontramos recorrido    │
│                          │
│ Con S/ 4,00 y 200 m no   │
│ hay opción. Puedes:      │
│ [ +S/ 2,50 y taxi en     │
│   Javier Prado ]         │
│ [ Caminar +320 m en      │
│   Av. Arequipa ]         │
│  Mantener mis límites    │
└──────────────────────────┘
```

### S5 · Revisión antes de salir
```
┌──────────────────────────┐
│ ‹ Tu recorrido           │
│ Gastarás ~S/ 8,50 ◐ Estimado│
│ Te quedarán ~S/ 0,50     │
│                          │
│ 1 🚶 Camina 150 m a Av. Brasil│
│ 2 🚌 Corredor Azul → Plaza…  │
│ 3 🚖 Taxi puente ~1,4 km    │
│      ⚠ Confirma el precio en tu app de taxi│
│ 4 🚶 Camina 90 m a tu destino│
│                          │
│ [ Empezar viaje ]        │ ▓
└──────────────────────────┘
```

### S6 · Seguimiento
```
┌──────────────────────────┐
│ ░░░░░ mapa grande ░░░░░░ │
│ ░░ (tú) ●━━━━ ░░░░░░░░░ │
├──────────────────────────┤
│  ●──●○○   Paso 1 de 4    │
│ 🚶 Camina 150 m hacia    │
│    Av. Brasil            │
│ Saldo  S/ 6,50  ▓▓▓▓░░   │
│ [ Listo, siguiente ]     │ ▓
│  Algo cambió             │
└──────────────────────────┘
```

### S7 · Algo cambió
```
┌──────────────────────────┐
│ ¿Qué pasó?               │
│ ( Ya no quiero caminar tanto )│
│ ( El taxi cuesta más )   │
│ ( Me bajé en otro punto ) │
│ ( Gasté un monto )       │
│ ( Tengo menos dinero )   │
│  → Gasté:  S/ [ 2,50 ]   │
│  Te quedan S/ 6,50       │
│ [ Recalcular desde aquí ]│ ▓
└──────────────────────────┘
```

### S8 · Fin del viaje
```
┌──────────────────────────┐
│   (amanecer ilustrado)   │
│  ¡Llegaste!              │
│  ¿Pudiste hacer el recorrido?│
│  ( Sí ) ( Parcial ) ( No )│
│  ¿Coincidieron tarifas y │
│  paraderos?  (opcional)  │
│  [ Enviar ]  Omitir      │
└──────────────────────────┘
```

### S9 · Impacto (tracción pública)
```
┌──────────────────────────┐
│ ▁▂▃▅▆▇ banda escalonada  │
│ Impacto de Cyberon       │
│ Datos hasta 09:40        │
│ ┌────────┐ ┌────────┐    │
│ │  41    │ │  17    │    │
│ │ viajes │ │ personas│   │
│ │externos│ │ distintas│  │
│ └────────┘ └────────┘    │
│ ┌────────┐ ┌────────┐    │
│ │   9    │ │  12    │    │
│ │replan. │ │completos│   │
│ └────────┘ └────────┘    │
│ Excluye equipo y datos   │
│ simulados.               │
└──────────────────────────┘
```
> Las cifras de arriba son **ilustrativas del diseño**; el panel real lee de la base de datos y **no** muestra números inventados (RF-23).

### Mis viajes (historial) y Cuenta
- **Lista** de tarjetas compactas: fecha, origen → destino, costo, estado (chip) · acciones "Repetir" / "Eliminar" (con confirmación).
- **Vacío:** silueta de montaña + *"Aún no tienes viajes. Planifica el primero."* + botón primario.
- **Cuenta:** perfil, consentimientos (interruptores con explicación), "Cerrar sesión"; invitados ven *"Guarda tu historial"* (no bloqueante).

---

## 10 bis. Especificación de desarrollo por pantalla

> **Cómo usar esta sección:** cada pantalla tiene su ficha con **objetivo, contenido (qué muestra), acciones, datos, estados, errores, eventos, accesibilidad, criterios de aceptación de UI y notas de desarrollo**. Los wireframes de la sección 10 son la referencia visual; **esta sección es el contrato de construcción**. Los nombres de proveedores y repositorios coinciden con [cyberon-arquitectura.md](cyberon-arquitectura.md) (sec. 5) y los códigos RF/RNF con [cyberon-requerimientos.md](cyberon-requerimientos.md).

### 10 bis.0 Mapa de navegación y reglas globales

**Rutas (`go_router`)**

| Ruta | Pantalla | Hito | ¿Requiere sesión? |
|---|---|---|---|
| `/` | S0 Bienvenida | MVP-0 | No |
| `/plan` | S1 Origen y destino | MVP-0 | No (invitado) |
| `/plan/conditions` | S2 Condiciones | MVP-0 | No |
| `/plan/results` | S3 Comparar | MVP-0 | No |
| `/plan/infeasible` | S4 Sin solución | MVP-0 | No |
| `/trip/:id/review` | S5 Revisión previa | MVP-0 | No (invitado con uid anónimo) |
| `/trip/:id/follow` | S6 Seguimiento | MVP-1 | No |
| `/trip/:id/changed` | S7 Algo cambió | MVP-1 | No |
| `/trip/:id/finish` | S8 Fin y feedback | MVP-1 | No |
| `/history` | H1 Mis viajes | MVP-0 | No (invitado ve los suyos locales/anónimos) |
| `/history/:id` | H2 Detalle de viaje | MVP-0 | No (solo el dueño) |
| `/auth/login` · `/auth/register` · `/auth/forgot` | A1 · A2 · A3 | MVP-0 | No |
| `/account` | A4 Cuenta | MVP-1 | No (adapta contenido a invitado/cuenta) |
| `/impact` | S9 Impacto (público) | MVP-1 | **No** (abierta, solo lectura) |
| `/demo` | Selector de modo demo | MVP-1 | No |
| *(modales)* | M1 paradero · M2 fuente del dato · M3 consentimiento · M4 confirmar borrado | MVP-0/1 | — |

> ✅ **Regla de oro:** **ninguna ruta del flujo principal exige sesión** (RF-33, RNF-17). Si no hay sesión, el arranque crea la identidad anónima en silencio.

**Grafo de navegación**

```
  S0 ──▶ S1 ──▶ S2 ──▶ S3 ──▶ S5 ──▶ S6 ──▶ S8 ──▶ H2 / S1
                  │      │            │
                  │      └──▶ S4 ──┐  └──▶ S7 ──▶ S3 (recalculado) / S4
                  └────────────────┘
  Pestañas inferiores:  Planificar(S1) · Mis viajes(H1) · Cuenta(A4)
  Acceso directo público: /impact (S9)   ·   /demo → S1 con viaje precargado
```

**Estructura base (shell)**
- **Móvil:** `Scaffold` + barra inferior de 3 pestañas (se **oculta** en S5–S8 para dar foco al viaje) + `DemoBadge` si el modo demo está activo.
- **Escritorio (≥ 900 px):** panel izquierdo de 380–420 px con el flujo y **mapa persistente a la derecha**; barra lateral compacta con las 3 secciones.
- **Mapa persistente:** un único widget de mapa compartido entre S1–S6 (no se recrea al navegar); lo controlan los proveedores de estado, no cada pantalla.
- **Pie discreto en pantallas con datos:** `Datos del 17/10/2026` (`dataVersion`) + atribución del mapa.

**Comportamientos globales (aplican a **todas** las pantallas)**

| Tema | Regla |
|---|---|
| **Atrás** | El gesto/botón atrás **vuelve al paso anterior conservando lo ingresado**. En S6 pide confirmación ("¿Salir del viaje? Podrás reanudarlo"). |
| **Estado de formulario** | `planFormProvider` conserva origen, destino y condiciones mientras dure la sesión; se restaura al volver. |
| **Sin conexión** | Franja superior ámbar *"Sin conexión: puedes planificar; guardaremos después"*. S1–S4 **siguen funcionando** (motor local). |
| **Errores** | Nunca texto técnico. Mensaje claro + acción ("Reintentar", "Volver"). Pantalla de error genérica con silueta de neblina. |
| **Carga** | Esqueletos (no ruedas a pantalla completa); progreso visible si > 300 ms. |
| **Eventos de uso** | Solo **5 eventos** se registran para tracción: `PLAN`, `SELECT`, `REPLAN`, `COMPLETE`, `FEEDBACK` (RF-22). El resto de interacciones **no** se escriben en la base (cuida cuotas). |
| **Textos** | Todos desde `core/i18n` (es-PE); **ningún texto incrustado** en widgets. |
| **Estilo** | Solo tokens de `core/ui`; ningún color, radio ni espacio "a mano". |
| **Accesibilidad** | `Semantics` en iconos/marcadores/chips; foco visible; respeta texto al 200 % y "reducir movimiento". |

**Plantilla de cada ficha**
`Ruta · Hito · Requerimientos` → **Objetivo** → **Contenido** (zona · elemento · dato · regla) → **Acciones** → **Datos** (lee / escribe) → **Estados** → **Validaciones y errores** → **Eventos** → **Criterios de aceptación de UI** → **Notas de desarrollo 🤖**.

---

### S0 · Bienvenida

**Ruta:** `/` · **Hito:** MVP-0 · **Requerimientos:** RF-33, RNF-03, RNF-17, RF-29

**Objetivo:** que el usuario (o el jurado) entre al flujo **en menos de 2 s y sin registrarse**, mientras la app carga el motor y los datos por detrás.

**Contenido**

| Zona | Elemento | Dato / fuente | Regla |
|---|---|---|---|
| Fondo | Degradado Noche → Oro + silueta de cordillera escalonada | Asset local | Estático si "reducir movimiento" |
| Centro | Logo + `cyberon` + tagline *"Llega con lo que tienes."* | Assets / `i18n` | Visible desde el **primer pintado** (HTML previo a Flutter) |
| Acción primaria | **[ Probar sin registrarme ]** | — | Crea identidad anónima y va a `/plan` |
| Acción secundaria | **[ Crear cuenta o entrar ]** | — | Va a `/auth/login` |
| Terciaria | *"Ver un viaje de ejemplo"* | `demoTrips[0]` | Activa modo demo y abre S3 con el viaje precargado |
| Pie | *"Hecho en Hack the Andes · Lima 2026"* · enlace *Privacidad* | `i18n` | Enlace abre la política (modal) |
| Indicador | Progreso discreto "Preparando datos…" | Estado de `dataset_repo` | Solo si la carga no ha terminado |

**Acciones:** *Probar sin registrarme* → `auth_repo.signInAnonymously()` → `/plan` · *Crear cuenta o entrar* → `/auth/login` · *Viaje de ejemplo* → modo demo → `/plan/results`.
**Datos:** lee `authStateProvider` (si ya hay sesión, **salta** a `/plan` tras ≤ 500 ms) y estado del dataset; escribe la identidad anónima.
**Estados:** *cargando dataset* (botones activos igual; el dataset termina de cargar detrás) · *error de dataset* (mensaje y "Reintentar"; no bloquea el modo demo) · *error de auth* (continúa en modo local y avisa en S1).
**Errores:** si la autenticación falla, la app **continúa como invitado local** (sin guardar historial) y lo informa de forma discreta (RNF-07).
**Eventos:** ninguno.
**Accesibilidad:** orden de foco: primaria → secundaria → terciaria; contraste del texto sobre el degradado ≥ 4,5:1 (usar capa semitransparente `primaryDark` bajo el texto).
**Criterios de aceptación de UI:**
- El primer pintado ocurre en **≤ 1,5 s** y los botones responden aunque el dataset no haya terminado.
- *Probar sin registrarme* funciona **sin red** (modo local).
- No se pide ningún permiso del navegador/dispositivo en esta pantalla.

> 🤖 **Notas:** precargar el dataset **después** del primer pintado (`dataset_repo.load()` sin `await` bloqueante). La redirección automática si hay sesión debe evitar parpadeo (decidir antes de pintar).

---

### S1 · Origen y destino

**Ruta:** `/plan` · **Hito:** MVP-0 · **Requerimientos:** RF-01, RF-02, RF-15, RF-20, RNF-14

**Objetivo:** fijar y **confirmar** origen y destino con el menor número de toques.

**Contenido**

| Zona | Elemento | Dato / fuente | Regla |
|---|---|---|---|
| Mapa (fondo) | Mapa del eje, **polígono de cobertura** tenue, paraderos (marcadores agrupados) | `dataset.coverage`, `dataset.stops` | Máx. 300 marcadores; agrupar a zoom bajo |
| Mapa | Pines **A** (origen) y **B** (destino) | `planFormProvider` | Arrastrables; al soltar, se reubican |
| Hoja inferior (peek) | Campo **Desde** (icono 📍) | Ubicación / búsqueda / toque en mapa | Por defecto "Mi ubicación" si hay permiso |
| Hoja inferior | Campo **Hasta** (icono 🏁) | Búsqueda local / toque en mapa | Vacío con *"¿A dónde vas?"* |
| Hoja | Botón **intercambiar ⇅** | — | Alterna origen y destino |
| Hoja | Lista de **sugerencias** | `dataset.landmarks` + paraderos que coinciden | Aparece desde 2 caracteres; **búsqueda local** (sin servicio remoto) |
| Hoja | Enlace **"Usar un viaje de ejemplo"** | `dataset.demoTrips` | Activa modo demo y precarga |
| Botón primario | **[ Siguiente ▸ ]** | — | Deshabilitado hasta tener A **y** B confirmados dentro de cobertura |
| Aviso contextual | Chip de advertencia | Reglas de RF-02 | *"Tu caminata inicial será larga (950 m)"* si el punto está lejos de paraderos |

**Acciones**
- Escribir → filtra sugerencias locales → tocar una → fija el punto y centra el mapa.
- **Tocar el mapa** → marcador provisional + mini-tarjeta con dirección aproximada y **[ Confirmar ]**.
- *Usar mi ubicación* → solicita permiso (con explicación previa, M3-guía) → fija A.
- *Siguiente* → valida cobertura → `/plan/conditions`.

**Datos:** lee `dataset_repo` (cobertura, paraderos, hitos), `location` (si hay permiso); escribe `planFormProvider.origin/destination`.
**Estados:** sin permiso de ubicación (A manual) · fuera de cobertura (bloquea con mensaje y resalta zona) · punto lejos de paradero (advertencia, permite seguir) · dataset cargando (mapa visible, búsqueda deshabilitada con *"Cargando lugares…"*).
**Validaciones y errores:**
- Fuera de polígono → *"Aún cubrimos el eje X–Y"* + zona resaltada (código `OUT_OF_COVERAGE`).
- A y B a < 100 m → *"Puedes ir caminando (X m)"* y no avanza al cálculo.
- Permiso denegado → sin error rojo: *"Elige tu punto de salida en el mapa"*.
**Eventos:** ninguno.
**Accesibilidad:** el mapa tiene alternativa: los campos de texto permiten fijar puntos sin usar el mapa; pines con `Semantics("Origen")`/`("Destino")`.
**Criterios de aceptación de UI:**
- Se puede fijar A y B y pasar a S2 en **≤ 4 toques** usando el viaje de ejemplo o "Mi ubicación" + una sugerencia.
- El mapa responde a ≥ 30 fps con los marcadores agrupados.
- En escritorio, la hoja se convierte en **panel izquierdo** y el mapa ocupa el resto.

> 🤖 **Notas:** no usar geocodificación remota con autocompletado (RF-01/ADR-11). Mantener la lista de hitos pequeña (≤ 200) y buscarla en memoria. El mapa persistente se monta aquí y se reutiliza en S2–S6.

---

### S2 · Condiciones del viaje

**Ruta:** `/plan/conditions` · **Hito:** MVP-0 · **Requerimientos:** RF-03 (RF-04 en Incremento B), RF-26, RNF-14, RNF-15

**Objetivo:** capturar las restricciones **de este viaje** (dinero, caminata, taxi, prioridad) en una sola pantalla, sin fricción.

**Contenido (de arriba abajo)**

| # | Elemento | Componente | Dato | Regla |
|---|---|---|---|---|
| 1 | Encabezado *"Tus condiciones"* + resumen *"Av. Brasil → Plaza Bolognesi"* | AppBar + texto | origen/destino | Toque en el resumen vuelve a S1 |
| 2 | **¿Cuánto puedes gastar?** | Campo de presupuesto (9.2) | `budgetCents` | Teclado numérico; **S/** fijo; atajos 6·8·10·15 |
| 3 | **¿Cuánto caminas seguido?** | Slider (9.3) | `maxContinuousWalkM` | Muestra `300 m ≈ 3 cuadras`; marcas 100/200/300/500/800 |
| 4 | **Caminata total máxima** | Slider (9.3) | `maxTotalWalkM` | Se muestra **plegada** bajo "Más opciones"; valor por defecto 800 m |
| 5 | **¿Aceptas un taxi corto?** | Toggle (9.4) | `allowTaxiBridge` | Ayuda: *"Solo lo usamos si te ahorra camino."* |
| 6 | **Prioridad** | Segmentado de 4 (9.4) | `priority` | Ahorro · Menos caminata · Tiempo · Menos transbordos |
| 7 | *(Inc. B)* **Cuéntalo con tus palabras** | Campo de texto + etiquetas | `raw_text` → `parsed` | Mostrar etiquetas **editables**; nunca calcula sin confirmar |
| 8 | **[ Ver opciones ]** | Botón primario | — | Habilitado si los valores son válidos |

**Valores por defecto:** presupuesto **S/ 8,00** · caminata seguida **300 m** · total **800 m** · taxi **sí** · prioridad **Equilibrada** (se aplican y se muestran; el usuario los reconoce y edita, no los inventa).
**Acciones:** cambiar cualquier control actualiza `planFormProvider` en vivo · *Ver opciones* → `PlannerGateway.plan()` → muestra progreso → S3 (con solución) o S4 (sin solución).
**Datos:** lee `planFormProvider`, `prefs_repo` (si hay preferencias recordadas, **precompleta** y muestra *"Recordamos tus preferencias"* con enlace "Borrar"); escribe `planFormProvider`.
**Estados:** calculando (botón con indicador, controles deshabilitados, texto *"Buscando tus opciones…"*) · error de cálculo (tarjeta con "Reintentar") · tiempo > 3 s (mensaje *"Tardamos un poco más…"* y opción de ver resultado parcial).
**Validaciones y errores:**
- Presupuesto ≤ 0 o > S/ 200 → *"Pon un monto entre S/ 1 y S/ 200"* (en línea).
- Caminata seguida > total → se **ajusta** la total y se avisa; no se pierde lo ingresado.
- Resultado `Infeasible` → navegar a S4 **sin** mostrar error.
**Eventos:** `PLAN` al recibir resultado (con `feasible: true|false`, sin datos personales).
**Accesibilidad:** cada control con etiqueta; el slider anuncia "300 metros, aproximadamente 3 cuadras"; teclado numérico automático.
**Criterios de aceptación de UI:**
- Con los valores por defecto, **un solo toque** ("Ver opciones") calcula.
- Todos los controles caben sin desplazamiento en 360×640 **salvo** "Más opciones" (plegado).
- El valor del slider es visible **sin tocarlo**.

> 🤖 **Notas:** `Money` en céntimos; el campo formatea `8,50` pero guarda `850`. El cálculo **no** bloquea la interfaz (búsqueda cooperativa en web). Llamar a `PlannerGateway` solo desde el *notifier*, nunca desde el widget.

---

### S3 · Comparar alternativas

**Ruta:** `/plan/results` · **Hito:** MVP-0 · **Requerimientos:** RF-07, RF-08, RF-09, RF-15, RF-21 (Inc. B), RNF-04

**Objetivo:** que el usuario **entienda en segundos** qué gana y qué sacrifica con cada opción y **elija una**.

**Contenido**

| Zona | Elemento | Dato | Regla |
|---|---|---|---|
| Mapa | Tramos de la alternativa seleccionada (estilos de 8) + A/B + paraderos de abordaje/descenso | `Alternative.legs` | Encuadre automático **con margen** para no quedar tapado por la hoja |
| Cabecera de hoja | Resumen *"3 opciones · S/ 8 · 300 m"* + **Ajustar condiciones ‹** | `planFormProvider` | *Ajustar* vuelve a S2 conservando valores |
| Lista | **Hasta 3** `AlternativeCard` (9.6) | `PlanResult.alternatives` | Orden por la prioridad elegida; **nunca** tarjetas duplicadas |
| Cada tarjeta | Etiqueta (Más barata / Menos caminata / Equilibrada), **costo + chip de certidumbre**, caminata total y seguida, tiempo, transbordos, resumen de tramos, línea de tradeoff | `Alternative` | Costo y caminata en tamaño grande |
| Tarjeta seleccionada | Borde 2 px + ✓ + `TradeoffCallout` (Ganas / Sacrificas) | `Alternative.tradeoffText` | Solo cifras del motor |
| Detalle (al tocar "Ver") | `LegTimeline` (9.7) con chips por tramo | `legs` | Hoja a altura completa |
| Avisos | Franja `warnC` si hay `warnings` (espera estimada, paradero inferido) | `Alternative.warnings` | **No se pueden ocultar** |
| *(Inc. B)* Alertas | Chip *"⚠ Alerta hoy en Corredor Azul"* con fuente | `alerts` | Se carga de forma asíncrona; no bloquea |
| Botón primario | **[ Elegir esta opción ]** | — | Actúa sobre la tarjeta seleccionada |

**Acciones**
- Tocar tarjeta → la **selecciona** y el mapa se actualiza (≤ 300 ms, sin recalcular).
- *Ver* (o tocar de nuevo) → detalle por tramos.
- Tocar un **paradero** en el mapa/timeline → M1 (hoja de paradero).
- Tocar un **chip de certidumbre** → M2 (fuente y fecha).
- *Elegir esta opción* → `trips_repo.create(status: ACTIVE, selected: snapshot, dataVersion)` → evento `SELECT` → S5.
- *Ajustar condiciones* → S2.
**Datos:** lee `planResultProvider`; escribe el viaje en Firestore (`users/{uid}/trips/{id}`) con **instantánea** de la alternativa.
**Estados:** 1, 2 o 3 alternativas (nunca se rellena) · una sola alternativa con etiqueta combinada ("Más barata y con menos caminata") · modo demo (insignia `DEMO`) · resultado `degraded` (chip *"Valores aproximados"*) · **guardado fallido** (se continúa con el viaje local y se avisa *"No guardamos tu historial ahora"*).
**Validaciones y errores:** si la selección falla al guardar, **no se bloquea** al usuario (RNF-07).
**Eventos:** `SELECT` (con `label`, `costCents`, `walkM`; sin coordenadas).
**Accesibilidad:** la **lista de tramos es la alternativa textual del mapa**; las tarjetas anuncian "Menos caminata, 8 soles con 50, estimado, 250 metros a pie".
**Criterios de aceptación de UI:**
- Cada importe visible tiene **chip de certidumbre** (prueba de widgets).
- Cambiar de alternativa actualiza el mapa en **≤ 300 ms**.
- Las 3 tarjetas se distinguen **sin depender del color**.
- En escritorio: tarjetas apiladas en el panel izquierdo; mapa a la derecha.

> 🤖 **Notas:** `AlternativeCard` es un widget **puro** (recibe `Alternative`, no consulta nada). Probarlo con *golden tests* en claro/oscuro. La instantánea guardada incluye `dataVersion` para que el historial no cambie (RF-34).

---

### S4 · Sin solución (relajación mínima)

**Ruta:** `/plan/infeasible` · **Hito:** MVP-0 · **Requerimientos:** RF-10

**Objetivo:** convertir un "no hay rutas" en una **decisión informada** del usuario, sin cambiar sus límites por él.

**Contenido**

| Zona | Elemento | Dato | Regla |
|---|---|---|---|
| Ilustración | Neblina sobre la cordillera | Asset | Tono amable, **no** rojo de error |
| Título | *"Con esos límites no encontramos un recorrido"* | `i18n` | — |
| Cuerpo | Frase con **las condiciones actuales** (*"Con S/ 4,00 y máx. 200 m…"*) | `planFormProvider` | Cifras del usuario |
| Opciones | **Hasta 2** botones de relajación (9.9) | `Infeasible.relaxations` | Cada botón dice **el cambio exacto** |
| Terciaria | *"Mantener mis límites y cambiar el viaje"* | — | Vuelve a S1 |
| Secundaria | *"Editar condiciones"* | — | Vuelve a S2 |

**Acciones**
- Pulsar una relajación → **solo esa** restricción cambia en `planFormProvider` → recalcula → S3.
- *Mantener mis límites* → S1; *Editar condiciones* → S2.
**Datos:** lee `Infeasible {blocking, relaxations}`; escribe `planFormProvider` **únicamente** al aceptar.
**Estados:** con 2 relajaciones · con 1 · **ninguna** (ni relajando hay solución → mensaje *"No hay recorrido con los datos actuales. Prueba con otro origen o destino"* y solo las acciones terciaria/secundaria).
**Validaciones y errores:** **prohibido** aplicar una relajación sin toque explícito.
**Eventos:** `PLAN` con `feasible:false` (ya registrado en S2).
**Criterios de aceptación de UI:**
- Los botones muestran **el delta con unidad** (`+S/ 2,50`, `+320 m`) y **dónde** (nombre del lugar).
- Si el usuario no toca nada, sus condiciones **no cambian**.
- Ninguna palabra técnica (restricción, infactible) aparece en pantalla.

> 🤖 **Notas:** reutilizar el mismo `planResultProvider`; al aceptar, actualizar el formulario y volver a llamar a `plan()` (no navegar manualmente a S3). Probar con el caso de oro "infactible con relajación esperada".

---

### S5 · Revisión antes de salir

**Ruta:** `/trip/:id/review` · **Hito:** MVP-0 · **Requerimientos:** RF-11, RF-09

**Objetivo:** que el usuario **sepa qué va a hacer, cuánto gastará y qué debe confirmar** antes de dar el primer paso.

**Contenido**

| Zona | Elemento | Dato | Regla |
|---|---|---|---|
| Cabecera | *"Gastarás ~S/ 8,50"* + chip `◐ Estimado` · *"Te quedarán ~S/ 0,50"* | `Alternative.totalCost`, `budget` | Si el saldo previsto < 20 % → tono `warnC` |
| Lista numerada | **Pasos** (1 🚶, 2 🚌, 3 🚖, 4 🚶) con nombre del lugar, distancia/tiempo y chip por tramo | `legs` | Una línea por paso |
| Aviso de taxi | Caja `taxiC`: *"Precio estimado. Confirma la cotización en tu app de taxi antes de subir."* + enlace **"Abrir mi app de taxi"** | `legs[type=TAXI]` | Solo si hay taxi; **no se contrata aquí** |
| Aviso de datos | Chip *"Datos del 17/10/2026"* + enlace *"¿Qué significa estimado?"* | `dataVersion` | Abre M2 |
| Botón primario | **[ Empezar viaje ]** | — | Cambia `status` a `ACTIVE` y va a S6 |
| Secundaria | *"Elegir otra opción"* | — | Vuelve a S3 |

**Acciones:** *Empezar viaje* → `trips_repo.update(status: ACTIVE, startedAt)` → S6 · *Otra opción* → S3 (el viaje **no** se descarta; se actualiza la selección) · *Abrir app de taxi* → intención externa (solo móvil; en web, copia el destino).
**Datos:** lee el viaje activo (`activeTripProvider`) y su instantánea; escribe `status`.
**Estados:** viaje no encontrado (mensaje y vuelta a S1) · sin red (continúa; se guarda local).
**Validaciones y errores:** si el usuario cierra la app aquí, el viaje queda `ACTIVE` y puede **reanudarse** desde H1.
**Eventos:** ninguno (el `SELECT` ya se registró).
**Criterios de aceptación de UI:**
- Se ven **todos** los pasos y el gasto total **sin desplazamiento** en 360×800 para viajes de ≤ 4 tramos.
- El aviso de taxi aparece **siempre** que exista un tramo `TAXI_BRIDGE`.
- La barra de pestañas está **oculta** en esta pantalla.

> 🤖 **Notas:** no ofrecer pagar ni reservar el taxi (alcance negativo). La intención externa a apps de taxi es opcional (🔻).

---

### S6 · Seguimiento del viaje

**Ruta:** `/trip/:id/follow` · **Hito:** MVP-1 · **Requerimientos:** RF-12, RF-13, RF-16 (Inc. A), RF-29, RNF-14, RNF-18

**Objetivo:** mostrar **una sola acción clara a la vez**, con el saldo visible, para guiarse con un vistazo.

**Contenido**

| Zona | Elemento | Dato | Regla |
|---|---|---|---|
| Mapa | Tramo actual resaltado (los demás atenuados), posición del usuario (si hay GPS), paradero objetivo | `legs`, `location` | Sigue al usuario si está activo "Seguirme" |
| Barra superior | Progreso `●──●○○` + *"Paso 1 de 4"* | `current_leg_index` | Texto además del gráfico |
| `NextStepCard` (9.10) | **Acción principal** en `title` (*"Camina 150 m hacia Av. Brasil"*) + subtítulo (tiempo, nombre del paradero, chip de certidumbre) | `legs[current]` | ≤ 100 caracteres |
| Saldo | `BalanceMeter` (9.11) | `budget − spent` | Cambia a tono de aviso < 20 % |
| Botón primario | **[ Listo, siguiente ]** | — | Avanza al siguiente tramo |
| Secundaria | **Algo cambió** | — | Va a S7 |
| Aviso de limitación | Franja `warnC` si el paso usa dato estimado/inferido | `warnings` | *"Este paradero es inferido (82 %). Si no ves gente esperando, pregunta."* |
| Ajustes rápidos | Interruptor *"Seguirme"* · *(Inc. A)* *"Compartir mi ubicación para mejorar el mapa"* (consentimiento aparte) | `consent` | **Apagado por defecto**; se explica en M3 |

**Acciones**
- *Listo, siguiente* → `current_leg_index + 1`; si el tramo implica pago, **pregunta** *"¿Pagaste S/ 2,50?"* con **[ Sí ] [ Otro monto ] [ No ]** → actualiza `spentCents`.
- *Algo cambió* → S7.
- Si hay GPS y el usuario llega a < 30 m del punto objetivo → sugerir avance (*"¿Ya llegaste?"*) **sin avanzar solo**.
- Programar la **notificación local** *"¿Cómo te fue?"* (+30 min del inicio, solo Android).
- Último paso → S8.
**Datos:** lee `activeTripProvider`, `location`; escribe `current_leg_index`, `spentCents` en el viaje.
**Estados:** sin GPS / permiso denegado (avance manual) · GPS con baja precisión (*"Ubicación aproximada"*) · sin red (continúa; sincroniza al volver) · viaje reanudado desde otro dispositivo (aviso breve).
**Validaciones y errores:** el saldo **no puede ser negativo** (si el gasto supera el presupuesto: aviso y saldo `S/ 0,00`, RNF-08); doble toque en *Listo* **no** avanza dos pasos (idempotencia, RNF-25).
**Eventos:** ninguno nuevo (el `REPLAN`/`COMPLETE` se registra en S7/S8).
**Accesibilidad:** el mapa es secundario: toda la información está en la tarjeta; anuncio por lector de pantalla al cambiar de paso; **botones ≥ 56 px** por uso en movimiento.
**Criterios de aceptación de UI:**
- Una **única acción** visible con texto ≤ 100 caracteres y un botón principal.
- El saldo siempre visible; la pantalla funciona **sin GPS**.
- Salir con *atrás* pide confirmación y el viaje es **reanudable**.

> 🤖 **Notas:** no enviar pings GPS en el MVP (Incremento A). Mantener la pantalla encendida solo si el usuario lo activa (consumo, RNF-18). El estado vive en `activeTripProvider` y se persiste tras cada cambio.

---

### S7 · Algo cambió (replanificar)

**Ruta:** `/trip/:id/changed` · **Hito:** MVP-1 · **Requerimientos:** RF-13, RNF-02, RNF-25

**Objetivo:** reportar el imprevisto con **pocos toques** y obtener un nuevo plan **con el dinero que queda**.

**Contenido**

| Zona | Elemento | Dato | Regla |
|---|---|---|---|
| Título | *"¿Qué pasó?"* | `i18n` | — |
| Opciones rápidas (chips grandes, una selección) | *Ya no quiero caminar tanto* · *El taxi cuesta más* · *Me bajé en otro punto* · *Gasté un monto* · *Tengo menos dinero* | — | Cada una muestra el **campo mínimo** que necesita |
| Campo condicional | **Monto gastado / nuevo costo del taxi / nuevo saldo** | `Money` | Prefijo **S/**, teclado numérico |
| Ubicación | *"Estoy aquí"* (GPS) o **elegir en el mapa** | `location` / mapa | Sin GPS → elegir en mapa |
| ¿A bordo? | Pregunta *"¿Estás dentro de un bus?"* (Sí/No) | `onBoardRoute?` | Si **Sí**, pide la línea (lista de la ruta actual) |
| Resumen | *"Te quedan S/ 6,50"* (calculado en vivo) | `budget − spent` | Debe ser visible **antes** de recalcular |
| Botón primario | **[ Recalcular desde aquí ]** | — | Llama a `replan()` |

**Acciones:** *Recalcular* → `PlannerGateway.replan(posición, saldo, aBordo?)` → progreso → S3 (con nuevas alternativas) o S4 (si no hay solución con ese saldo) → evento `REPLAN`; `replanCount + 1`.
**Datos:** lee `activeTripProvider`; escribe `spentCents`, `replanCount`, y una **nueva instantánea** al elegir.
**Estados:** calculando · sin solución con el saldo → S4 (con relajaciones) · error → *"No pudimos recalcular. Mantenemos tu plan actual"* (**se conserva el plan anterior**, RNF-02).
**Validaciones y errores:** monto > presupuesto → *"Es más de lo que tenías. ¿Seguro?"* (confirma y fija saldo en `S/ 0,00`); gasto **requiere confirmación** del usuario, nunca se descuenta solo (RF-13).
**Eventos:** `REPLAN`.
**Criterios de aceptación de UI:**
- Desde el toque en "Algo cambió" hasta ver el nuevo plan: **≤ 3 s en p95** (RNF-02), con indicador en **< 100 ms**.
- El saldo mostrado coincide **exactamente** con `presupuesto − gastado`.
- Doble toque en *Recalcular* **no** crea dos replanificaciones.

> 🤖 **Notas:** generar un `request_id` por intento y reutilizarlo en reintentos. Si el usuario está a bordo, el motor solo ofrece bajadas en paraderos de esa ruta.

---

### S8 · Fin del viaje y feedback

**Ruta:** `/trip/:id/finish` · **Hito:** MVP-1 · **Requerimientos:** RF-14, RF-33, RF-22

**Objetivo:** cerrar el viaje, recoger **feedback mínimo** y, si es invitado, invitar (sin bloquear) a guardar el historial.

**Contenido**

| Zona | Elemento | Dato | Regla |
|---|---|---|---|
| Ilustración | **Amanecer** (animación 800 ms; estático con "reducir movimiento") | Asset | — |
| Título | *"¡Llegaste!"* | `i18n` | — |
| Resumen | Gastado real vs. estimado, caminata realizada, replanificaciones | `trip` | Cifras reales del viaje |
| Pregunta 1 | *"¿Pudiste hacer el recorrido?"* → **Sí · Parcial · No** | `feedback.completed` | **Única obligatoria**; control grande |
| Pregunta 2 (opcional) | *"¿Coincidieron tarifas y paraderos?"* → campos opcionales | `fareMismatch`, `stopMismatch` | Texto ≤ 300 caracteres |
| Botón primario | **[ Enviar ]** | — | Guarda y cierra |
| Secundaria | *Omitir* | — | Cierra sin feedback |
| Invitación (solo invitado, tras el **primer** viaje completado) | Tarjeta *"Guarda tu historial (opcional)"* + **[ Crear cuenta ]** | `isAnonymous` | **Descartable**; no vuelve a aparecer en la sesión si se descarta |

**Acciones:** *Enviar* → `trips_repo.update(status: COMPLETED|ABANDONED, feedback)` → evento `COMPLETE` (+ `FEEDBACK` si hay respuesta) → vuelve a S1 o abre H2 · *Crear cuenta* → A2 (se **vincula** a la identidad anónima).
**Datos:** lee `trip`; escribe `status`, `completedAt`, `feedback`; actualiza contadores de `traction_users`.
**Estados:** viaje **abandonado** (se llegó aquí desde "Salir") → título *"Viaje terminado"* y misma pregunta · sin red (se guarda local, se sincroniza después).
**Validaciones y errores:** ninguna pregunta bloquea; si falla el guardado: *"No pudimos guardar. Reintentar"* y opción de continuar.
**Eventos:** `COMPLETE`, `FEEDBACK`.
**Accesibilidad:** la animación no transmite información; los botones Sí/Parcial/No tienen texto.
**Criterios de aceptación de UI:**
- Se puede **omitir** todo con un toque.
- El feedback **no cambia** datos oficiales (solo se guarda como reporte).
- La invitación a crear cuenta **no aparece** en modo demo.

> 🤖 **Notas:** cancelar la notificación local "¿Cómo te fue?" al completar el viaje. Los reportes de tarifa/paradero van a `reports` (solo creación).

---

### S9 · Impacto (tracción pública)

**Ruta:** `/impact` · **Hito:** MVP-1 · **Requerimientos:** RF-23, RF-22, RNF-13, RNF-29

**Objetivo:** mostrar al jurado **evidencia real de uso** leída de la base de datos, sin datos personales.

**Contenido**

| Zona | Elemento | Dato | Regla |
|---|---|---|---|
| Cabecera | Banda escalonada + *"Impacto de Cyberon"* + *"Datos hasta 09:40"* | hora de consulta | La hora es la **real** de la consulta |
| Mosaico `StatTile` ×4–6 | **Viajes planificados por personas externas** · **Personas distintas** · **Volvieron a usarla** · **Replanificaciones** · **Viajes completados** · **Comentarios recibidos** | agregados de `traction_users` | Cifra grande + etiqueta + variación opcional |
| Evidencia cualitativa | *"Entrevistas realizadas: N"* con 2–3 citas cortas (con permiso) | `docs/VALIDATION` o `config` | Solo si existen; **no inventar** |
| Criterio | Pie: *"Excluye al equipo y los datos simulados."* | `config.teamHashes` | Siempre visible |
| *(Inc. A)* Paraderos | *"Paraderos inferidos visibles: N"* | `inferred_stops` | Solo reales, **no** simulados |

**Acciones:** actualizar al entrar y cada ≤ 30 s (o botón *Actualizar*); tocar un tile abre una explicación del criterio de conteo.
**Datos:** lee **solo agregados** (`count()`/`sum()` sobre `traction_users`) y `config`; **no** lee documentos individuales.
**Estados:** **cero uso** → muestra `0` y *"Aún no hay uso externo"* (**nunca** cifras de relleno) · cargando (esqueleto) · error de lectura (*"No pudimos leer los datos. Reintentar"*).
**Validaciones y errores:** el panel **no es editable** por nadie desde la app.
**Eventos:** ninguno.
**Accesibilidad:** cada tile anuncia "41 viajes de personas externas"; las cifras no dependen del color.
**Criterios de aceptación de UI:**
- Todas las cifras provienen de la consulta; **ninguna** está escrita a mano.
- Excluye equipo y simulados; el criterio está escrito en pantalla.
- Se abre **sin sesión** y carga en ≤ 1 s para consultas agregadas (RNF-01).

> 🤖 **Notas:** las cifras del wireframe son ilustrativas. Si una agregación falla, mostrar el error, **no** un valor previo ni un número por defecto. Es la pantalla que el jurado puede abrir en una pestaña aparte.

---

### H1 · Mis viajes (historial)

**Ruta:** `/history` · **Hito:** MVP-0 · **Requerimientos:** RF-34, RF-33, RNF-29

**Objetivo:** ver, repetir y gestionar los viajes propios.

**Contenido**

| Zona | Elemento | Dato | Regla |
|---|---|---|---|
| Cabecera | *"Mis viajes"* + (si invitado) franja *"Guarda tu historial: crea una cuenta (opcional)"* | `isAnonymous` | Descartable |
| Lista | **Tarjeta compacta**: fecha/hora, *Origen → Destino*, costo (con chip), estado (chip: En curso · Completado · Abandonado), nº de replanificaciones | `trips` | Orden: más reciente primero; **20 por página** |
| Viaje **en curso** | Tarjeta destacada arriba con **[ Reanudar ]** | `status == ACTIVE` | Solo uno visible como "en curso" |
| Acciones por fila | **Repetir** · **Eliminar** (con confirmación M4) | — | Gesto de deslizar opcional (con alternativa visible) |
| Carga progresiva | *"Ver más"* al final | cursor | — |
| Vacío | Silueta de montaña + *"Aún no tienes viajes. Planifica el primero."* + **[ Planificar ]** | — | — |

**Acciones:** tocar fila → H2 · *Repetir* → precarga S1/S2 y **recalcula con el dataset actual** · *Eliminar* → M4 → `trips_repo.delete` · *Reanudar* → S6.
**Datos:** `trips_repo.list(uid, limit 20, cursor)`.
**Estados:** cargando (esqueleto de 3 tarjetas) · vacío · error (*"No pudimos cargar tus viajes. Reintentar"*) · sin red (muestra lo cacheado + aviso).
**Criterios de aceptación de UI:**
- La primera página carga en **p95 ≤ 1,5 s**.
- *Eliminar* **siempre** pide confirmación.
- Un invitado ve **solo sus viajes** (nunca los de otros).

> 🤖 **Notas:** paginar por `createdAt` descendente con cursor; no escuchar la colección completa en tiempo real (cuotas). El viaje activo se obtiene con una consulta aparte (`status == ACTIVE`, límite 1).

---

### H2 · Detalle de viaje

**Ruta:** `/history/:id` · **Hito:** MVP-0 · **Requerimientos:** RF-34, RF-09

**Objetivo:** revisar exactamente **lo que se eligió**, tal como estaba, y poder repetirlo.

**Contenido:** mapa con el recorrido · `LegTimeline` de la **instantánea** · costo estimado vs. gastado · caminata · replanificaciones · feedback dado · pie *"Calculado con datos del 17/10/2026"* · acciones **[ Repetir este viaje ]** (primaria) y **Eliminar** (peligro, con confirmación).
**Acciones:** *Repetir* → precarga origen, destino y condiciones → S2 → **recalcula con datos actuales** (no reutiliza el resultado viejo).
**Datos:** `trips_repo.get(uid, id)`; sin red usa caché.
**Estados:** no encontrado / sin permiso → mensaje genérico *"No encontramos ese viaje"* (no revela si existe, RNF-29) · cargando · error.
**Criterios de aceptación de UI:**
- El detalle **no cambia** aunque el dataset se actualice (usa la instantánea).
- Se distingue claramente **lo estimado** de **lo real** (chips).

> 🤖 **Notas:** reutilizar `LegTimeline` y los chips; el widget recibe una `Alternative` reconstruida desde la instantánea.

---

### A1 · Iniciar sesión · A2 · Registro · A3 · Recuperar contraseña

**Rutas:** `/auth/login` · `/auth/register` · `/auth/forgot` · **Hito:** MVP-0 · **Requerimientos:** RF-31, RF-32, RF-35, RNF-28

**Objetivo:** entrar o crear cuenta **sin perder el historial de invitado** y sin fricción.

**Contenido por pantalla**

| Pantalla | Campos y elementos | Reglas |
|---|---|---|
| **A1 Login** | Correo · Contraseña (con **mostrar/ocultar**) · **[ Entrar ]** (primaria) · *¿Olvidaste tu contraseña?* · *Crear cuenta* · *Continuar como invitado* | Error **genérico**: *"Correo o contraseña incorrectos"* (no revela si existe, RNF-28) |
| **A2 Registro** | Nombre (opcional) · Correo · Contraseña (**≥ 8**, con indicador) · **checkbox** *"Acepto la política de privacidad"* (**no premarcado**, con enlace) · **[ Crear cuenta ]** | Validación en línea; correo duplicado → *"Ese correo ya tiene cuenta. ¿Entrar o recuperar contraseña?"* |
| **A3 Recuperar** | Correo · **[ Enviar enlace ]** | Siempre responde *"Si existe una cuenta, te enviamos un enlace"* (no revela existencia) |

**Acciones**
- *Crear cuenta* desde un **invitado** → **vincula** la credencial a la identidad anónima (mismo `uid`): el historial **ya es de la cuenta**.
- *Entrar* a una cuenta **existente** estando como invitado con viajes → pregunta *"¿Quieres sumar tus viajes de invitado a esta cuenta?"* **[ Sí, sumarlos ] [ No ]** (migra en lote).
- Tras éxito → vuelve a la **pantalla de origen** (S8, S1 o H1).
- *Continuar como invitado* → `/plan`.
**Datos:** `auth_repo` (registro/login/vinculación); crea/actualiza `users/{uid}` con `privacyVersion`.
**Estados:** enviando (botón con indicador; campos deshabilitados) · bloqueo temporal tras **5 intentos** (*"Demasiados intentos. Intenta en unos minutos"*) · correo sin verificar (**no bloquea**; aviso suave) · almacenamiento bloqueado (incógnito): *"Tu sesión durará solo esta visita"*.
**Errores:** mensajes traducidos, sin códigos del proveedor; error de red → *"No pudimos conectar. Reintentar"*.
**Eventos:** ninguno.
**Accesibilidad:** etiquetas visibles (no solo *placeholder*), errores asociados al campo, teclado adecuado (`emailAddress`), autocompletado del gestor de contraseñas habilitado.
**Criterios de aceptación de UI:**
- Registro completado en **p95 ≤ 3 s** y el usuario queda con sesión iniciada.
- **Nunca** se almacena ni registra la contraseña en la app.
- El flujo "invitado → cuenta" **conserva** el historial (prueba obligatoria).

> 🤖 **Notas:** la política de contraseña es propia (≥ 8) aunque el proveedor admita menos. Manejar el caso "credencial ya en uso" (cuenta existente) con el flujo de **migración**. Probar en incógnito.

---

### A4 · Cuenta

**Ruta:** `/account` · **Hito:** MVP-1 · **Requerimientos:** RF-29, RF-32, RF-35, RF-26

**Objetivo:** gestionar identidad, consentimientos y datos, con el mínimo de opciones.

**Contenido (adapta según *invitado* o *cuenta*)**

| Sección | Invitado | Con cuenta |
|---|---|---|
| Cabecera | *"Estás como invitado"* + **[ Crear cuenta ]** | Nombre/correo + estado de verificación |
| **Privacidad** | Interruptores: *"Usar mi ubicación para guiarme"* · *(Inc. A)* *"Compartir mi ubicación anónima para mejorar el mapa"* (cada uno con explicación) | Igual, **sincronizado entre dispositivos** |
| **Preferencias** (Inc. B) | — | Lista de lo recordado + **Borrar** |
| **Impacto** | Enlace a `/impact` | Igual |
| **Ayuda** | *Cómo leer "Estimado / Confirmado / Inferido"* · Política de privacidad · Limitaciones (sin promesas de accesibilidad) | Igual |
| **Sesión** | — | **[ Cerrar sesión ]** |
| **Datos** | *"Borrar mis datos de invitado"* (con confirmación) | *"Eliminar mi cuenta"* (Inc. C; en MVP, instrucciones) |
| Pie | Versión de la app · `dataVersion` | Igual |

**Acciones:** cambiar un interruptor → guarda en `users.consent` (cuenta) o local (invitado) y **surte efecto de inmediato**; *Cerrar sesión* → limpia datos locales sensibles y vuelve a S0.
**Estados:** cargando perfil · error al guardar (*"No pudimos guardar tu cambio"* y el interruptor vuelve a su valor).
**Criterios de aceptación de UI:**
- **Revocar** el compartir de ubicación lo detiene **inmediatamente**.
- Los dos consentimientos son **independientes** y están **apagados por defecto** el de trazas.
- Ninguna acción destructiva sin confirmación (M4).

> 🤖 **Notas:** la eliminación completa de cuenta (cascada) es **Incremento C**; en el MVP la opción solo muestra el procedimiento (qué se borrará y cómo solicitarlo).

---

### Modales y hojas reutilizables

| Código | Nombre | Cuándo aparece | Contenido | Reglas |
|---|---|---|---|---|
| **M1** | Hoja de paradero | Tocar un paradero (mapa o timeline) | Nombre, **tipo (chip)**, rutas que lo sirven, fuente y fecha; si es inferido: *"Usuarios con GPS esperaron aquí"* + **[ No subí aquí ]** (RF-36) | Altura media; cerrar al deslizar |
| **M2** | Fuente del dato | Tocar un chip de certidumbre | Qué significa (*Confirmado / Estimado / Inferido / Simulado*), **fuente, fecha** y por qué | Si no hay fuente → explica que es estimado |
| **M3** | Consentimiento | Antes de pedir permiso de ubicación; antes de compartir trazas | Para qué se usa, qué **no** se hace, cómo revocar | **Dos variantes** (guiar / mejorar el mapa); botones *Permitir* / *Ahora no* |
| **M4** | Confirmar acción destructiva | Eliminar viaje / borrar datos | Qué se pierde, **[ Eliminar ]** (peligro) y *Cancelar* | Cancelar es la acción por defecto |

---

### 10 bis.1 Modo demo (transversal)

- **Activación:** desde S0 (*Ver un viaje de ejemplo*), S1 (*Usar un viaje de ejemplo*) o `/demo`.
- **Efecto:** carga un `demoTrip` (origen, destino, condiciones) y **fija una posición simulada** tocando el mapa si hace falta; **no** solicita permisos de ubicación.
- **Señales visibles:** insignia `DEMO` en una esquina (no tapa controles); los datos simulados llevan `SIMULADO`.
- **Reglas:** resultados **idénticos en cada ejecución** (determinismo); **no cuenta como tracción**; no muestra la invitación a crear cuenta; el **viaje ensayado** completa el flujo S3→S7 en ≤ 2 min.
- **Salida:** *Salir del modo demo* en `/account` y en la insignia.

> 🤖 **El modo demo es lo que el jurado verá primero.** Probarlo en **incógnito, sin sesión, sin GPS y desde otro equipo** antes de entregar.

---

### 10 bis.2 Orden de construcción de pantallas y definición de "hecho"

| Orden | Pantalla(s) | Depende de | Hito |
|---|---|---|---|
| 1 | **Shell + tema + navegación** (rutas, pestañas, layout de escritorio) | Tokens | MVP-0 |
| 2 | **S1** Origen y destino (mapa persistente, búsqueda local) | Dataset | MVP-0 |
| 3 | **S2** Condiciones | Tokens, componentes de formulario | MVP-0 |
| 4 | **S3** Comparar (+ `AlternativeCard`, `LegTimeline`, `CertaintyChip`) | Motor (o *fake*) | MVP-0 |
| 5 | **S4** Sin solución | Motor | MVP-0 |
| 6 | **S5** Revisión + creación del viaje | `trips_repo` | MVP-0 |
| 7 | **A1–A3** Autenticación + invitado→cuenta | `auth_repo` | MVP-0 |
| 8 | **H1–H2** Historial | `trips_repo` | MVP-0 |
| 9 | 🚩 **Despliegue web público + prueba en incógnito** | Todo lo anterior | **Corte H+10** |
| 10 | **S6, S7, S8** Seguimiento, replanificar, fin | `replan`, `activeTripProvider` | MVP-1 |
| 11 | **Modo demo + S0** | `demoTrips` | MVP-1 |
| 12 | **S9** Impacto + **A4** Cuenta + M3 | `traction_users`, reglas | MVP-1 |
| 13 | 🚩 **Estados, pulido, accesibilidad, slides** | — | **Corte H+13** |

**Definición de "pantalla hecha"** (todas deben ser verdaderas):
- [ ] Usa **solo tokens** y componentes del sistema (sin estilos sueltos).
- [ ] Tiene diseñados y probados sus **estados** (carga, vacío, error, sin conexión, degradado).
- [ ] Cumple **contraste, objetivos táctiles ≥ 48 px, foco y `Semantics`**.
- [ ] Funciona en **360×800, 1366×768 y 1920×1080** sin desbordes.
- [ ] Todo texto viene de `i18n` (es-PE) y **sin jerga**.
- [ ] Cumple sus **criterios de aceptación de UI** (arriba).
- [ ] Tiene **prueba de widgets** (y *golden* si es un componente visual clave).
- [ ] Funciona **sin registrarse**, en **incógnito** y, si aplica, **sin GPS**.
- [ ] Los **eventos de tracción** (si los tiene) se registran **una sola vez** por acción.

---

## 11. Estados de la interfaz (ninguna pantalla en blanco)

| Estado | Tratamiento visual | Texto de ejemplo |
|---|---|---|
| **Cargando (< 1 s)** | Sin cambio; solo indicador en el botón | — |
| **Cargando (1–3 s)** | Esqueleto de tarjetas con **brillo suave**; progreso del cálculo | "Buscando tus opciones…" |
| **Cargando largo (> 3 s)** | Mensaje + opción de continuar con resultado parcial | "Tardamos un poco más de lo normal…" |
| **Vacío** | Ilustración de montaña + acción | "Aún no tienes viajes" |
| **Error recuperable** | Tarjeta con ícono ▲ y **"Reintentar"** | "No pudimos guardar tu viaje. Reintentar" |
| **Sin conexión** | Franja superior ámbar, la app **sigue funcionando** | "Sin conexión: puedes planificar; guardaremos después" |
| **Degradado** | Chip discreto "Valores aproximados" | "Usamos una estimación local" |
| **Fuera de cobertura** | Zona cubierta resaltada en el mapa | "Aún cubrimos el eje X–Y" |
| **Éxito** | Amanecer + texto breve | "¡Llegaste!" |

---

## 12. Movimiento

**Propósito:** orientar y dar feedback, nunca decorar. **Breve y suave.**

| Interacción | Duración | Curva |
|---|---|---|
| Pulsar botón | 100 ms | `easeOut` |
| Aparición de tarjetas | 200 ms (escalonada 40 ms entre tarjetas) | `easeOutCubic` |
| Hoja inferior | 280 ms | `easeInOutCubic` |
| Cambio de alternativa en mapa | 300 ms (la línea se "dibuja") | `easeInOut` |
| Barra de saldo | 400 ms | `easeOut` |
| **Amanecer (fin de viaje)** | 800 ms | `easeInOut` |

- **Respetar "reducir movimiento":** si está activo, se eliminan pulsos, escalonados y el amanecer animado (queda estático).
- **Nada** de parpadeos ni animaciones infinitas con información crítica.
- Mientras el motor calcula en **web** (sin hilos), la animación debe seguir fluida: por eso la búsqueda es cooperativa (ver arquitectura, sec. 6.5).

---

## 13. Voz y microtextos (es-PE)

**Tono:** cercano, claro, respetuoso; **tuteo**; frases cortas; **verbos de acción**; cifras concretas (soles, metros, cuadras). Sin jerga técnica (nada de "Pareto", "arista", "DBSCAN").

| Situación | ✅ Sí | ❌ No |
|---|---|---|
| Botón principal | "Ver opciones" | "Ejecutar consulta" |
| Sin solución | "Con esos límites no encontramos un recorrido. Puedes…" | "Error 404: sin rutas" |
| Estimado | "Estimado: puede variar" | "Valor heurístico" |
| Inferido | "Usuarios con GPS esperaron aquí (82 %)" | "Cluster DBSCAN confianza 0.82" |
| Taxi | "Precio estimado. Confirma en tu app de taxi" | "Tarifa" |
| Invitar a registrarse | "Guarda tu historial (opcional)" | "Regístrate para continuar" |
| Error de red | "No pudimos conectar. Reintentar" | "Network exception" |
| Permiso GPS | "Usamos tu ubicación solo para guiarte. ¿Permitir?" | "Se requieren permisos" |

**Formatos:** `S/ 8,50` · `850 m` · `1,4 km` · `38 min` · fechas `17/10/2026` · hora 24 h · "cuadras" siempre como **equivalencia aproximada** (≈ 100 m).

---

## 14. Accesibilidad (checklist verificable, RNF-16)

- [ ] 🧮 Contraste de texto ≥ **4,5:1** en claro y oscuro (verificado en secs. 4.2 y 4.3).
- [ ] Gráficos y bordes de componentes ≥ **3:1**.
- [ ] **Nada depende solo del color**: forma + icono + texto (4.4).
- [ ] Objetivos táctiles ≥ **48 × 48**, separación ≥ 8.
- [ ] Texto ampliable al **200 %** sin pérdida de contenido.
- [ ] Etiquetas accesibles (`Semantics`) en iconos, marcadores y chips; el mapa tiene **alternativa textual** (la lista de tramos).
- [ ] Orden de foco lógico; **foco visible** (anillo `primary` 2 px) en web.
- [ ] Respeto de **"reducir movimiento"** y de modo oscuro del sistema.
- [ ] Mensajes de error asociados al campo y legibles por lector de pantalla.
- [ ] **Sin afirmar accesibilidad física** de recorridos (silla de ruedas, escaleras): nota visible de limitación.

---

## 15. Responsive: del teléfono al computador del jurado

> El jurado abre la web en una **PC de escritorio** (R3). La interfaz **no** debe verse como un teléfono estirado ni como un marco de teléfono.

| Ancho | Layout |
|---|---|
| **< 600 px** (móvil) | Una columna: mapa + **hoja inferior**; navegación inferior |
| **600–900 px** (tablet) | Mapa ancho + hoja con ancho máx. 480 centrada abajo |
| **≥ 900 px** (escritorio) | **Dos paneles:** columna izquierda de **380–420 px** con el flujo (S1→S8) y **mapa a la derecha** a pantalla completa; navegación en barra lateral compacta |

- En escritorio las **tarjetas de alternativas** se apilan en el panel izquierdo y el mapa muestra la seleccionada; el panel de tracción usa mosaico de **4 columnas**.
- Contenedor de contenido **máx. 1200 px**; márgenes 24–32.
- **Modo demo visible** en la esquina (insignia `DEMO`), sin tapar controles.
- 🎯 Probar en **1366×768** (laptop común) y **1920×1080**, además de 360×800.

---

## 16. Diseño del pitch y las slides (coherencia de marca)

**Plantilla de slides:** fondo `bg` o `primaryDark` (portada y cierre), títulos Sora, banda escalonada al 8 %, acentos `accent`. **Máximo 6 ideas por slide, 1 por pantalla de demo.**

| Min | Slide | Contenido |
|---|---|---|
| 0:00–0:30 | **1 · Problema** | Valeria con S/ 8 y mochila: el dilema "caminar 600 m o taxi de S/ 25" + un dato real de entrevistas |
| (transición) | **2 · Solución** | Una frase + captura de S3 (tres tarjetas) |
| 0:30–2:30 | **Demo en vivo** | Desde la URL pública (modo demo) — **no** slides |
| 2:30–3:00 | **3 · Cómo está hecho** | Diagrama de la arquitectura (una imagen), 3 decisiones técnicas |
| Preguntas | **4 · Límites y siguiente paso** | Qué quedó fuera, honestidad de datos, alcance futuro |
| Apoyo | **5 · Impacto** | Captura del panel de tracción (datos reales) |

> 🎯 La **demo** es lo que más pesa; las slides son apoyo. Mantener la **misma paleta, tipografía y chips** que la app para que todo se perciba como un solo producto.

---

## 17. Implementación en Flutter

### 17.1 Estructura
```
lib/core/ui/
├─ tokens/        # color.dart · spacing.dart · radius.dart · motion.dart · typography.dart
├─ theme/         # app_theme.dart (claro/oscuro) · cyberon_colors.dart (ThemeExtension)
├─ components/    # certainty_chip · alternative_card · leg_timeline · tradeoff_callout
│                 # infeasible_card · next_step_card · balance_meter · stat_tile · stop_marker_sheet
├─ map/           # map_style.dart (colores, trazos, marcadores)
└─ assets/        # fuentes (Sora, Inter), logo, siluetas, patrón escalonado
```

### 17.2 Tokens y tema (referencia; ⚠️ verificar API al implementar)

```dart
// tokens/color.dart
abstract final class Palette {
  // Claro
  static const bg = Color(0xFFFBF7F0), surface = Color(0xFFFFFFFF), surfaceAlt = Color(0xFFF1EADF);
  static const ink = Color(0xFF1B2433), inkMuted = Color(0xFF586274);
  static const primary = Color(0xFF1E4D7B), primaryDark = Color(0xFF163A5C);
  static const accent = Color(0xFFE0A526), taxi = Color(0xFFB8452E);
  static const ok = Color(0xFF2E7D5B), info = Color(0xFF6B3FA0), warn = Color(0xFFB7791F), error = Color(0xFFB3261E);
  // Oscuro
  static const dBg = Color(0xFF0F1724), dSurface = Color(0xFF182234), dSurfaceAlt = Color(0xFF223049);
  static const dInk = Color(0xFFEDEAE3), dInkMuted = Color(0xFFA8B0BF);
  static const dPrimary = Color(0xFF8DB9E8), dAccent = Color(0xFFF0BE4A), dTaxi = Color(0xFFE58A73);
}

// theme/cyberon_colors.dart  — colores semánticos propios (no existen en Material)
@immutable
class CyberonColors extends ThemeExtension<CyberonColors> {
  const CyberonColors({
    required this.confirmed, required this.confirmedBg,
    required this.estimated, required this.estimatedBg,
    required this.inferred,  required this.inferredBg,
    required this.simulatedBg, required this.simulatedFg,
    required this.walk, required this.ride, required this.taxiBridge,
  });
  final Color confirmed, confirmedBg, estimated, estimatedBg, inferred, inferredBg;
  final Color simulatedBg, simulatedFg, walk, ride, taxiBridge;
  // copyWith / lerp: implementar (obligatorio en ThemeExtension)
  @override CyberonColors copyWith({/*...*/}) => this;
  @override CyberonColors lerp(ThemeExtension<CyberonColors>? other, double t) => this;

  static const light = CyberonColors(
    confirmed: Color(0xFF1F5E43), confirmedBg: Color(0xFFDDF1E7),
    estimated: Color(0xFF7A4A00), estimatedBg: Color(0xFFFCEBC8),
    inferred:  Color(0xFF4F2A85), inferredBg:  Color(0xFFEBE1F7),
    simulatedBg: Color(0xFFE8E6E1), simulatedFg: Color(0xFF3F4857),
    walk: Color(0xFF6B7280), ride: Palette.primary, taxiBridge: Palette.taxi,
  );
}

// theme/app_theme.dart
ThemeData buildLightTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: Palette.primary, onPrimary: Colors.white,
    secondary: Palette.accent, onSecondary: Palette.ink,
    error: Palette.error, onError: Colors.white,
    surface: Palette.surface, onSurface: Palette.ink,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.bg,
    extensions: const [CyberonColors.light],
    // textTheme: Sora (display/headline/title) + Inter (body/label), fuentes empaquetadas como assets
    // filledButtonTheme: alto 52, radio 12 · inputDecorationTheme: radio 12, relleno surfaceAlt
    // cardTheme: radio 16, sin sombra, borde 1 px · chipTheme: radio 8
  );
}
```

- **Fuentes como *assets*** declaradas en `pubspec.yaml` (no `google_fonts` en ejecución) → arranque sin red.
- **Accesibilidad:** envolver iconos y marcadores con `Semantics(label: …)`; `MediaQuery.disableAnimations` para "reducir movimiento"; `textScaler` respetado.
- **Responsive:** `LayoutBuilder` con puntos de quiebre 600 y 900; un solo `PlanFlow` que cambia de **hoja inferior** a **panel lateral**.
- **Modo oscuro:** `ThemeMode.system` por defecto; mapa con estilo oscuro cuando corresponda.

### 17.3 Construir primero (orden de componentes)
1. Tokens + tema claro/oscuro. 2. `CertaintyChip`. 3. `AlternativeCard`. 4. `LegTimeline`. 5. Campo de presupuesto, slider de caminata, toggle y segmentado (S2). 6. `InfeasibleCard`. 7. `NextStepCard` + `BalanceMeter`. 8. `StatTile` (S9). 9. Estados (esqueleto, vacío, error). 10. Pulido: movimiento, ilustraciones, splash.

---

## 18. Lista de verificación de calidad visual (antes de entregar)

- [ ] Cada concepto usa **siempre** el mismo color + forma + icono (4.4).
- [ ] Una sola acción primaria por pantalla.
- [ ] Ningún importe ni paradero sin **chip de certidumbre**; lo simulado, rotulado.
- [ ] Contrastes verificados en claro **y** oscuro (14).
- [ ] 360×800, 1366×768 y 1920×1080 sin desbordes ni scroll horizontal.
- [ ] Texto al 200 % sin romperse.
- [ ] Estados de carga, vacío, error, sin conexión y degradado **diseñados y probados**.
- [ ] El mapa se entiende **sin color** (patrones de trazo y formas de marcador).
- [ ] Fuentes empaquetadas; sin parpadeo de texto; funciona en **incógnito y sin red** (tras la carga inicial).
- [ ] "Reducir movimiento" respetado.
- [ ] Tono de microtextos coherente (es-PE, tuteo, sin jerga).
- [ ] Slides con la misma paleta y tipografía que la app.
- [ ] Una persona ajena entiende "Estimado / Confirmado / Inferido" **sin explicación** (RNF-15).

---

## 19. Notas para el agente constructor

> 🤖 **Léelas antes de escribir pantallas.**

1. **Tokens primero.** Nunca escribas un color, radio o espacio "a mano" en un widget: todo viene de `Palette`, `CyberonColors` y los tokens de espaciado.
2. **El chip de certidumbre es obligatorio** en todo importe y paradero (RF-09). Una prueba de widgets debe fallar si falta.
3. **No uses solo color** para transmitir estado: forma + icono + texto siempre.
4. **No inventes cifras en pantallas de ejemplo**: los números de este documento son ilustrativos; la app lee datos reales.
5. **Fuentes y logo empaquetados** como *assets*; sin dependencias de red para pintar la primera pantalla.
6. **Una sola acción primaria** por pantalla; el resto, secundarias o terciarias.
7. **Diseña los estados** (carga, vacío, error, sin conexión, degradado) **antes** de pulir lo bonito.
8. **Responsive real**: en escritorio, dos paneles con el mapa a la derecha; probar en 1366×768.
9. **Armonía antes que cantidad**: si dudas entre añadir un adorno o dejar aire, deja aire. El motivo escalonado va siempre **sutil**.
10. **Recorte (🔻):** si el tiempo aprieta, se recortan en este orden: ilustraciones y animación del amanecer → estilo oscuro del mapa → motivo escalonado → modo oscuro completo. **Nunca** se recortan: contraste, chips de certidumbre, estados de error/vacío ni el layout de escritorio.

---

*Fin del documento. Contrastes calculados el 17/10/2026 con la fórmula de luminancia relativa de WCAG; las capturas y cifras de las pantallas son ilustrativas del diseño, no datos reales.*
