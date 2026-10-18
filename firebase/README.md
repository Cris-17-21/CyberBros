# Firebase en Cyberon

Productos usados (ver `cyberon-arquitectura.md`, sec. 8): **Authentication** (correo y contraseña),
**Cloud Firestore** con reglas versionadas en este directorio, y **FCM** más adelante (Incremento B).

La app habla con Firebase Auth por su API REST, así que **no necesita `google-services.json`**:
solo la clave de API web.

## Configuración (una vez, en tu cuenta de Google)

1. Instala las herramientas y entra con tu cuenta:
   ```powershell
   npm install -g firebase-tools
   firebase login
   ```
2. Crea el proyecto (o usa uno existente) y registra una app web:
   ```powershell
   firebase projects:create cyberon-lima --display-name "Cyberon"
   firebase apps:create WEB "Cyberon" --project cyberon-lima
   firebase apps:sdkconfig WEB --project cyberon-lima
   ```
   El último comando muestra `apiKey`: es la **clave de API web**.
3. En la consola → **Authentication → Método de acceso**, activa **Correo electrónico/contraseña**.
4. En la consola → **Firestore Database**, crea la base en modo producción (región `southamerica-east1`).
5. Publica las reglas e índices desde esta carpeta:
   ```powershell
   cd firebase
   firebase deploy --only firestore --project cyberon-lima
   ```
6. Ejecuta la app con la clave:
   ```powershell
   cd ..\app\cyber_bros
   flutter run -d <dispositivo> --dart-define=FIREBASE_API_KEY=<apiKey>
   ```

Sin la clave la app sigue funcionando como invitado.

## Reglas

`firestore.rules` deniega todo por defecto (RNF-29). Los casos negativos obligatorios
(A no lee a B; invitado no lee cuentas; el cliente no escribe `isTeamMember` ni `config`) deben
probarse con el Emulator Suite: `firebase emulators:start --only auth,firestore`.

## Pendiente

- Pruebas automatizadas de las reglas con el emulador.
- Guardar el historial de viajes en Firestore (RF-34) y vincular al invitado con la cuenta (RF-33).
- Cuota del plan gratuito: revisarla antes de la demo (RNF-05, RNF-06).
