# Cyberon — Documento maestro de contexto, problema, solución y plan de construcción

**Proyecto:** Cyberon · **Evento:** Hack the Andes (Lima, 17–18 oct 2026) · **Track:** `transport` (Movilidad y Transporte)
**Versión:** 2 · **Fuente base:** chat compartido de Gemini del 17/10/2026 (leído completo) **+** lectura directa del deck oficial (`/deck/onboarding`) y de la guía (`/guide`) **+** análisis crítico propio (Claude).

---

## 0. Cómo usar este documento (leer primero)

Este archivo es el **traspaso completo** para quien (persona o agente) vaya a construir el proyecto. Tiene tres tipos de contenido, marcados así:

- **Contenido de Gemini** (ideas, fórmulas, esquema): tal como se conversó, salvo donde lo corrijo.
- **✅ Verificado:** confirmado por mí leyendo el deck/guía oficiales el 17/10/2026.
- **⚠️ No verificado:** afirmación de Gemini (o mía) que debe comprobarse antes de depender de ella.
- **🤖 NOTA PARA EL AGENTE CONSTRUCTOR:** instrucción o advertencia concreta para quien programe. **Si eres el agente constructor, lee todas las notas 🤖 y la sección 15 antes de escribir código.**

Mapa del documento:

| Sec. | Contenido |
|---|---|
| 1 | Hechos verificados del evento (reglas, fechas, agenda, premios) |
| 2 | ⚠️ **Conflicto entre las dos rúbricas oficiales** (crítico) |
| 3 | Historia de decisiones: cómo llegamos a Cyberon (incluye el documento del compañero íntegro) |
| 4 | **El problema en profundidad** |
| 5 | **La solución en profundidad** (producto, pantallas, algoritmos, API) |
| 6 | Datos: de dónde sale cada dato y qué falta |
| 7 | **Sponsors y sus herramientas** (verificado + cómo usarlas + prioridad) |
| 8 | Arquitectura, stack, repo, base de datos |
| 9 | App móvil vs. URL pública (la tensión con las reglas) |
| 10 | Respuesta a "¿cómo entra Zavu / WhatsApp?" |
| 11 | Plan de tracción (evidencia externa) |
| 12 | Plan de trabajo por horas y checklist de entrega |
| 13 | Guion de demo (3 min) y preguntas probables del jurado |
| 14 | Errores/exageraciones de Gemini detectados |
| 15 | **Notas críticas y reglas duras para el agente constructor** |
| 16 | Decisiones pendientes y próximos pasos |

---

## 1. Hechos verificados del evento

> ✅ Todo lo de esta sección lo leí directamente en `hacktheandes.com/deck/onboarding` y `hacktheandes.com/guide` el 17/10/2026.

### 1.1 Datos generales
- **Evento:** Hack the Andes, Lima, 17–18 de octubre de 2026. **100 participantes, 30 horas, 4 tracks.** Sponsor principal: **Chofex**. Venue: pisos 3 y 4 (auditorio y salones).
- **Equipos:** de 1 a 4 personas. Hasta **12 equipos por track**, **36 equipos activos** en total.
- **Canal oficial:** Discord (`hacktheandes.com/discord`).
- **Código de conducta:** respeto, pedir permiso antes de grabar, reportar lo inseguro.

### 1.2 Agenda
**Sábado 17:** 09:00 bienvenida · 10:15 formación de equipos y elección de track · 11:15–14:00 building · 14:00 almuerzo · 15:00–19:00 building · 19:00 cena · 20:00–00:00 building.
**Domingo 18:** 00:00–09:00 dormir o seguir construyendo · **09:00 HORA LÍMITE (`andes project submit`)** · 09:30 mensaje de cierre · **10:00–13:30 demos en vivo (3 min + 2 de preguntas)** · 13:30 ganadores · hasta 14:00 networking.

### 1.3 Los 4 tracks
| Track | Alcance (deck) |
|---|---|
| `environmental` Clima y Territorio | Agua, heladas, huaicos y lluvias; agricultura y alertas de plagas; información para productores y comunidades |
| **`transport` Movilidad y Transporte** | **Transporte público en Lima: rutas y tiempos; pasajeros y conectividad entre localidades en regiones; transporte de carga y distribución en regiones** |
| `education` Educación Escolar | Herramientas docentes y aprendizaje; prevención de la deserción escolar; infraestructura y servicios escolares |
| `security` Seguridad | Extorsión a comercios y transportistas; estafas, suplantación y voces clonadas; desinformación y noticias falsas |

Regla general: **"Software, APIs y datos abiertos; sin hardware especial."** La guía añade para transport: "transporte público dentro de Lima, con rutas, conexiones, tiempos **y accesibilidad**".

### 1.4 Entrega (`andes project submit`)
Cuatro datos obligatorios: **(1)** URL del despliegue funcionando, **(2)** URL de la presentación (Canva, Google Slides o hecha con código), **(3)** URL del repositorio de GitHub, **(4)** descripción en Markdown (problema, para quién, cómo funciona, limitaciones). Se puede usar `--file ./proyecto.md`.

- **No cuenta:** correr en localhost; solo slides o un pitch; mockups o video grabado.
- "**Se evalúa una demo en vivo desde tus links.**" La organización abre los enlaces **desde su propio equipo** (no conectas tu laptop). Hay que comprobar que todo funcione en **ventana privada, sin sesión iniciada, sin permisos pendientes y sin archivos locales**.
- Se puede entregar pronto y **corregir después**; cualquier integrante puede editar la entrega. Pero: cuando la organización abre la evaluación **se guarda una copia** de entregas, enlaces y bitácoras para el jurado; los cambios posteriores no actualizan esa copia.
- **Las descripciones y avances son contenido que se hará público** (galería). Excluir claves, tokens, **datos personales de usuarios** y material sin permiso.

### 1.5 Bitácora (`andes project update`)
Publicar un avance tras una decisión importante, prueba con usuarios, demo funcional o bloqueo. Explicar qué cambió, por qué y el siguiente paso. Usa solo hechos verificables, sin secretos. **Mentores y jurado la ven.** (`--message "..."` o `--file ./avance.md`; `andes project updates` para listarla.)

### 1.6 Formato de la demo
0:00–0:30 **Problema** (para quién y qué le resuelves) · 0:30–2:30 **Demo en vivo desde la URL pública** · 2:30–3:00 **Cómo está hecho** (arquitectura y decisiones) · 3:00–5:00 **Preguntas** (2 min del jurado). **Al minuto 3 se corta la demo.**

### 1.7 Premios
1.er lugar **S/ 6.000** (Chofex) · 2.º lugar **S/ 2.000** (Chofex), además viaje a Chofex HQ y mentorías de StartUPC. Planes extendidos de Qatom y AtomicMemory para los ganadores (1.er puesto: Qatom 12 meses Plan Max; AtomicMemory 1 año Plan Max).

### 1.8 CLI (`andes`, alias `chofex`)
`andes update` (correrlo antes de empezar) · `andes login` · `andes confirm` · `andes checkin` / `--status` · **`andes credits`** (muestra beneficios, códigos, enlaces e instrucciones de canje; **no se canjean solos**; **no publicar los códigos**) · `andes team` / `team create` / `team invite` / `team tracks` / **`andes team track --track transport`** · `andes project` / `project update` / `project updates` / `project submit`. Para agentes: `andes --output json ...`.

> 🤖 **NOTA PARA EL AGENTE CONSTRUCTOR:** el CLI está pensado para agentes (`--output json`, `--yes`). Puedes ejecutar `andes --output json project update --message "..."` para publicar la bitácora, **solo con hechos que puedas verificar**. Nunca incluyas códigos de `andes credits`, API keys ni datos personales.

---

## 2. ⚠️ Conflicto crítico: hay DOS rúbricas oficiales distintas

Esto Gemini lo trató como si fuera una sola. **No lo es.** Las dos fuentes que yo leí dicen cosas diferentes:

| | **Guía (`/guide`)** | **Deck de onboarding (`/deck/onboarding`)** |
|---|---|---|
| Criterios | **Tracción 30 % · Esfuerzo técnico 40 % · Pitch 30 %** | Complejidad técnica 30 % · Funciona 25 % · Calidad técnica (repo) 20 % · Problema e impacto 15 % · Claridad 10 % |
| Fórmula | `tracción×6 + esfuerzo técnico×8 + pitch×6` (sobre 100) | Cada criterio 1–5; "TÉCNICO 75 % · PRODUCTO 25 %" |
| Tracción | **Es criterio principal (30 %)**: 3 = entrevistas o señales verificables; 5 = uso real, retención o demanda sólida con evidencia | **Solo puntos extra**: +0,25 "lo usaron" (se ve en registros), +0,5 uso repetido, volumen visible, lista de espera real o un pago |

Además, Gemini mencionó un **PDF de rúbrica** ("hack-the-andes-rubrica-sponsors") que tú le pasaste y que **yo no he visto**. Gemini lo citó con detalles (p. ej. niveles 1/5 de cada criterio, "desempate por complejidad técnica y luego por Funciona"). **No puedo confirmar esos detalles.**

> 🤖 **NOTA PARA EL AGENTE CONSTRUCTOR — estrategia ante la incertidumbre:** hasta que la organización aclare cuál rige, **construye para satisfacer ambas**: (a) ingeniería sólida y repo limpio (pesa 40 % en una y 75 % en la otra); (b) demo en vivo desde URL pública que no falle; (c) **tracción real y medible desde la base de datos** (30 % en una; bonus en la otra). **No asumas, como hizo Gemini, que la tracción "ya no importa tanto".** Si solo vale como bonus, perdemos poco por perseguirla; si vale 30 %, ignorarla sería catastrófico.
>
> **Acción inmediata recomendada:** preguntar en el Discord oficial (o a un mentor) "¿rige la rúbrica de la guía (tracción/esfuerzo/pitch) o la del deck (5 criterios + bonus)?". Y **subir el PDF a esta carpeta** para que se incorpore.

---

## 3. Historia de decisiones: cómo llegamos a Cyberon

> Contenido de Gemini, ordenado cronológicamente. Se conserva para que el constructor entienda **por qué** se descartó cada cosa.

### 3.1 Primera ronda de problemas (4)
Criterios de Gemini: validar con usuarios hoy (sin depender de ATU/MTC) e ingeniería real (no CRUD).
1. **Punto ciego de rutas informales y colapsos en vivo (Lima):** cústers, combis y colectivos (70 %+ de viajes) no existen en mapas digitales; motor multimodal con grafo dinámico y reportes comunitarios.
2. **"Correteo" a ciegas y control de frecuencia sin hardware:** buses de la misma flota pegados y luego huecos de 25 min; telemetría ligera, copiloto de voz, panel QR en el paradero.
3. **Carga fragmentada y "flete falso" en regiones:** matching geoespacial entre transportistas con espacio libre y carga, vía audios de WhatsApp.
4. **Ruteo de supervivencia y accesibilidad (movilidad reducida):** fotos de rampas/ascensores con visión computacional.

