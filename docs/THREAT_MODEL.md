# Modelo de amenazas: datos colaborativos

## La amenaza

En 2020 el artista Simon Weckert paseó unos 99 teléfonos en un carrito por una calle vacía de
Berlín y Google Maps la mostró como atascada: los teléfonos se movían a paso de peatón y el sistema
interpretó "mucha gente lenta" como tráfico. **Un sistema que infiere el mundo a partir de
ubicaciones de usuarios es manipulable si cree todo lo que recibe.**

En Cyberon la **única** función que aprende de ubicaciones es la inferencia de paraderos de facto
([`stop_inference.dart`](../app/cyber_bros/lib/features/trip_planner/domain/stop_inference.dart)).
El cálculo de rutas, costos y esperas **no usa** velocidades ni densidades de usuarios: no hay
"tráfico colaborativo", así que el ataque del carrito no tiene un parámetro que mover.

## Activos y atacantes

| Activo | Qué se quiere evitar |
|---|---|
| Mapa de paraderos inferidos | Inventar un paradero que no existe, o hacer desaparecer uno real |
| Confianza de cada paradero | Inflarla con datos falsos |
| Métricas de tracción | Inflarlas con cuentas o tráfico automatizado |

Atacantes considerados: una persona con un carrito de teléfonos, un script que crea cientos de
sesiones desde una IP, y un grupo pequeño de usuarios reales coordinados.

## Defensa en capas

| Capa | Defensa | Dónde está |
|---|---|---|
| **1. Radio de impacto** | Los datos colaborativos nunca modifican datos oficiales; solo **añaden** puntos marcados "inferido" | `InferredStop` es un tipo aparte |
| **2. Plausibilidad física** | Exige espera quieta ≥ 40 s y luego velocidad de vehículo sostenida; rechaza saltos imposibles (> 70 m/s), marcas de tiempo desordenadas, precisión sospechosamente perfecta y constante; la trayectoria posterior debe seguir una ruta conocida | `BoardingDetector` |
| **3. Anti-Sybil** | Se cuentan **fuentes independientes** (`nEff`), no sesiones: las que viajan juntas o llegan al mismo instante se fusionan; tope por fuente (dispositivo/IP); 1 evento por sesión, punto y día | `_independentGroups`, `maxPerSource` |
| **4. Cuarentena y reversión** | Un candidato es visible solo con `nEff ≥ 3`, llegadas dispersas ≥ 2 min y ≥ 2 ventanas de 30 min; la confianza decae a la mitad cada 14 días; se puede invalidar un lote y bloquear una fuente | `inferStops`, `invalidate`, `blockSource` |
| **Auditoría** | Cada descarte o cuarentena queda registrado con su causa, sin datos personales | `StopInferenceEngine.log` |

## Pruebas obligatorias (corren en CI)

Todas en [`test/stop_inference_test.dart`](../app/cyber_bros/test/stop_inference_test.dart) y
[`test/stop_lab_screen_test.dart`](../app/cyber_bros/test/stop_lab_screen_test.dart):

| Prueba | Resultado verificado |
|---|---|
| **Carrito**: 99 sesiones caminando a ~1.2 m/s durante 10 min | **0** eventos y **0** paraderos |
| **Carrito + auto**: 99 sesiones co-ubicadas que suben a un auto | `nEff = 1`, el candidato **no** es visible |
| Lo mismo con rutas conocidas | Ni siquiera llega a ser evento (`offRoute`) |
| **Bots dispersos**: 20 sesiones de una misma IP con llegadas escalonadas | Topadas por fuente (`nEff ≤ 2`), no superan la cuarentena |
| **Control positivo**: 5 personas independientes y escalonadas | **Sí** se promueve el paradero, a < 10 m del real |
| **Reversión**: invalidar un lote de eventos | El paradero desaparece en el siguiente recálculo |
| Llegadas simultáneas de fuentes distintas | Se tratan como una sola |
| Decaimiento | Confianza a la mitad a los 14 días; expira a los 90 |

## Otras superficies

* **Tracción**: el panel debe excluir cuentas del equipo y datos simulados; las reglas de Firestore
  limitan los contadores a incrementos de 1 (limitación declarada: un cliente malicioso podría
  falsear los suyos).
* **Alertas externas**: el texto recuperado de la web es dato, no instrucción.
* **Lenguaje natural**: el texto solo puede producir los campos del esquema validado
  (`ParsedConditions`); es un analizador de reglas, sin interpolar en consultas.
* **Taxi compartido**: solo cuentas con sesión; las salas guardan paraderos, no la ubicación de las
  personas; solo la creadora cierra la sala. El cupo lo controla el cliente.

## Riesgos residuales (honestos)

* Un atacante con **muchos dispositivos reales, fuentes distintas y paciencia** puede aportar
  evidencia plausible. Las capas lo encarecen y lo hacen visible y reversible, no imposible.
* Los umbrales están calibrados con **trazas sintéticas**, no con datos reales: hay que ajustarlos
  con usuarios reales antes de confiar en el resultado.
* Hoy la inferencia corre en el cliente y se demuestra con el simulador. Con usuarios reales
  haría falta un backend de confianza que reciba las trazas, las valide y las agregue; ese
  servidor aplicaría los mismos módulos.
* No hay detección de anomalías por celda ni límite de sesiones nuevas por IP a nivel de red
  (requieren servidor).
