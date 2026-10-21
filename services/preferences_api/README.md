# preferences_api — condiciones recordadas (RF-26)

Backend ligero en Dart (`shelf`, sec. 9 de `cyberon-arquitectura.md`) que permite a una cuenta
**guardar, usar, corregir y olvidar** sus condiciones de viaje de siempre (presupuesto, caminata
seguida y total, taxi puente y prioridad) en [Atomic Memory](https://docs.atomicstrata.ai).

* **Opcional:** sin `TRIP_MEMORY_API_URL` en la app la tarjeta no aparece; sin
  `ATOMICMEMORY_API_URL`/`ATOMICMEMORY_API_KEY` la API responde `503 MEMORY_DISABLED`.
* **Con consentimiento:** solo guarda cuando la persona pulsa "Guardar mis condiciones" (`consent:
  true`). Nunca aplica nada a los controles sin que pulse "Usar estas".
* **Identidad del servidor:** el token de Firebase Auth se verifica con `accounts:lookup`; el sujeto
  de memoria es `rutealo-firebase-<uid>`. El cliente no puede elegirlo.
* **Mínimo de datos:** se guarda una frase con las cinco condiciones. Ni correo, ni nombre, ni
  ruta, ni ubicación.
* **Latencia acotada:** 3 s para verificar la cuenta, 2 s por llamada a Atomic Memory y **5 s en
  total por solicitud**; la app corta a los 8 s. Ante un fallo dice "No pudimos confirmar que se
  guardó" o "No pudimos consultar" en vez de fingir éxito, y el formulario sigue igual.
* **Guardar y olvidar se confirman, nunca por un 2xx:** la documentación de Atomic Memory no
  promete que repetir el `externalId` actualice el registro, así que corregir no depende de eso.
  Se crea el registro nuevo (se acepta cualquier 2xx, p. ej. `201`), se exige su id confirmado
  (`stored_memory_ids`/`updated_memory_ids`), se relee **por id** y se comparan las condiciones;
  recién entonces se borra el anterior, se comprueba por id que ya no existe (un `200` que deja el
  registro no cuenta) y al final se busca por `externalId`. Olvidar borra y comprueba por id y por
  `externalId` que ya no existe. Si un paso no se confirma, responde `503` y no borra nada más.
* **La clave no sale a otro destino:** ninguna solicitud sigue redirecciones (un `3xx` es un fallo).
  La URL de Atomic Memory debe ser HTTPS (HTTP solo hacia `127.0.0.1`/`localhost`), sin
  usuario/contraseña, consulta ni fragmento; si no, o si falta la clave, la memoria queda apagada
  con un aviso y el servidor arranca igual. El emulador de Auth solo se acepta en `127.0.0.1` o
  `localhost`.
* **No toca el motor:** el ruteo, las tarifas y la relajación siguen siendo deterministas y
  locales.

## Por qué un servicio aparte

La clave de Atomic Memory no puede ir en la app, así que hace falta un servidor. El plan gratuito de
Firebase no admite Cloud Functions (riesgo R8 de `cyberon-arquitectura.md`), y
`services/whatsapp_bot` es un cliente de WhatsApp (Baileys) sin HTTP. Por eso este es el "backend
ligero en Dart" de la sec. 9 de la arquitectura, reducido a lo mínimo: tres operaciones, sin base
de datos propia, y apagado salvo que se configure.

## API

Todas exigen `Authorization: Bearer <token de Firebase Auth>`.

| Método | Ruta | Respuesta |
|---|---|---|
| `GET` | `/v1/trip-conditions` | `{status: "found", conditions}` o `{status: "empty"}` |
| `PUT` | `/v1/trip-conditions` con `{consent: true, conditions}` | `{status: "saved", conditions}` |
| `DELETE` | `/v1/trip-conditions` | `{status: "deleted"}` o `{status: "empty"}` |

Errores: `401 UNAUTHENTICATED`, `400 CONSENT_REQUIRED | INVALID_CONDITIONS`,
`503 MEMORY_DISABLED | MEMORY_UNAVAILABLE | IDENTITY_UNAVAILABLE`.

En Atomic Memory se usa un único registro por cuenta (rutas documentadas de la API HTTP):

* `POST /v1/memories/ingest/quick` con `skip_extraction: true`, `content_class: "summary"` y
  `metadata.externalId = "rutealo-trip-conditions-v1"`.
* `GET /v1/memories/by-external-id/rutealo-trip-conditions-v1?user_id=…` para recordar.
* `GET /v1/memories/{id}?user_id=…` para confirmar lo guardado y lo borrado.
* `DELETE /v1/memories/{id}?user_id=…` para olvidar o reemplazar.

## Variables

| Variable | Uso |
|---|---|
| `FIREBASE_API_KEY` | Clave web pública del proyecto (obligatoria). |
| `FIREBASE_AUTH_EMULATOR_HOST` | Opcional, solo `127.0.0.1:<puerto>` o `localhost:<puerto>`. |
| `ATOMICMEMORY_API_URL` | Opcional, p. ej. `https://api.atomicstrata.ai` (HTTPS, o HTTP solo local). |
| `ATOMICMEMORY_API_KEY` | Clave del proyecto de Atomic Memory. **Solo en el servidor.** |
| `ALLOWED_ORIGINS` | Orígenes de la app web separados por comas. |
| `HOST` / `PORT` | Por defecto `127.0.0.1:8787`. |

## Ejecutar

```bash
cd services/preferences_api
dart pub get
FIREBASE_API_KEY=... ATOMICMEMORY_API_URL=https://api.atomicstrata.ai \
ATOMICMEMORY_API_KEY=... ALLOWED_ORIGINS=http://localhost:8085 dart run bin/server.dart

# App (desde app/cyber_bros)
flutter run -d chrome --dart-define=TRIP_MEMORY_API_URL=http://127.0.0.1:8787
```

### Desarrollo sin credenciales

`test/support/atomic_memory_fixture.dart` es un **fixture local de prueba, no Atomic Memory**: imita en
memoria solo las rutas anteriores, y `POST /__fixture/mode` permite simular fallos (`failing`,
`deleteRetains`, `redirecting`, …). Junto con el Firebase Auth Emulator (no necesita Java ni
Firestore: sin emulador de Firestore el historial en la nube falla en silencio, como ya hace la app)
permite probar todo sin tocar producción. Así se grabó la demo de `docs/media/condiciones-recordadas/`:

```bash
# firebase.json local con "emulators": {"auth": {"host": "127.0.0.1", "port": 9455}}
npx firebase-tools@15.19.1 emulators:start --only auth --project demo-rutealo --config <ese-json>
PORT=4721 dart run test/support/atomic_memory_fixture.dart
PORT=4719 FIREBASE_API_KEY=demo-local-key FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9455 \
ATOMICMEMORY_API_URL=http://127.0.0.1:4721 ATOMICMEMORY_API_KEY=fixture-key \
ALLOWED_ORIGINS=http://127.0.0.1:4720 dart run bin/server.dart
# App (desde app/cyber_bros); 127.0.0.1:9 hace que Firestore falle rápido y local.
flutter build web --release --no-web-resources-cdn \
  --dart-define=FIREBASE_API_KEY=demo-local-key \
  --dart-define=FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9455 \
  --dart-define=FIRESTORE_EMULATOR_HOST=127.0.0.1:9 \
  --dart-define=TRIP_MEMORY_API_URL=http://127.0.0.1:4719
python3 -m http.server 4720 --bind 127.0.0.1 -d build/web
```

## Pruebas

```bash
dart analyze && dart test
```

## Limitaciones

* Solo cuentas con sesión: un invitado no tiene una identidad verificable en el servidor.
* Al eliminar la cuenta (RF-35, aún no implementado) habrá que llamar también a
  `DELETE /v1/trip-conditions`.
* Sin límite de solicitudes por cuenta todavía.
* La documentación de Atomic Memory no detalla los campos de respuesta. Se asume que las lecturas
  devuelven `id`, `user_id` y `metadata` (directo o dentro de `memory`), y que la ingesta devuelve
  `stored_memory_ids`/`updated_memory_ids`. Falta verificarlo contra el servicio real; si no
  coinciden, la API responde `503` (nunca un éxito falso).
* Las pruebas y la demo usan el fixture local, no el servicio real.