### 3.2 Segunda ronda tras leer el deck (A / B / C)
**A.** Motor de despacho y consolidación de carga regional ("flete de retorno vacío") · **B.** Navegador resiliente urbano + incidentes en tiempo real (Lima) · **C.** Control de frecuencia "anti-correteo" y ETAs en paraderos sin hardware.

### 3.3 Tu decisión y tu objeción
- Te gustó **B**, pero preguntaste qué la diferencia de Waze/Maps. **A** = poca tracción en 20 h. **C** = no convence.
- **Requisito explícito tuyo (se mantiene como regla):** *no queremos "un Waze que use IA para calcular rutas".* La idea debe diferenciarse de lo existente.

### 3.4 Por qué Waze/Maps fallan en el transporte público de Lima (argumento de Gemini)
1. Miden la velocidad del **asfalto**, no el colapso del **andén** (colas, buses llenos que no abren puerta).
2. El pasajero diario no busca rutas; ya las sabe. Su dolor es lo que ocurre antes de abordar.
3. El pasajero no controla el timón: desvíos por marchas/obras lo dejan en un "paradero fantasma".

### 3.5 Tres problemas fuera del esquema "Waze"
1. **La Trampa del Torniquete / paradero a ciegas** (capacidad de abordaje, colas, buses llenos, paraderos reubicados).
2. **El agujero negro de las líneas tradicionales** (cústers que cortan ruta, se desvían o dejan de pasar de noche).
3. **El varado en hora punta** (40 desconocidos en el mismo paradero, mismo destino; agruparlos para compartir salida).

Elegiste **1 y 3** y pediste definirlo "muuuy bien", fusionándolo con lo de tu compañero.

### 3.6 Propuesta de tu compañero (Cyberon) — íntegra

**Planteamiento.** Al desplazarse por una ciudad, una persona dispone de varias combinaciones de transporte para llegar al mismo destino. Cada alternativa implica un gasto, un tiempo, cierta distancia a pie y una cantidad de transbordos. Compararlas es difícil: una opción económica puede exigir una caminata larga; otra la reduce con un taxi en una parte del recorrido pero sube el costo. La persona debe decidir si ese gasto adicional le conviene y si cabe en su presupuesto. Afecta a visitantes y residentes. Equipaje, cansancio, poco dinero o necesidad de llegar a una hora cambian la alternativa conveniente.

**Hipótesis central.** Las personas necesitan comparar con más claridad el costo total y las exigencias de distintas combinaciones, sobre todo cuando pueden sustituir una caminata o varios transbordos por un tramo en taxi. **Debe validarse con usuarios y contrastarse con las herramientas que ya usan.**

**Formulación.** ¿Cómo ayudar a las personas a planificar y completar un viaje que combine transporte público, caminatas y, cuando convenga, taxis, considerando su presupuesto, tolerancia a la caminata y preferencias?

**Personas.**
| Situación | Necesidad |
|---|---|
| Presupuesto ajustado | Alternativa económica y conocer caminata y transbordos |
| Puede gastar algo más para reducir esfuerzo | Identificar en qué tramo conviene un taxi |
| Zona desconocida | Dónde subir, bajar, caminar y cambiar |
| Equipaje o cansancio | Reducir caminatas largas y conexiones complicadas |
| Debe llegar a una hora | Comparar tiempo y costo |

Las preferencias se definen **por viaje**: no se clasifica a la gente como de ingresos altos o bajos.

**Cómo se resuelve hoy / qué falta comprobar.** Se supone: app de rutas + preguntar a conocidos/conductores + revisar aparte el taxi + comparar mentalmente. A comprobar: no conocer el costo de la combinación completa; no advertir la caminata de cada conexión; no saber en qué tramo un taxi aporta ventaja; elegir una opción que supera el presupuesto al sumar pagos; dificultad para seguir el recorrido al cambiar de medio.

**Objetivo.** Facilitar la elección y el seguimiento de un viaje comparando gasto total, caminata, tiempo estimado y transbordos. Específicos: recoger presupuesto y preferencias; presentar combinaciones comprensibles; explicar qué se gana y qué se sacrifica; orientar durante caminatas y cambios; permitir revisar el plan cuando cambien las condiciones.

**Solución.** Cyberon recibe origen, destino y condiciones y presenta alternativas comparables: **Menor costo**, **Menor caminata**, **Opción intermedia**. Se muestran solo si existen alternativas que las respalden (un taxi no siempre reduce el tiempo; lo más barato no siempre exige más caminata). Cada alternativa: recorrido por tramos, costo total y por tramo, caminata total y más larga continua, tiempo estimado (con esperas cuando se conozcan), cantidad y ubicación de transbordos, datos estimados o pendientes de confirmar.

**Flujo (8 pasos):**
1. Indicar el viaje (origen y destino confirmados).
2. Definir condiciones (presupuesto máximo; caminata total y continua; si acepta taxi; prioridad: ahorro, menos caminata, tiempo, menos transbordos). Puede expresarlo con sus palabras y revisar que se entendió.
3. Comparar alternativas (mapa + resumen; abrir cada una; explicación del tradeoff; importes pendientes marcados como tales).
4. Ajustar condiciones si ninguna cumple: el sistema explica qué condición lo impide; **nunca modifica una restricción sin que el usuario la acepte**.
5. Seleccionar y revisar el recorrido: dónde ir primero, qué servicio abordar, dónde bajar, cómo llegar a la siguiente conexión, gasto estimado. Si hay taxi, **confirma la cotización antes de contratarlo**; si el precio cambia, vuelve a comparar.
6. Seguir el viaje: mapa con tramo actual y siguiente acción; indicaciones concretas; limitaciones visibles.
7. Revisar el plan ante un cambio ("ya no quiero caminar tanto", "el taxi cuesta más", "me bajé en otro punto", "tengo menos presupuesto"): se recalcula desde su ubicación **descontando el dinero ya gastado cuando el usuario lo confirme**.
8. Finalizar: registrar si fue realizable y señalar diferencias en tarifas, puntos de embarque o indicaciones.

**Dos escenarios.** Mismo origen/destino; el transporte público exige caminar seis cuadras entre dos servicios.
| Momento | Prioriza ahorrar | Prioriza caminar menos |
|---|---|---|
| Condiciones | Presupuesto reducido, acepta la caminata | Mayor gasto, limita la caminata |
| Compara | Buses y a pie | Combinación con taxi en el tramo de conexión |
| Decide | Ahorra y camina | Confirma si el costo del taxi lo justifica |
| Realiza | Sigue al segundo paradero | Sigue al punto de recojo y la conexión posterior |
| Si algo cambia | Revisa con el dinero restante | Puede descartar el taxi si la cotización excede su presupuesto |

**Alcance inicial.** Área delimitada y recorridos con información verificable. La contratación y pago del taxi **se hacen mediante el servicio correspondiente**; precios estimados se distinguen de cotizaciones confirmadas. Caminata expresada como distancia y duración; **no se promete accesibilidad** (sillas de ruedas, pendientes, escaleras) por tener poca caminata.

**Evidencia para validar.** Pedir a personas reales que planifiquen un mismo viaje con su método habitual y con Cyberon, y observar: si identifican el costo completo, entienden cuánto caminarán, eligen una opción compatible con sus límites, cuánto tardan en decidir, comprenden qué falta confirmar y pueden seguir las conexiones. También hay que comprobar si la comparación mixta aporta ventaja frente a las apps actuales (**esa ventaja aún no está demostrada**). Acción principal de la demo: elegir un recorrido compatible con presupuesto y caminata aceptable, comprender sus conexiones y seguirlo en el mapa.

### 3.7 La fusión (idea fuerza de Gemini)
Google Maps, Waze y Moovit son **binarios**: todo transporte público (barato pero caminatas hostiles/transbordos colapsados) o todo taxi (cómodo pero ~S/ 25–28). La realidad de Lima es **híbrida y dinámica**: transporte público en el tramo troncal y un **"tramo puente"** (taxi corto o compartido) solo en el eslabón crítico, sin romper el presupuesto.

Nombre del problema (Gemini): **"La Trampa de la Movilidad Binaria y el Presupuesto Roto en Viajes Urbanos Multimodales."**

### 3.8 Tu aporte: paraderos informales ("de facto") por GPS
Tu idea: si varios usuarios están quietos en una zona y cuando pasa un bus su velocidad cambia, estaban esperando ahí → "paradero informal probable". Gemini la llamó *Inferencia de Nodos de Abordaje por Transición Cinemática* y la integró como Motor 2 (detalle en 5.6).

---

## 4. EL PROBLEMA EN PROFUNDIDAD

### 4.1 Una frase
> **Moverse por Lima combinando buses, corredores, cústers, caminata y taxi es un cálculo de dinero, esfuerzo y certidumbre que hoy la persona hace "de memoria y a ciegas"; ninguna herramienta lo hace por ella respetando sus límites reales del día.**

### 4.2 Contexto de Lima (por qué este problema existe aquí)
- El transporte combina **sistemas formales** (Metropolitano, Línea 1 del Metro, Corredores Complementarios) con una **red tradicional enorme** (cústers, micros, combis, colectivos). ⚠️ La cifra de "70 %+ de los viajes en tradicional" es de Gemini, sin fuente.
- Cada **subida se paga por separado** (no hay una tarifa integrada simple entre todos los modos) → **el costo del viaje es la suma de varias subidas**, que el usuario rara vez conoce de antemano. ⚠️ Verificar con tarifas reales por servicio.
- Los **transbordos** suelen exigir caminar entre avenidas, de noche, con peso o con calor/lluvia/cansancio.
- Los vehículos tradicionales **no siempre paran en el paradero oficial**; hay paraderos de facto que solo conoce quien frecuenta la zona.
- El **taxi** existe como alternativa, pero se evalúa "todo o nada": nadie calcula si conviene **solo en un tramo**.
- Hay **inseguridad** y **fatiga** que cambian qué ruta es "buena" ese día.

### 4.3 Quién es el usuario (personas concretas para diseñar y para el pitch)

> **Regla de la rúbrica:** "Problema e impacto: un usuario real de tu track"; nivel alto = **usuario específico y evidencia**. Usar estos personajes **y validarlos con gente real** (sección 11).

**Persona A — "Valeria", estudiante, viaje de regreso nocturno.**
Sale tarde de clases, tiene S/ 8.00 en la billetera, lleva laptop y mochila pesada. Su ruta habitual exige bajar de un corredor y caminar ~600 m hasta otro paradero por una avenida poco iluminada. *Pregunta que no puede responder hoy:* "¿Me conviene pagar un taxi solo esos 600 m y seguir en bus, o me alcanza el dinero para eso?"

**Persona B — "Marco", trabajador en una zona que no conoce.**
Tiene una entrevista/visita de trabajo en un distrito donde nunca ha estado. Google le da una ruta, pero no sabe si el paradero que muestra existe, dónde exactamente para la cúster, ni cuánto gastará en total.

**Persona C — "Rosa", viaje con carga o cansancio.**
Vuelve del mercado con bolsas; puede gastar S/ 12 pero no caminar más de 250 m seguidos. Quiere "lo más barato que no me mate la espalda".

