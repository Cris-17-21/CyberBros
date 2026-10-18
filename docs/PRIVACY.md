# Privacidad

Resumen en lenguaje llano: Cyberon guarda lo mínimo para funcionar, **no guarda trazas de tu
ubicación** y puedes usarla sin cuenta.

## Qué se guarda

| Dato | Dónde | Para qué | Quién lo ve |
|---|---|---|---|
| Correo, nombre (opcional) y fecha de alta | Firebase Auth y `users/{uid}` | Tu cuenta | Solo tú |
| Tus viajes: origen, destino, límites, recorrido elegido y estado | Tu dispositivo y, con cuenta, Firestore `users/{uid}/trips` | Tu historial y repetir un viaje | Solo tú |
| Salas de taxi compartido: paraderos, tu primer nombre | Firestore `taxi_pools` | Repartir un taxi | Personas con cuenta que buscan el mismo tramo |
| Preferencias de notificaciones | Tu dispositivo | Avisos del viaje | Solo tú |

## Qué NO se guarda

* **Trazas GPS**: la ubicación se usa en el momento para ubicarte y guiarte, y no se envía ni se
  almacena. El laboratorio de paraderos usa trazas **sintéticas**.
* Contraseñas: nunca pasan por nuestro código; las gestiona Firebase Auth.
* Teléfono, dirección de casa o ubicación exacta de personas.
* Ningún dato personal aparece en métricas públicas ni en la bitácora del proyecto.

## Invitados

Sin cuenta, el historial vive **solo en tu dispositivo** y se conserva hasta 30 días. Si luego
inicias sesión, los viajes de invitado se suben a tu cuenta.

## Control

* Puedes **borrar un viaje** cuando quieras: se elimina de tu cuenta y de todos tus dispositivos.
* Puedes **apagar las notificaciones** (todas o por tipo) en Mi perfil.
* Puedes **cerrar sesión**; el historial de la cuenta deja de verse en ese dispositivo.

## Seguridad

Las reglas de Firestore ([`firebase/firestore.rules`](../firebase/firestore.rules)) deniegan todo
por defecto: cada persona solo lee y escribe lo suyo, y los campos sensibles no los puede cambiar el
cliente.

## Limitaciones honestas

* **Eliminar la cuenta completa** y sus datos desde la app **aún no está implementado**; hoy se
  pueden borrar los viajes uno por uno.
* **No hay pantalla de consentimiento** separada para ubicación; el permiso lo pide el sistema
  operativo solo cuando pulsas "usar mi ubicación" o inicias el seguimiento.
* La verificación del correo no está activada.