**Persona D — "Diego", cambio de planes a mitad de viaje.**
Ya pagó S/ 2.50 en el primer bus. Se baja antes por tráfico o el taxi que iba a tomar cuesta S/ 12 en vez de S/ 6. Necesita un plan B **con los S/ 5.50 que le quedan**, desde donde está parado.

**Persona E — Visitante** (turista, nuevo en la ciudad): no conoce el sistema de líneas ni los paraderos informales; necesita guía tramo a tramo y saber qué está confirmado y qué no.

### 4.4 Trabajos por hacer (Jobs-to-be-done)
1. "Quiero llegar a X **gastando como máximo S/ N**."
2. "Quiero **no caminar más de M metros seguidos** (por peso, miedo o cansancio)."
3. "Si conviene, quiero **sustituir solo el tramo malo** por taxi y saber cuánto me cuesta de más."
4. "Quiero saber **dónde exactamente** subir y bajar, y qué tan seguro es ese punto."
5. "Si algo cambia, quiero un **plan B con el dinero que me queda**, sin empezar de cero."
6. "Quiero **entender por qué** me sugieren eso y qué estoy sacrificando."

### 4.5 Cómo lo resuelven hoy y por qué falla
| Alternativa actual | Qué hace bien | Dónde falla para este caso |
|---|---|---|
| Google Maps / Moovit | Ruta puerta a puerta con transporte público | Rutas tradicionales incompletas; **no optimiza por presupuesto duro**; no sugiere taxi parcial; no recalcula con el saldo; no distingue paraderos de facto |
| Waze | Tráfico vehicular | Mide asfalto, no transporte público |
| Uber / inDrive / Cabify | Taxi puerta a puerta | Todo o nada; caro; precio no integrado con el resto del viaje |
| Preguntar a conductores/conocidos | Conocimiento local real | No escala; inconsistente; hay que hacerlo en la calle |
| Cálculo mental | Gratis | Propenso a error; no suma costos ni caminata; se rompe con imprevistos |

### 4.6 Las tres fallas estructurales (formulación final)
1. **Movilidad binaria (todo o nada):** nadie calcula en qué eslabón conviene el tramo puente.
2. **Brecha entre el mapa oficial y la calle real:** paraderos de facto, recorridos que cambian.
3. **Rigidez ante imprevistos y costo hundido:** el viaje cambia a mitad de camino y el saldo ya no es el inicial.

### 4.7 Formulación del problema (la oficial para pitch/README)
> ¿Cómo ayudar a las personas a planificar, comparar y completar viajes urbanos multimodales —combinando transporte público, caminatas y tramos puente en taxi— según su presupuesto, su tolerancia a la caminata y el nivel real de certidumbre de los paraderos (oficiales e inferidos), permitiéndoles replantear el recorrido en tiempo real con el saldo que les queda?

### 4.8 Hipótesis a validar (falsables)
| # | Hipótesis | Cómo se comprueba | Si es falsa |
|---|---|---|---|
| H1 | La gente **no sabe el costo total** de una combinación antes de salir | Entrevista corta: "¿cuánto gastas de aquí a tu casa? ¿lo sabías antes de salir?" | Bajar énfasis del presupuesto |
| H2 | La **caminata entre transbordos** es una molestia relevante (por peso, miedo, cansancio) | Preguntar la peor caminata de su ruta habitual | El taxi puente pierde sentido |
| H3 | Sustituir **solo un tramo** por taxi es algo que la gente consideraría | "Si un taxi de S/ 5 te ahorrara esa caminata, ¿lo tomarías?" | Priorizar solo ruteo público |
| H4 | Una app que **suma costos y respeta límites** les parece más útil que su método actual | Prueba lado a lado: mismo viaje con su método vs. Cyberon | Replantear el diferencial |
| H5 | Los paraderos de facto **existen y confunden** | "¿Hay un lugar donde siempre tomas la cúster aunque no sea paradero?" | Motor 2 es adorno (recortarlo) |

> 🤖 **NOTA PARA EL AGENTE CONSTRUCTOR:** estas hipótesis son la columna vertebral del discurso del pitch ("qué probamos con personas y qué aprendimos"). **Instrumenta la app para recolectar la evidencia** (eventos en BD, formulario post-viaje de 2 preguntas) y deja un espacio en la UI/README para mostrar los resultados reales. **No inventes cifras de validación**; si hay 4 entrevistas, se dice "4".

### 4.9 Lo que el problema NO incluye (alcance negativo, para el pitch "qué quedó fuera")
- No es un navegador calle-a-calle para autos.
- No promete **accesibilidad** (silla de ruedas, escaleras) solo por medir distancia.
- No vende/gestiona el taxi: **cotiza de forma estimada** y deriva al servicio externo.
- No promete frecuencias/horarios exactos de cústers (no existen datos fiables).
- No cubre todo Lima: un **eje acotado**.
- No promete seguridad personal.

---

## 5. LA SOLUCIÓN EN PROFUNDIDAD

### 5.1 Tesis del producto
**Cyberon es un planificador y copiloto de viajes multimodales con restricciones duras (dinero y caminata) y transparencia de incertidumbre.** Tres ideas lo diferencian de Maps/Waze/Moovit:
1. **Optimiza para el bolsillo y el cuerpo del usuario, no solo para el tiempo.**
2. **Inyecta un "tramo puente" en taxi solo donde vale la pena** y explica el tradeoff.
3. **Recalcula a mitad de viaje con el saldo real restante** y **distingue lo confirmado de lo estimado** (incluyendo paraderos de facto inferidos por comportamiento).

### 5.2 Principios de diseño (innegociables)
1. **Honestidad de datos:** todo valor lleva etiqueta `CONFIRMED` o `ESTIMATED` (+ fuente y fecha). Nunca presentar una estimación como hecho.
2. **El usuario manda sobre sus restricciones:** nunca relajar presupuesto o caminata sin su aceptación explícita.
3. **Explicabilidad:** cada alternativa trae "qué ganas / qué sacrificas".
4. **Degradación elegante:** si falta un dato o cae una API, la app responde con lo que sabe y lo dice.
5. **Una acción central:** *elegir un recorrido compatible con presupuesto y caminata, entender sus conexiones y seguirlo.*
6. **Uso en calle:** poca interacción, texto corto, botones grandes, mínimo consumo de datos/batería.

### 5.3 Alcance por prioridad (MoSCoW) — **esto es lo que se construye**

**P0 — Imprescindible (sin esto no hay demo). Meta: funcionando y desplegado en ~8 h.**
- Selección de origen/destino en mapa (con búsqueda/geocodificación) dentro del eje elegido.
- Formulario de condiciones: presupuesto máximo, caminata continua máxima, caminata total máxima, aceptar taxi (sí/no), prioridad.
- **Motor de ruteo multimodal** sobre datos reales (OSM) con costos por subida, caminata y taxi puente estimado.
- **3 alternativas** (menor costo / menor caminata / intermedia) con desglose por tramos, costos, caminata, tiempo y etiquetas de certidumbre.
- **Diagnóstico de infactibilidad** con relajación mínima ("necesitas +S/ X o +Y m").
- Vista de recorrido en mapa con colores por tramo.
- **Modo "seguir el viaje"** (tramo actual + siguiente acción) y **"Cambié de plan / recalcular"** con **saldo restante**.
- **Registro de eventos en BD** (sesiones, planes, replanificaciones, feedback) → base de la tracción.
- Despliegue público HTTPS, probado en incógnito. Repo limpio + README.

**P1 — Fuerte diferenciador (después de P0). Meta: ~6 h.**
- **Motor 2:** inferencia de paraderos de facto (ingesta de pings, detector, DBSCAN, capa en mapa con confianza) **+ simulador de trazas para la demo**.
- Entrada de condiciones en **lenguaje natural** (LLM → JSON, con confirmación visual de lo interpretado).
- **Panel público de tracción** leyendo de la BD real.
- Alertas de contingencias (Tavily/Exa) en la pantalla de comparación.
- Formulario post-viaje (¿fue realizable? ¿tarifa/paradero coincidió?).

**P2 — Si sobra tiempo.**
- Memoria de preferencias entre sesiones (AtomicMemory).
- Canal WhatsApp/SMS (Zavu) para guía y replanificación.
- Pipeline n8n/Apify de refresco de datos.
- Taxi **compartido** entre usuarios (alto riesgo; ver 15).
- Notificaciones push, modo offline parcial.

**Fuera (anotar en README como "qué quedó fuera"):** pago/contratación de taxi dentro de la app; accesibilidad certificada; frecuencias en tiempo real de cústers; cobertura de toda Lima.

### 5.4 Pantallas y flujo (wireframe textual)

**S1 · Inicio / Viaje.** Mapa del eje. Dos campos (Origen, Destino) con autocompletado y "usar mi ubicación". Botón "Siguiente". Banner discreto "Datos de [fecha], algunas rutas pueden variar".

**S2 · Condiciones.** Controles:
- Presupuesto máximo (S/) — teclado numérico + atajos (S/ 6, 8, 10, 15).
- "Caminata máxima seguida" (m) — slider con equivalencia en cuadras (≈ 100 m = 1 cuadra).
- "Caminata total máxima" (m).
- Toggle "Acepto taxi en algún tramo".
- Prioridad: Ahorro / Menos caminata / Tiempo / Menos transbordos.
- Caja de texto opcional: *"Cuéntalo con tus palabras"* → el sistema muestra **etiquetas interpretadas editables** ("Presupuesto S/ 8,50 · Caminata seguida ≤ 300 m · Taxi sí") para confirmar.
- Botón "Ver opciones".

**S3 · Comparar (3 tarjetas + mapa).** Cada tarjeta: nombre ("Más barata", "Menos caminata", "Equilibrada"), **costo total** (con chip `CONFIRMADO`/`ESTIMADO`), **caminata total y la más larga**, **tiempo estimado**, **transbordos**, resumen en una línea de tramos (🚶 → 🚌 Corredor Azul → 🚖 taxi puente → 🚶). Al tocarla: detalle tramo a tramo + **explicación del tradeoff** ("Esta opción inserta un taxi de ~1,4 km entre A y B: +S/ 4,50 y baja tu caminata seguida de 850 m a 90 m"). Marcadores: 🟢 paradero oficial · 🟡 paradero de facto (con % confianza) · 🟠 espera/frecuencia estimada. Alertas de contingencia si las hay.

**S4 · Sin solución (infactible).** No dice "no hay rutas". Dice: *"Con S/ 4,00 y máx. 200 m no hay recorrido. Puedes: (A) +S/ 2,50 para incluir un taxi puente en [lugar], o (B) caminar +320 m en el transbordo de [lugar]."* Botones de un toque para aceptar solo una relajación. **Nunca se aplica solo.**

**S5 · Revisión antes de salir.** Checklist: primer punto al que ir, qué servicio abordar, dónde bajar, cómo llegar a la conexión, gasto estimado total y saldo previsto. Si hay taxi: aviso "precio estimado; confirma la cotización en tu app de taxi antes de subir". Botón "Empezar viaje".

**S6 · Seguir el viaje.** Mapa grande. Tarjeta inferior con **la siguiente acción** ("Camina 150 m hacia Av. X y espera el Corredor Azul"), progreso por tramos, saldo restante. Botón **"Algo cambió"**. (Si hay permiso de ubicación: envía pings al backend.)

**S7 · Algo cambió.** Opciones rápidas: "Ya no quiero caminar tanto" · "El taxi cuesta más (ingresar monto)" · "Me bajé en otro punto" (usar mi ubicación) · "Gasté un monto (ingresar)" · "Tengo menos dinero (ingresar)". Confirma el saldo y **recalcula desde la ubicación actual**.

**S8 · Fin.** Una pregunta: "¿Pudiste completar el recorrido?" Sí/No/Parcial; "¿Coincidieron tarifas y paraderos?" (campos opcionales para indicar diferencias). Alimenta confianza de paraderos y evidencia de tracción.

**S9 · Tracción (pública, solo lectura).** Número de viajes planificados por **usuarios externos**, replanificaciones, viajes completados, feedback, paraderos de facto detectados. **Sin datos personales.**

> 🤖 **NOTA PARA EL AGENTE CONSTRUCTOR:** construir **S1→S3 + S4 primero** (es el núcleo y lo que se demuestra), luego S5–S8. S9 es barato y vale mucho en la rúbrica. Todo texto de UI en **español claro y corto**; evitar jerga ("arista", "Pareto") en pantalla.

### 5.5 Motor 1 — Ruteo multimodal con restricciones (diseño detallado)

> **Crítica a Gemini:** propuso `pgRouting`. Para 18 horas y un eje acotado es **innecesario y arriesgado**. Recomiendo **grafo en memoria** (Node/TS o Python) + PostGIS solo para almacenamiento y DBSCAN.

**5.5.1 Modelo del grafo**
- **Nodos:** paraderos/estaciones (`transit_stops`: oficial, OSM, inferido) + nodos virtuales **ORIGEN** y **DESTINO**.
- **Estado de búsqueda:** `(nodo, ruta_a_bordo | null)`. Esto es lo que permite cobrar la tarifa **al subir** (no por tramo) y contar transbordos.
- **Aristas:**
  1. `RIDE`: paradero_i → paradero_{i+1} a lo largo de una ruta `r`. Tiempo ≈ distancia / velocidad media del modo. Costo 0 (la tarifa se cobra al abordar).
  2. `BOARD`: (nodo, null) → (nodo, r). Costo = tarifa de `r`; tiempo = espera estimada (≈ headway/2; headway estimado por modo y hora, marcado `ESTIMATED`).
  3. `ALIGHT`: (nodo, r) → (nodo, null). Costo 0.
  4. `WALK`: entre paraderos (y de/hacia origen/destino) a distancia ≤ R (p. ej. 800 m). Distancia inicial = haversine × 1,3 (factor de circuitidad); **solo los caminos finalistas** se refinan con OSRM `foot`.
  5. `TAXI_BRIDGE` (**virtual, se genera perezosamente**): entre dos paraderos (u,v) a ≤ ~3 km cuando el WALK u→v supera `W_continua_max`, o cuando encadenar ≥ 2 subidas cortas tiene alta fricción. Costo = `max(5.00, 3.50 + 1.25·d_km + 0.25·t_min) × factor_hora` (**ESTIMADO**); distancia/tiempo vía OSRM `driving` (con caché) o aproximación.
- **Parámetros del usuario como restricciones duras:** `Σ costos ≤ presupuesto_restante`; **cada** tramo WALK ≤ `W_continua_max`; `Σ WALK ≤ W_total_max`; `allow_taxi`.

**5.5.2 Búsqueda multicriterio (label-setting tipo Martins)**
Cada etiqueta en un estado guarda `(costo, caminata_total, caminata_continua_actual, tiempo, transbordos, predecesor)`.
```
inicializar etiqueta en (ORIGEN, null) con ceros
cola de prioridad ordenada por (tiempo) o por función escalar ponderada
mientras cola no vacía:
    sacar etiqueta L en estado s
    si L está dominada por otra etiqueta ya fijada en s: continuar
    para cada arista e saliente de s:
        L' = extender(L, e)
        si viola restricción dura (presupuesto, caminata continua, caminata total): descartar
        si L' dominada en el estado destino de e: descartar
        insertar L' (eliminando las que L' domina); limitar a K etiquetas por estado (K≈8-12)
al terminar: conjunto Pareto en DESTINO
```
- **Dominancia:** `A` domina a `B` si es ≤ en (costo, caminata_total, tiempo, transbordos) y < en al menos uno.
- Seleccionar las 3 alternativas del frente de Pareto:
  - **Más barata:** mínimo costo (desempate: menos caminata).
  - **Menos caminata:** mínima caminata total (o continua) dentro del presupuesto.
  - **Equilibrada ("rodilla"):** mayor ratio `Δmetros_ahorrados / Δsoles_gastados` respecto a la más barata, o el punto del frente más cercano al "ideal" normalizado.
- **Regla de honestidad:** si dos alternativas son idénticas o una no aporta ventaja (p. ej. el taxi no reduce caminata ni tiempo), **no se muestra** y se explica ("Descartamos el taxi: no reduce tu caminata en este tramo").
- Si se pidió prioridad "tiempo" o "menos transbordos", ajustar el criterio de ordenamiento.

**5.5.3 Relajación mínima de restricciones (cuando no hay solución)**
Ejecutar la búsqueda varias veces **relajando una sola restricción a la vez** y reportar el delta mínimo:
1. Sin límite de presupuesto → mínima `costo*` ⇒ `Δpresupuesto = costo* − presupuesto`.
2. Sin límite de caminata continua → mínima caminata ⇒ `Δcaminata`.
3. Permitir taxi (si estaba desactivado) → qué cambia.
Presentar las 1–2 relajaciones **más baratas para el usuario**. Mensaje en lenguaje llano. **Nunca aplicar sin consentimiento.**

**5.5.4 Recalculo con costo hundido**
Entradas: `posición_actual`, `gastado_confirmado` (el usuario lo confirma o acepta el monto sugerido del plan), `saldo = presupuesto_inicial − gastado`, estado a bordo (si dice que está en un bus, solo puede bajarse en paraderos de esa ruta; si no, es peatón). Se ejecuta la búsqueda con `ORIGEN = posición_actual` y presupuesto = `saldo`. Se incrementa `replan_count` y se registra el evento.

**5.5.5 Etiquetas de certidumbre por arista/nodo**
| Dato | Estado posible | Origen |
|---|---|---|
| Existencia del paradero | OFFICIAL_ATU / OSM / INFERRED (con %) | Padrón ATU, OSM, Motor 2 |
| Tarifa de la subida | CONFIRMED (con fuente y fecha) / ESTIMATED | Tabla de tarifas, Tavily/Exa |
| Costo del taxi | siempre ESTIMATED hasta cotización externa | Fórmula |
| Espera/frecuencia | ESTIMATED por hora valle/punta | Heurística |
| Recorrido de cústers | OSM_COMMUNITY (puede estar desactualizado) | OSM |

> 🤖 **NOTA PARA EL AGENTE CONSTRUCTOR:** implementa el motor como **módulo puro y testeable** (entrada: grafo + parámetros; salida: alternativas + diagnóstico), sin dependencias de red dentro del bucle de búsqueda. Escribe **tests unitarios** con casos de oro: (1) caso con solución única; (2) caso infactible con relajación esperada; (3) caso donde el taxi **no** debe aparecer; (4) recálculo con saldo reducido. Esto da puntos de **Calidad técnica** (repo) y evita fallos en vivo. Límites de seguridad: tamaño máximo de entrada, timeout de búsqueda (p. ej. 2–3 s) y respuesta parcial si se excede.

### 5.6 Motor 2 — Paraderos de facto por transición cinemática (diseño detallado)

**Idea:** convertir el comportamiento colectivo en información de mapa, marcándola siempre como **inferida**.

**5.6.1 Captura (Paso "Seguir el viaje")**
Ping cada 2–5 s: `(session_id_anónimo, lat, lon, speed_mps, heading_deg, accuracy_m, ts)`. Enviar en lotes (cada ~10 s) para ahorrar batería/datos. **Descartar pings con `accuracy_m` > 30–40 m.**

**5.6.2 Detección de "espera → abordaje"**
Ventana deslizante por sesión:
1. **Espera:** durante ≥ 40 s el usuario permanece en radio ≲ 15–25 m con `v < 1,2 m/s`.
2. **Salto:** en ≤ 15–20 s la velocidad sube a `v > 4,5 m/s` (> 16 km/h) y se mantiene unos segundos.
3. **Alineación:** el rumbo coincide (±20–30°) con una ruta conocida **o** con una avenida troncal; el punto de transición está a > 50 m de cualquier paradero oficial.
4. **Exclusiones (falsos positivos):** semáforo/tráfico (el salto no viene precedido de espera larga en acera), taxi/mototaxi propio (si el usuario marcó taxi puente), auto particular, bicicleta (rango de velocidad), GPS con mala precisión.

> **Crítica:** los umbrales de Gemini (15 m, 40 s, 4,5 m/s) son **puntos de partida, no verdades**. En cañones urbanos el GPS tiene error de 10–30 m; con 15 m de radio habrá muchos falsos negativos. Hay que **tunearlos con trazas reales** y documentarlo.

**5.6.3 Agrupamiento**
`ST_ClusterDBSCAN(geom_proyectada, eps := ~25–30 m, minpoints := 3)` sobre los puntos de transición (proyectar a UTM 18S, `EPSG:32718`, para que `eps` esté en metros). Cada clúster → **candidato a paradero de facto** con:
- `detected_boardings_count`,
- `distinct_sessions` (≥ 3 sesiones **distintas**; un solo usuario no cuenta),
- `confidence` (p. ej. función creciente de abordajes y sesiones distintas y decreciente con dispersión; si se llama "bayesiano", implementarlo realmente — si no, llamarlo "puntaje heurístico").
**No promover a la capa visible** hasta cumplir `distinct_sessions ≥ 3`.

**5.6.4 Presentación en la app**
🟡 "Paradero probable (inferido por GPS de otros usuarios) — confianza X %". Texto de ayuda: *"No figura como paradero oficial; usuarios con GPS esperaron aquí y luego subieron a un vehículo."* Nunca afirmar que el paradero es legal/ilegal: solo "oficial" vs "inferido".

**5.6.5 Demo sin datos reales: simulador**
Endpoint/CLI que **inyecta trazas sintéticas** (N peatones quietos en una esquina no oficial, un "bus" que pasa, saltos de velocidad). **Marcar visiblemente `SIMULADO` en la UI y decirlo en voz alta en el pitch.** Presentar el detector como "implementado y verificado con datos simulados; recogiendo datos reales".

**5.6.6 Privacidad (obligatoria)**
Las trazas GPS son datos personales. Usar **IDs de sesión anónimos**, no guardar teléfono/nombre junto a las trazas, **no exponer trazas individuales** en ninguna API ni en la galería pública, y publicar solo **agregados** (clústeres). Política corta en el README. (La guía exige excluir "datos personales de usuarios" de descripciones y avances.)

> 🤖 **NOTA PARA EL AGENTE CONSTRUCTOR:** el worker del detector puede correr como **tarea periódica** (cada 1–5 min) sobre los últimos N minutos, no como streaming complejo. Primero haz que funcione con el simulador, luego conéctalo a pings reales. Si el tiempo se acaba, **se recorta el paradero en vivo pero se conserva la capa de paraderos OSM/ATU**: el producto sigue funcionando sin Motor 2.

### 5.7 Intérprete de lenguaje natural (P1)
- Entrada: texto (o audio transcrito) como *"Tengo 10 soles, estoy con cajas en Angamos y no quiero caminar más de 2 cuadras seguidas"*.
- Salida estricta JSON validado con esquema: `{budget_max, max_continuous_walk_m, max_total_walk_m?, allow_taxi, priority, origin_hint?, spent_so_far?}`.
- **Siempre mostrar las etiquetas interpretadas para que el usuario confirme** (paso 2 del flujo). Nunca ejecutar sin confirmar.
- Conversión de cuadras→metros (≈ 100 m/cuadra) explícita en pantalla.
- **Fallback:** si el LLM falla o tarda, los controles manuales siguen funcionando (el NL nunca debe ser la única vía).

### 5.8 Contrato de API (propuesta)

```
POST /api/trips/plan
  body: { origin:{lat,lng}, destination:{lat,lng},
          budget_soles, max_continuous_walk_m, max_total_walk_m,
          allow_taxi_bridge, priority, session_id }
  200:  { trip_id, alternatives:[ Alternative ], infeasible:null }
  200:  { trip_id, alternatives:[], infeasible:{ blocking:[...], relaxations:[ {type, delta, message} ] } }

Alternative = {
  id, label: "CHEAPEST"|"LEAST_WALK"|"BALANCED",
  total_cost:{ amount, certainty:"CONFIRMED"|"ESTIMATED" },
  total_walk_m, longest_continuous_walk_m, est_duration_min, transfers,
  legs:[ { type:"WALK"|"RIDE"|"TAXI_BRIDGE", from, to, polyline,
           distance_m, duration_min, route_code?, cost?, certainty,
           boarding_stop?:{ id, type:"OFFICIAL_ATU"|"OSM_COMMUNITY"|"INFERRED_DE_FACTO", confidence } } ],
  tradeoff_text, warnings:[ ... ]
}

POST /api/trips/:id/select         body: { alternative_id }
POST /api/trips/:id/replan         body: { position:{lat,lng}, spent_soles, new_budget?, note? }
POST /api/trips/:id/complete       body: { completed:"YES"|"NO"|"PARTIAL", fare_mismatch?, stop_mismatch?, comment? }
POST /api/telemetry/pings          body: { session_id, pings:[ {lat,lng,speed,heading,accuracy,ts} ] }
GET  /api/stops?bbox=...           (oficiales, OSM, inferidos con confianza)
GET  /api/metrics/traction         (agregados públicos, sin datos personales)
POST /api/nlp/parse-constraints    body: { text }  → { parsed, confirmation_labels }
POST /api/dev/simulate-boardings   (solo modo demo; protegido)
```
Todas las respuestas incluyen `data_version` (fecha del dataset) para mostrarla en la UI.

### 5.9 Manejo de errores y casos borde (mínimos a cubrir)
- Origen/destino **fuera del eje cubierto** → mensaje claro + sugerencia de zona cubierta.
- Presupuesto ≤ 0, valores no numéricos, caminata negativa → validación (cliente y servidor).
- **Presupuesto menor a cualquier tarifa** → infactible con relajación.
- Origen = destino o muy cercanos → "puedes ir caminando (X m)".
- **API externa caída** (OSRM, Tavily, LLM) → fallback a estimación local y aviso en pantalla.
- Sin permiso de ubicación → entrada manual del punto.
- Doble envío/replanificación repetida → idempotencia por `request_id`.
- Entradas hostiles (inyecciones en el texto libre, tamaños enormes) → validar esquema, límites de longitud, no pasar texto del usuario directo a consultas.

---

## 6. DATOS: de dónde sale cada dato y qué falta

### 6.1 Fuentes
| Necesidad | Fuente propuesta | Estado |
|---|---|---|
| Rutas (Metropolitano, Metro L1, Corredores) y paraderos | **OpenStreetMap vía Overpass** (`route=bus|subway|train`, `highway=bus_stop`) | ⚠️ Cobertura y calidad **sin verificar**. Probar la consulta primero |
| Rutas de cústers/micros tradicionales | OSM (si existen) | ⚠️ Gemini dijo ">150 rutas": **probablemente exagerado** |
| Paraderos autorizados ATU / rutas autorizadas | Datos abiertos ATU (`datosabiertos.gob.pe`, ArcGIS REST) | ⚠️ Existencia y formato **sin verificar** |
| Caminata y taxi (distancias/tiempos) | **OSRM** (`foot`, `driving`) | ⚠️ El servidor público de demostración tiene política de uso; **cachear** y limitar llamadas, o auto-hospedar solo si hay tiempo |
| Tarifas | Tabla propia + verificación con Tavily/Exa | ⚠️ Los montos de Gemini (S/ 2,20 / 2,50 / etc.) son **ilustrativos, no verificados** |
| Frecuencias/horarios | **No existen datos fiables** para tradicional | Usar heurística por modo/hora, **siempre `ESTIMATED`** |
| Alertas (desvíos, cierres, marchas) | Tavily / Exa / Apify | Viable |
| GTFS de Lima | ⚠️ Posible GTFS de Metropolitano/Corredores en catálogos abiertos (p. ej. Mobility Database) | **Sin verificar**; buscar rápido, puede ahorrar horas |

Consulta Overpass de ejemplo (eje Javier Prado–Arequipa–Universitaria; ajustar el bbox al eje real):
```
[out:json][timeout:25];
(
  relation["route"~"bus|subway|train"](-12.15,-77.10,-11.98,-76.95);
  node["highway"="bus_stop"](-12.15,-77.10,-11.98,-76.95);
);
out body;
>;
out skel qt;
```

### 6.2 Fórmula de taxi (estimada)
`C_taxi = max(5.00, 3.50 + 1.25·d_km + 0.25·t_min) × factor_hora` (Gemini dio 1,20 en una versión y 1,25 en otra; **usar una sola y documentarla**). ⚠️ **Coeficientes inventados**, no calibrados. No existe API pública de tarifas de taxi en Lima: mostrar siempre como estimado y pedir al usuario que confirme la cotización en su app de taxi.

### 6.3 Plan de ingesta (qué hacer primero)
1. **Elegir el eje** (ver 16).
2. **Probar Overpass** en ese bbox y **medir**: ¿cuántas rutas tienen geometría completa? ¿cuántos paraderos? ¿hay cústers?
3. Si OSM es pobre en tradicional: **curar a mano** 4–8 rutas clave del eje (polilínea + paraderos + tarifa + fuente) en un archivo GeoJSON/JSON del repo. **Es legítimo y honesto** si se documenta ("datos curados del eje, fuente: X").
4. Cargar a PostGIS; pre-calcular vecindades de caminata entre paraderos.
5. Probar 10 viajes de oro dentro del eje y fijarlos como pruebas.

> 🤖 **NOTA PARA EL AGENTE CONSTRUCTOR:** el riesgo nº 1 técnico es la **calidad de los datos de rutas**, no el algoritmo. **No escribas el motor completo antes de ver los datos reales del eje.** Documenta en el README, con fecha y fuente, de dónde sale cada dataset y qué se curó a mano. Un jurado técnico castigará datos "inventados" mucho más que datos acotados pero reales.

---

## 7. SPONSORS Y SUS HERRAMIENTAS

> ✅ **Lo que otorgan** está leído del deck oficial. 🔎 **Qué es cada herramienta** lo busqué en la web (fuentes de terceros o repos públicos; verificar en la documentación oficial antes de depender de ellas). **Canjear con `andes credits`** (después de check-in); no se canjea solo; no publicar códigos.

### 7.1 Tabla maestra

| Sponsor | Qué da (deck ✅) | Qué es (🔎) | Encaje con Cyberon | Prioridad |
|---|---|---|---|---|
| **Tavily** | 8.000 créditos por participante | API de búsqueda/lectura web pensada para agentes | Alertas del día (desvíos, cierres, marchas), verificación de tarifas | **Media-Alta** (barato) |
| **Exa** | USD 50 en Search API | Búsqueda **semántica** de páginas/documentos | Encontrar resoluciones tarifarias, comunicados ATU/Municipalidad por significado | **Media** |
| **Apify** | USD 100 en créditos | Plataforma de scrapers ("actors") listos | Extraer tablas/listados de rutas, tarifas o alertas de páginas oficiales si no hay API | **Media** (si hay hueco de datos) |
| **n8n** | 1 mes Cloud Pro por participante | Automatización de flujos que conecta APIs | Programar el refresco de datos y alertas hacia la BD | **Media-Baja** |
| **Maritime** | USD 100 en maritime.sh | Cada agente/servicio corre en su propia micro-VM con disco **persistente**; despliegue por CLI/REST/SDK; barato (desde ~US$ 1/mes por agente según fuentes) | **Alojar el worker persistente** (detector de paraderos, simulador) o incluso el backend | **Media-Alta** |
| **AtomicMemory** | 5 meses Plan Pro (USD 95 en total) | Capa de **memoria** para agentes: motor HTTP sobre Postgres + pgvector, SDK TypeScript/Python, MCP, de código abierto y con opción hospedada (en *developer preview*) | Recordar preferencias del usuario entre sesiones ("tiene medio pasaje", "de noche máx. 200 m") | **Media** (P2) |
| **Zavu** | 3 meses | API unificada de mensajería: **WhatsApp, SMS, Telegram, email y voz**; SDK TS/Python/Go/PHP/Ruby (server-side); webhooks; claves test/live | Canal opcional para guiar/replanificar y para **captar usuarios externos** | **Media-Baja** (P2) |
| **Qatom** | 6 meses Plan Max (USD 1.800); "agentes y transacciones sin límite, hasta 1.000 ítems en el catálogo" | Según fuentes de terceros: servidor **MCP para comercio entre agentes** (descubrir APIs, pagar por llamada, wallets, pagos atómicos). **Qué hace exactamente es poco claro** | **Encaje débil/incierto** con taxis; ver 7.9 | **Baja** salvo caso honesto |
| **Lovable** | Plan Pro | Generador de apps web a partir de descripciones | Acelerar un **front web / panel de tracción**; **no** produce app nativa | **Baja-Media** (solo si ayuda; cuidado con la calidad del repo) |
| **Chofex** | Sponsor principal, dueño del CLI `andes` | — | Premios (S/ 6.000 / 2.000 + viaje a Chofex HQ) | — |
| **ElevenLabs** | **No figura en el deck ni en la guía** que leí | — | **Gemini lo inventó/asumió**. No contar con él | — |

### 7.2 Qué NO hacer con los sponsors
- **No usar un sponsor "porque sí".** La rúbrica premia integraciones y orquestación *reales* con "decisiones justificadas" (Esfuerzo técnico: "Usar IA no resta puntos por sí solo. Explica tus decisiones"). Cada integración debe tener una **razón de producto** que se pueda decir en 10 segundos.
- **No bloquear el camino crítico con un sponsor.** Todo servicio externo debe tener **fallback** (la demo no puede caerse porque una API de terceros tarde).
- **No publicar códigos/keys** (ni en README, ni en bitácora, ni en el repo).

### 7.3 Detalle por herramienta (cómo se integraría de verdad)

**Tavily + Exa — "Contingencias y tarifas del día" (P1)**
- *Qué hace:* un servicio `alerts` consulta por el eje/ruta ("desvío corredor azul hoy", "cierre estación [X]", "marcha centro de Lima") y devuelve fragmentos con **fuente y fecha**.
- *Dónde aparece:* en S3 como chips "⚠️ Alerta reportada hoy: … (fuente, hora)". **Nunca** modifica rutas por sí solo; solo informa y baja la confianza de un tramo.
- *Exa* para consultas semánticas ("resolución que fija la tarifa del corredor X"); *Tavily* para noticias/actualidad.
- *Riesgos:* resultados ruidosos o falsos positivos → mostrar siempre la fuente y marcar "no verificado".
- *Esfuerzo:* bajo (un endpoint + caché de 10–30 min).

**Apify — "Cuando no hay API" (P1/P2)**
- *Qué hace:* ejecutar un scraper existente (o uno simple) sobre páginas oficiales (listados de rutas, tarifas, comunicados) y volcar a la BD.
- *Cuidado:* respetar términos de uso de cada sitio; **no extraer datos personales**; guardar la fuente.
- *Esfuerzo:* medio. Úsalo solo si falta un dato que OSM/ATU no dan.

**n8n — Orquestación de refrescos (P2)**
- *Qué hace:* flujo programado (cron) → Overpass/ATU → normalizar → upsert en BD; otro flujo → Tavily → tabla `alerts`.
- *Valor demostrable:* "los datos se actualizan solos". Útil para el criterio de arquitectura/orquestación.
- *Riesgo:* añade infraestructura y credenciales; mantener flujos simples y exportados al repo (`/ops/n8n/*.json`) sin secretos.

**Maritime — Worker persistente (P1)**
- *Qué hace:* aloja el servicio de fondo (detector de paraderos, simulador, jobs) en una micro-VM con **disco persistente**; se despliega por CLI/REST/SDK.
- *Valor:* separa el **API público** (liviano) del **worker** (cómputo/estado). Buen argumento de arquitectura.
- *Riesgo:* curva de aprendizaje; si no sale rápido, correr el worker junto al backend y mencionarlo como evolución.

**AtomicMemory — Preferencias entre sesiones (P2)**
- *Qué hace:* guardar y recuperar hechos del usuario (p. ej. "tiene medio pasaje", "evita caminar de noche", "presupuesto típico de mañana S/ 6") y usarlos para **pre-llenar** S2.
- *Cómo:* SDK TypeScript o MCP; clave de memoria = `session_id`/usuario anónimo. **No almacenar datos sensibles.**
- *Riesgo:* el valor para el jurado es modesto si no se muestra; mostrar en la UI "recordamos tus preferencias (puedes borrarlas)".

**Zavu — Canal complementario (P2)** → ver sección 10.

**Qatom — ver 7.9.**

**Lovable — Aceleración de UI (opcional)**
- Podría generar rápido un **panel público de tracción** o un front web. **Limitación:** genera apps web (React) con su propia estructura; mezclar con una app Expo exige cuidado. Para cumplir "Calidad técnica del repo" es preferible código propio y limpio. Si se usa, **revisar y refactorizar** lo generado.

### 7.4 Cómo se vería la arquitectura con sponsors (mínimo defendible)
```
[App móvil/web Expo]  ──HTTPS──▶  [API (Node/TS o Python)]  ──▶  [PostgreSQL + PostGIS]
        │                              │  ├─▶ Motor de ruteo (módulo puro, grafo en memoria)
        │                              │  ├─▶ OSRM (caminata/taxi, con caché)
        │                              │  ├─▶ Tavily/Exa (alertas, con caché y fallback)
        │                              │  └─▶ LLM (parser NL, con fallback manual)
        └─(opcional)─▶ Zavu ◀──webhook──┘
[Worker en Maritime] ──▶ DBSCAN/simulador ──▶ PostgreSQL (transit_stops INFERRED)
[n8n (opcional)] ──cron──▶ Overpass/ATU/Tavily ──▶ PostgreSQL
[AtomicMemory (opcional)] ◀──▶ API (preferencias)
```

### 7.5 Recomendación priorizada (opinión crítica)
1. **Núcleo sin sponsors:** ruteo + datos reales + UI + tracción en BD. *Esto es lo que gana.*
2. **Primeros sponsors a integrar (mejor relación valor/esfuerzo):** **Tavily/Exa** (alertas con fuente), **Maritime** (worker del detector).
3. **Segunda tanda si hay tiempo:** **AtomicMemory** (preferencias), **n8n** (refresco automático).
4. **Opcional/captación:** **Zavu** (solo si ayuda a conseguir usuarios externos).
5. **Descartar o dejar claramente justificado:** **Qatom** (salvo caso honesto), **Lovable** (salvo para panel simple).

### 7.6 Ayuda disponible
El deck indica para dudas de Zavu en Discord: **viktorpy, jullietv y calmizir**. Los mentores en sala (5) pueden orientar sobre créditos y qué sponsor encaja.

### 7.7 Dónde buscar documentación
- Zavu: `docs.zavu.dev` · Maritime: `maritime.sh` · AtomicMemory: repo `atomicstrata/atomicmemory` · Qatom: pedir la guía exacta en `andes credits` o a un mentor.

### 7.8 Checklist de canje
`andes checkin --status` → `andes credits` → leer condiciones de **cada** proveedor → canjear solo lo que se vaya a usar → **guardar claves en variables de entorno, nunca en el repo**.

### 7.9 Sobre Qatom (por qué dudo)
Gemini lo describió como "motor transaccional de tramos puente" con reservas auditables. Eso **no encaja con lo que dice el propio documento del compañero**: el taxi se contrata y paga *en el servicio correspondiente*, fuera de Cyberon. Según las fuentes que encontré, Qatom parece una plataforma de **comercio entre agentes de IA** (catálogo de APIs, pagos por llamada), lo cual no equivale a reservar taxis reales. Registrar "transacciones" ficticias para inflar la tracción **sería deshonesto** y el guion de tracción exige evidencia real.
**Opciones honestas:** (a) no usarlo; (b) usarlo solo si se identifica un caso real y pequeño (p. ej. publicar el motor de ruteo como herramienta consultable por otros agentes, con ítems reales en el catálogo); (c) pedir a un mentor/Discord que expliquen para qué sirve.
> 🤖 **NOTA PARA EL AGENTE CONSTRUCTOR:** **no simules transacciones**. Si Qatom se integra, que sea con un caso real, demostrable y descrito sin exagerar.

---

## 8. Arquitectura, stack, repo y base de datos

> ⚠️ **ACTUALIZADO:** el equipo decidió **Flutter + Firebase** (base de datos y notificaciones). Esta sección (PostgreSQL/PostGIS, Node/Python, Expo) queda **superada**; la arquitectura vigente y el enfoque MVP están en [cyberon-arquitectura.md](cyberon-arquitectura.md). Se conserva el texto de abajo solo como historial de lo que propuso Gemini.

### 8.1 Decisiones de stack (recomendadas)
- **Cliente:** **Expo (React Native) con salida web** (react-native-web), diseño **mobile-first**. Un código → app móvil + URL pública para el jurado (ver sección 9). Mapa: MapLibre / Leaflet (web) o `react-native-maps`; si el tiempo aprieta, priorizar la versión web.
- **Backend:** **Node.js + TypeScript** (Fastify/Express) o **Python (FastAPI)** — elegir el que domine el equipo. Tipado estricto, validación de esquemas (Zod/Pydantic), capas separadas (rutas HTTP / servicios / dominio / repositorios).
- **BD:** PostgreSQL + **PostGIS** (Supabase, Neon con PostGIS, o Postgres en contenedor). Migraciones versionadas.
- **Motor de ruteo:** módulo propio, **grafo en memoria**, cargado desde la BD al arrancar.
- **Despliegue:** API en un PaaS con HTTPS (Railway/Render/Fly/Maritime); cliente web estático (Vercel/Netlify/Cloudflare Pages) **o** servido por el propio backend. Probar siempre en incógnito.
- **Observabilidad mínima:** logs estructurados, endpoint `/health`, tabla `events`.

> 🤖 **NOTA PARA EL AGENTE CONSTRUCTOR:** **No elijas un stack que no se pueda desplegar con URL pública antes de la medianoche.** Mejor tener a las 22:00 una versión web simple desplegada que a las 08:00 una app nativa que solo corre en el teléfono de alguien.

### 8.2 Estructura de repositorio (sugerida)
```
/apps
  /mobile            # Expo (RN + web)
  /api               # backend (HTTP, validación, servicios)
/packages
  /routing-engine    # módulo puro: grafo, Pareto, relajación, replan  (con tests)
  /shared-types      # tipos/contratos compartidos
/data
  /raw               # descargas Overpass/ATU con fecha (no secretos)
  /curated           # rutas/paraderos curados a mano + FUENTES.md
/ops
  /n8n               # flujos exportados sin secretos
  /migrations        # SQL versionado
/docs
  ARCHITECTURE.md  DECISIONS.md  DATA_SOURCES.md  PRIVACY.md  DEMO_SCRIPT.md
.env.example         # sin valores reales
README.md            # problema, usuario, demo, arquitectura, tradeoffs, qué quedó fuera
```

### 8.3 Esquema de BD (base de Gemini, con añadidos míos)

```sql
-- Extensiones
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Nodos de transporte (oficiales ATU / OSM / inferidos por GPS)
CREATE TABLE transit_stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(180) NOT NULL,
    geom GEOMETRY(Point, 4326) NOT NULL,
    stop_type VARCHAR(30) NOT NULL CHECK (stop_type IN ('OFFICIAL_ATU','OSM_COMMUNITY','INFERRED_DE_FACTO')),
    confidence_score NUMERIC(4,2) DEFAULT 1.00,
    detected_boardings_count INT DEFAULT 0,
    distinct_sessions_count INT DEFAULT 0,          -- añadido: mínimo de sesiones distintas
    routes_serving TEXT[],
    source VARCHAR(120),                            -- añadido: trazabilidad
    last_verified_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX transit_stops_geom_idx ON transit_stops USING GIST (geom);

-- 2. Rutas
CREATE TABLE transit_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) NOT NULL,
    name VARCHAR(180) NOT NULL,
    mode VARCHAR(30) NOT NULL CHECK (mode IN ('METROPOLITANO','METRO_L1','CORREDOR','CUSTER_TRADICIONAL','ALIMENTADOR')),
    geom GEOMETRY(MultiLineString, 4326) NOT NULL,
    base_fare_soles NUMERIC(5,2) NOT NULL,
    fare_certainty VARCHAR(20) NOT NULL CHECK (fare_certainty IN ('CONFIRMED','ESTIMATED')),
    fare_source VARCHAR(200),                       -- añadido: URL/fecha de la tarifa
    est_headway_min NUMERIC(5,1),                   -- añadido: espera estimada
    avg_speed_kmh NUMERIC(5,1),                     -- añadido: velocidad media por modo
    active_alerts JSONB DEFAULT '[]'
);
-- añadido: orden de paraderos por ruta (necesario para las aristas RIDE)
CREATE TABLE route_stops (
    route_id UUID REFERENCES transit_routes(id),
    stop_id  UUID REFERENCES transit_stops(id),
    seq INT NOT NULL,
    PRIMARY KEY (route_id, seq)
);

-- 3. Sesiones de viaje y saldo (costo hundido)
CREATE TABLE trip_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    anon_session_id VARCHAR(64) NOT NULL,            -- anónimo (no teléfono)
    is_external_user BOOLEAN DEFAULT FALSE,          -- añadido: para tracción (no equipo)
    origin_geom GEOMETRY(Point, 4326) NOT NULL,
    destination_geom GEOMETRY(Point, 4326) NOT NULL,
    initial_budget_soles NUMERIC(6,2) NOT NULL CHECK (initial_budget_soles >= 0),
    spent_budget_soles NUMERIC(6,2) DEFAULT 0.00,
    remaining_budget_soles NUMERIC(6,2) GENERATED ALWAYS AS (initial_budget_soles - spent_budget_soles) STORED,
    max_total_walk_m INT NOT NULL,
    max_continuous_walk_m INT NOT NULL,
    allow_taxi_bridge BOOLEAN DEFAULT TRUE,
    priority_mode VARCHAR(30) DEFAULT 'BALANCED',
    status VARCHAR(30) DEFAULT 'PLANNING',           -- PLANNING, ACTIVE, REPLANNED, COMPLETED, ABANDONED
    replan_count INT DEFAULT 0,
    selected_alternative JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Telemetría para inferir paraderos (SIN datos personales)
CREATE TABLE gps_kinematic_pings (
    id BIGSERIAL PRIMARY KEY,
    anon_session_id VARCHAR(64) NOT NULL,
    geom GEOMETRY(Point, 4326) NOT NULL,
    speed_mps NUMERIC(5,2) NOT NULL,
    heading_deg NUMERIC(5,2),
    accuracy_m NUMERIC(6,2),                         -- añadido
    is_simulated BOOLEAN DEFAULT FALSE,              -- añadido: honestidad en la demo
    recorded_at TIMESTAMPTZ NOT NULL
);

-- 5. Eventos de producto (base de la TRACCIÓN)  — añadido
CREATE TABLE events (
    id BIGSERIAL PRIMARY KEY,
    anon_session_id VARCHAR(64) NOT NULL,
    type VARCHAR(40) NOT NULL,   -- PLAN, SELECT, REPLAN, COMPLETE, FEEDBACK, ALERT_VIEWED...
    payload JSONB,
    is_external_user BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Feedback post-viaje — añadido
CREATE TABLE trip_feedback (
    trip_id UUID REFERENCES trip_sessions(id),
    completed VARCHAR(10) CHECK (completed IN ('YES','NO','PARTIAL')),
    fare_mismatch TEXT, stop_mismatch TEXT, comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 8.4 Variables de entorno (`.env.example`, solo nombres)
`DATABASE_URL`, `OSRM_BASE_URL`, `TAVILY_API_KEY`, `EXA_API_KEY`, `LLM_API_KEY`, `ZAVU_API_KEY` (opcional), `ATOMICMEMORY_*` (opcional), `APIFY_TOKEN` (opcional), `ADMIN_DEMO_TOKEN` (protege el simulador). **Ningún valor real en el repo.**

---

## 9. App móvil vs. URL pública (la tensión con las reglas)

Tu postura: **app móvil, no sistema web** — válida para el producto (GPS nativo, uso en calle). **Conflicto:** la organización abre `--deployment-url` desde **su propia PC en incógnito**, y "no cuenta" localhost, video ni mockups. Un APK o Expo Go **no** se puede abrir en esa PC.

**Resolución recomendada:** **Expo + react-native-web**, diseño **mobile-first**:
- **Una base de código** → app Android/iOS **y** versión web desplegada (la URL del jurado).
- La demo oficial corre desde la **URL pública**; en la sala puedes mostrar la app instalada en teléfono como **extra**.
- **GPS en la demo del jurado:** su PC no tendrá una ubicación útil → incluir **"modo demo": fijar posición tocando el mapa/usar viajes de ejemplo** y el simulador de trazas. La geolocalización real se muestra en teléfono.
- Alternativa más simple: **PWA mobile-first** (instalable, con GPS). Menos "nativa", mucho menos riesgo.

⚠️ **Riesgos del nativo en 18 h:** geolocalización en segundo plano, permisos, compilación/firmado de builds, tiempo de depuración. **Decisión sugerida:** hacer funcionar primero la **web mobile-first pública**; la compilación nativa es un extra opcional.

---

## 10. Respuesta a: "¿Cómo piensas incluir Zavu? No entiendo lo de WhatsApp"

**Qué es:** una API para enviar/recibir **WhatsApp, SMS, Telegram, email y voz** con un solo código. No sustituye a tu app: es un **canal adicional**.

**Lo que propuso Gemini (dos usos):**
1. **Copiloto "modo calle":** tras "Iniciar viaje", el usuario puede recibir las instrucciones por WhatsApp ("camina 150 m a Av. X y aborda el Corredor Azul") para guardar el teléfono (seguridad/batería).
2. **Replanificación por chat:** si algo falla, escribe o manda un audio al bot ("el bus pasó lleno y me quedan 6 soles") y recibe el plan nuevo por el mismo chat.

**Mi evaluación crítica:**
- Con una app con **notificaciones push** y guía por pantalla, WhatsApp **aporta poco al núcleo**. Es el rol más débil de la lista de sponsors.
- **Lo que sí aporta:** (a) **captar usuarios externos sin instalar nada** (para tracción): "escríbele al bot y planifica tu viaje a casa"; (b) **replanificar con audio** cuando no puedes mirar la pantalla.
- **Costos ocultos (🔎):** WhatsApp exige **WhatsApp Business Account**, número y aprobación de plantillas; el email exige **verificación (KYC)**; puede no estar listo en horas. Las claves tienen modo test y live.
- **Recomendación:** P2, implementado como **un webhook que reusa los mismos endpoints** (`/plan`, `/replan`). Si el tiempo aprieta, es lo primero que se recorta. Si se hace, que **cuente en la tracción** (mensajes reales de personas fuera del equipo).

> 🤖 **NOTA PARA EL AGENTE CONSTRUCTOR:** no dupliques lógica por canal. El dominio (`routing-engine`) es único; la UI app y el bot de WhatsApp son **adaptadores**.

---

## 11. Plan de tracción (evidencia externa real)

**Por qué importa:** en la guía pesa **30 %** (3 = entrevistas/señales verificables; 5 = uso real, retención o demanda con evidencia) y en el deck da **+0,25/+0,5** "se ve en registros o datos". **Capturas, cuentas del equipo o tráfico automatizado no cuentan.**

### 11.1 Tu ventaja: los otros ~100 participantes **son usuarios reales** de Lima
Casi todos tienen **un viaje real a casa** (esta noche o el domingo tras las 14:00). Pedirles: *"Planifica tu regreso a casa con Cyberon con tu presupuesto real."* Es barato, inmediato y deja registro en BD.

### 11.2 Acciones
1. **Instrumentar desde el inicio** (`events`, `trip_sessions.is_external_user`, feedback). Sin eso no hay evidencia.
2. **Entrevistas cortas (≥5):** 3 preguntas — ¿cómo vas a casa y cuánto gastas?, ¿cuál es tu peor transbordo?, ¿tomarías un taxi solo en ese tramo? Anotar respuestas (con permiso) en `docs/VALIDATION.md`.
3. **Prueba lado a lado (≥3 personas):** mismo viaje con su método vs. Cyberon; medir tiempo de decisión y si identifican el costo completo.
4. **Pedir uso repetido:** que vuelvan a planificar el regreso o recalcular tras un cambio.
5. **Compartir el enlace** en Discord del evento, WhatsApp de equipo/universidad.
6. **Publicar en la bitácora** (`andes project update`) cada prueba real con **datos verificables**.

### 11.3 Panel de tracción (S9)
Lectura **directa de la BD** (no cifras tipeadas): viajes por usuarios externos, replanificaciones, completados, entrevistas registradas, paraderos de facto detectados. **Excluir** el tráfico propio (marcar sesiones del equipo con bandera).

> 🤖 **NOTA PARA EL AGENTE CONSTRUCTOR:** **prohibido** sembrar datos falsos para inflar el panel. Datos simulados deben llevar `is_simulated=true` y **no contarse** como tracción. El jurado puede abrir la BD/panel y preguntar de dónde salió cada número.

---

## 12. Plan de trabajo por horas y checklist de entrega

> Referencia horaria: construcción hasta 00:00 (pausa 14:00–15:00 y 19:00–20:00), opción de dormir 00:00–09:00, **entrega 09:00**. Asumo inicio efectivo ~14:00–15:00 → **unas 18 horas útiles**. Ajustar según el tiempo real.

### 12.1 Fases
| Fase | Horas | Objetivo | Salida verificable |
|---|---|---|---|
| **0 Decisiones** | 0–1 | Eje, stack, roles, **aclarar rúbrica en Discord**, canjear créditos necesarios | Decisiones anotadas en `DECISIONS.md`; primer `project update` |
| **1 Datos** | 1–4 | Overpass sobre el eje, curar rutas, cargar a PostGIS | Dataset del eje + `DATA_SOURCES.md` |
| **2 Motor** | 2–7 | `routing-engine` con tests (Pareto, relajación, replan) | Tests en verde; 10 viajes de oro |
| **3 API + Web mobile-first** | 4–9 | `/plan`, UI S1–S4, mapa | **Primera versión desplegada** y probada en incógnito |
| **4 Seguimiento y replan** | 8–12 | S5–S8, `events`, feedback | Flujo completo extremo a extremo |
| **5 Tracción** | desde la hora 9 | Entrevistas, pedir a participantes que usen la app, panel S9 | Eventos reales en BD |
| **6 Motor 2** | 10–15 | Ingesta de pings, detector, DBSCAN, simulador, capa en mapa | Demo del simulador funcionando |
| **7 Sponsors P1/P2** | 12–16 | Alertas Tavily/Exa, worker en Maritime; luego memoria/n8n/Zavu si sobra | Integraciones con fallback |
| **8 Entrega** | 16–18 (**antes de las 08:00**) | README, descripción, slides, **`project submit`**, prueba en incógnito | Entrega registrada (`andes project`) |

> 🤖 **NOTA PARA EL AGENTE CONSTRUCTOR:** **entrega una versión temprana (hora ~9) y corrígela después** (la guía lo permite). No dejes `submit` para las 08:55. **Congela cambios arriesgados a las 07:00.**

### 12.2 Checklist de entrega (todo debe ser verdadero)
- [ ] URL pública funciona en **ventana privada**, sin sesión y sin localhost.
- [ ] El flujo S1→S4 + seguir/replan funciona **sin intervención del equipo**.
- [ ] El "modo demo" permite mostrar el viaje sin GPS real y marca lo **simulado**.
- [ ] Repo público/accesible, **sin `.env`**, con `.env.example`, README, arquitectura, tests, commits claros.
- [ ] README/descripción: problema, usuario, cómo funciona, **limitaciones**, **qué quedó fuera**, fuentes de datos, privacidad.
- [ ] Slides accesibles por URL (Canva/Google Slides/web).
- [ ] Panel de tracción muestra solo datos reales; `VALIDATION.md` con entrevistas reales.
- [ ] Bitácora (`project update`) con decisiones, bloqueos y validaciones, **sin secretos ni datos personales**.
- [ ] `andes project` confirma los cuatro datos guardados.

---

## 13. Guion de demo (3 minutos) y preguntas probables

### 13.1 Guion (cronometrado, sobre la URL pública)
- **0:00–0:30 · Problema.** *"Valeria vuelve de clases con S/ 8 y una mochila pesada. Su ruta exige caminar 600 m por una avenida oscura entre dos servicios. Maps no le dice si le conviene un taxi solo en ese tramo ni cuánto gastará en total."* + 1 dato real de las entrevistas.
- **0:30–2:30 · Demo (un solo viaje ensayado):**
  1. Origen/destino en el eje; condiciones: S/ 8, ≤ 300 m seguidos, taxi sí.
  2. **Tres alternativas**; abrir "Menos caminata": taxi puente de ~1,4 km, +S/ X, caminata seguida 850 m → 90 m; chips *CONFIRMADO/ESTIMADO*; paradero 🟡 de facto en el mapa.
  3. Bajar presupuesto a S/ 4 → **infactible con relajación mínima** ("+S/ 2,50 o +320 m").
  4. **"Algo cambió":** "gasté S/ 2,50 y me bajé aquí" → recálculo con S/ 5,50 desde la posición nueva.
  5. (Si hay Motor 2) **simulador**: aparece un paradero inferido (rotulado SIMULADO).
  6. Mostrar el **panel de tracción** con datos reales del día.
- **2:30–3:00 · Cómo está hecho.** Un diagrama: motor de ruteo multicriterio (grafo en memoria, Pareto, relajación), PostGIS + DBSCAN para paraderos inferidos, datos OSM/ATU (con lo curado a mano dicho con honestidad), integraciones de sponsors con fallback.

### 13.2 Preguntas del jurado y respuestas que deben estar listas
| Pregunta probable | Respuesta honesta |
|---|---|
| "¿Qué lo diferencia de Google Maps?" | Optimiza con **presupuesto y caminata como restricciones duras**, inserta taxi **solo en el tramo crítico**, recalcula con **saldo restante** y marca lo estimado vs. confirmado |
| "¿De dónde salen los datos de cústers?" | OSM + curado manual del eje (documentado); no hay horarios fiables, por eso las esperas son estimadas |
| "¿El precio del taxi es real?" | **Estimado**; el usuario confirma en su app de taxi. No contratamos taxis |
| "¿Esto escala a toda Lima?" | Hoy cubre un eje; el motor es agnóstico; el cuello es la calidad de datos, no el algoritmo |
| "¿El detector de paraderos funciona?" | Implementado; verificado con trazas **simuladas**; recogiendo datos reales; umbrales por calibrar |
| "¿Cuánta gente lo usó?" | La cifra **real** del panel (externos), más cuántas entrevistas se hicieron |
| "¿Qué pasa con la privacidad del GPS?" | IDs anónimos, solo agregados públicos, sin trazas individuales expuestas |
| "¿Qué haría falta para producción?" | Convenios de datos con ATU/operadores, calibración de tarifas, validación de accesibilidad, pruebas con más zonas |
| "¿Por qué grafo en memoria y no pgRouting?" | Menor complejidad y latencia para un eje acotado; PostGIS para persistencia y clustering |

---

## 14. Errores y exageraciones de Gemini detectados

1. **Dos rúbricas contradictorias** tratadas como una (sección 2). Afirmó que la tracción "ahora es solo extra" sin verificar cuál rige.
2. **ElevenLabs** como sponsor: **no aparece** en el deck ni en la guía.
3. **Comando incorrecto:** `andes team track:environmental`; el real es `andes team track --track <valor>`.
4. **Zavu "Plan Pro"**: el deck dice solo "3 meses".
5. **">150 rutas de cústers en OSM"**, "70 % de los viajes", tarifas concretas, ATU GeoJSON: **sin fuente**.
6. **Fórmula de taxi** dada con dos coeficientes distintos (1,20 y 1,25) y sin calibración.
7. **Qatom** presentado como motor de reservas de taxi: encaje dudoso (sección 7.9).
8. **pgRouting/PostGIS para ruteo:** sobredimensionado para el plazo.
9. **Ignoró la regla de la URL pública** al recomendar app nativa (sección 9).
10. **Umbrales GPS** (15 m, 40 s) presentados como firmes: son hipótesis a calibrar.
11. **Prometió "5/5 asegurado"** en varios criterios: no se puede garantizar; depende de ejecución y datos reales.
12. Habló de **"5,5 puntos"**: mezcla la escala 1–5 con el bonus; no es una rúbrica oficial.

---

## 15. NOTAS CRÍTICAS Y REGLAS DURAS PARA EL AGENTE CONSTRUCTOR

> Léelas **antes** de codificar. Son el resultado de revisar críticamente toda la conversación.

**R1 — Primero datos, luego algoritmo.** Prueba Overpass en el eje y mide cobertura antes de escribir el motor. Si OSM no alcanza, **cura a mano** unas pocas rutas y **documéntalo**. Datos inventados = descalificación moral y técnica.

**R2 — Alcance mínimo viable explícito.** Un **eje**, **3–6 rutas**, **P0 completo** antes de tocar P1. Si dudas, recorta. Un producto pequeño que funciona en vivo vale más que uno ambicioso que falla (pitch de 3 min, corte al minuto 3).

**R3 — La demo corre en la PC del jurado, en incógnito.** Nada de localhost, nada de dependencia de tu sesión, **modo demo sin GPS**, datos precargados, cero pasos de login manual. Prueba en una ventana privada **en otra máquina** antes de entregar.

**R4 — Honestidad de datos en la UI.** Etiquetas `CONFIRMADO`/`ESTIMADO` + fuente + fecha. Lo simulado **siempre** rotulado `SIMULADO`. Nunca prometas accesibilidad ni seguridad.

**R5 — El usuario controla sus restricciones.** Prohibido relajar presupuesto/caminata automáticamente. Siempre botón de consentimiento.

**R6 — Tracción real o nada.** Sin datos sembrados ni tráfico propio contado como externo. Marca sesiones del equipo. El panel lee de la BD.

**R7 — Privacidad del GPS.** IDs anónimos, solo agregados públicos, sin teléfono junto a trazas, política en README. No publicar datos personales en la bitácora ni en la descripción (la guía lo exige).

**R8 — Cada sponsor, con razón y con fallback.** No integrar por cantidad. Prioridad: Tavily/Exa y Maritime → AtomicMemory/n8n → Zavu → (Qatom, Lovable solo con caso honesto). Ninguna integración puede ser punto único de falla de la demo.

**R9 — No dupliques lógica.** Dominio en `routing-engine` (puro, con tests); app, API y WhatsApp son adaptadores.

**R10 — Calidad de repo (20 % o parte del 40 %).** Commits pequeños y claros, tipado, capas, tests del motor, README con diagrama de arquitectura y sección "Decisiones, tradeoffs y qué quedó fuera", `.env.example`, **cero secretos** (si una clave se filtra, rotarla de inmediato).

**R11 — Entrega temprana.** Primer `project submit` con los 4 datos hacia la hora ~9; mejorar después. Congelar cambios arriesgados a las 07:00. Recordar que se guarda una **copia** cuando la organización abre la evaluación.

**R12 — Bitácora útil.** Un `project update` tras cada hito (datos cargados, motor listo, primera URL pública, primeras pruebas con usuarios, bloqueos). Solo hechos verificables.

**R13 — Resiliencia.** Timeouts, caché, fallback ante OSRM/Tavily/LLM; el NL nunca es la única forma de ingresar condiciones; respuesta parcial si el motor excede el tiempo.

**R14 — Aclarar la rúbrica** (sección 2) y reportar la respuesta en `DECISIONS.md`.

**R15 — Guardar el PDF de rúbrica** en `/docs` si el usuario lo aporta y reconciliar con este documento.

### Riesgos principales (ordenados por gravedad)
1. **Calidad/cobertura de datos de rutas** (puede invalidar todo el motor).
2. **Demo fallida en PC ajena** (URL, incógnito, GPS, dependencias).
3. **Sobrealcance** (taxi compartido, NL, memoria, WhatsApp, n8n, Apify a la vez).
4. **Tracción insuficiente** si la rúbrica de la guía rige (30 %).
5. **Motor 2 sin datos reales** → depender del simulador y decirlo.
6. **Integraciones decorativas** que el jurado percibe como relleno.
7. **Fugas de secretos/datos personales** en repo/bitácora/descripción.
8. **Taxi compartido real** (emparejar usuarios en el mismo nodo/momento): demasiado riesgo para un día; dejar como simulado o alcance futuro.

---

## 16. Decisiones pendientes y próximos pasos

**Por decidir (equipo):**
- [ ] **Eje de Lima** (propuesta: Javier Prado – Arequipa – Universitaria, o el eje que más conozcan; lo importante es que tengan datos y usuarios cerca).
- [ ] **Stack** definitivo (Expo + web recomendado; backend Node/TS vs. Python).
- [ ] **Sponsors a integrar** (sección 7.5).
- [ ] **Taxi compartido:** ¿simulado o fuera de alcance?
- [ ] **Roles** (3 frentes: Datos+Motor / Motor 2+Sponsors / Frontend+Tracción).
- [ ] **Aclarar rúbrica** con la organización.
- [ ] **Subir el PDF de rúbrica** a esta carpeta.

**Pasos sugeridos (en orden):**
1. Aclarar rúbrica y elegir eje.
2. Correr Overpass en el eje y evaluar los datos reales.
3. Definir/curar el dataset y las tarifas con fuente.
4. Esqueleto del repo + migraciones + `routing-engine` con tests.
5. API `/plan` + UI S1–S4 → **primer despliegue público**.
6. Seguimiento/replan + eventos + tracción (empezar a pedir uso real).
7. Motor 2 + simulador.
8. Sponsors P1 (Tavily/Exa, Maritime) y luego P2.
9. README, slides, `project submit`, prueba en incógnito en otra máquina.

---
*Fin del documento (v2). Fuentes: chat de Gemini del 17/10/2026 (lectura completa) · `hacktheandes.com/deck/onboarding` y `hacktheandes.com/guide` (lectura directa) · búsquedas web sobre Qatom, AtomicMemory, Maritime y Zavu (verificar en documentación oficial).*
