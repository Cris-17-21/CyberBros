const {
  default: makeWASocket,
  DisconnectReason,
  useMultiFileAuthState
} = require('@whiskeysockets/baileys');
const pino = require('pino');
const { planTrip, formatWhatsAppResponse } = require('./planner');

const TARGET_PHONE_NUMBER = '51915111037';

async function startBot() {
  console.log('🤖 Iniciando Rutéalo WhatsApp Bot...');
  const { state, saveCreds } = await useMultiFileAuthState('./auth_info_baileys');

  const sock = makeWASocket({
    auth: state,
    logger: pino({ level: 'silent' }),
    browser: ['Ubuntu', 'Chrome', '20.0.04'],
    printQRInTerminal: false
  });

  sock.ev.on('creds.update', saveCreds);

  if (!sock.authState.creds.registered) {
    setTimeout(async () => {
      try {
        console.log(`📲 Solicitando código de vinculación para el número: ${TARGET_PHONE_NUMBER}...`);
        const code = await sock.requestPairingCode(TARGET_PHONE_NUMBER);
        console.log('\n======================================================');
        console.log(`🔑 TU CÓDIGO DE VINCULACIÓN ES: ${code}`);
        console.log('======================================================\n');
      } catch (err) {
        console.error('Error solicitando pairing code:', err);
      }
    }, 4000);
  }

  sock.ev.on('connection.update', (update) => {
    const { connection, lastDisconnect } = update;

    if (connection === 'close') {
      const statusCode = lastDisconnect?.error?.output?.statusCode;
      const shouldReconnect = statusCode !== DisconnectReason.loggedOut;
      console.log(`⚠️ Conexión cerrada (status ${statusCode}). Reconectando:`, shouldReconnect);
      if (shouldReconnect) {
        startBot();
      }
    } else if (connection === 'open') {
      console.log('\n======================================================');
      console.log('✅ ¡Rutéalo Bot conectado exitosamente a WhatsApp!');
      console.log('🚀 Listo para responder mensajes de usuarios en tiempo real.');
      console.log('======================================================\n');
    }
  });

  sock.ev.on('messages.upsert', async (m) => {
    try {
      const msg = m.messages[0];
      if (!msg || msg.key.fromMe || !msg.message) return;

      const remoteJid = msg.key.remoteJid;

      // Ignorar grupos (@g.us) y difusiones/estados (@broadcast)
      if (!remoteJid || remoteJid.endsWith('@g.us') || remoteJid.endsWith('@broadcast')) {
        return;
      }

      const body =
        msg.message.conversation ||
        msg.message.extendedTextMessage?.text ||
        '';

      const cleanText = body.trim();
      if (!cleanText) return;

      console.log(`📩 Mensaje recibido de ${remoteJid}: "${cleanText}"`);

      const lower = cleanText.toLowerCase();

      // 1. Mensaje de bienvenida / ayuda
      if (
        lower === 'hola' ||
        lower === 'buenas' ||
        lower === 'ayuda' ||
        lower === 'menu' ||
        lower === 'start' ||
        lower === 'info'
      ) {
        const welcome =
          `👋 *¡Hola! Soy Rutéalo, tu asistente de movilidad inteligente en Lima.*\n\n` +
          `Escríbeme tu viaje en un solo mensaje indicando de dónde sales y a dónde vas. Por ejemplo:\n\n` +
          `👉 *De Avenida Tacna a Plaza Butters*\n` +
          `👉 *De Miraflores a Javier Prado con 5 soles*\n` +
          `👉 *Angamos a Wilson*\n\n` +
          `Te calcularé en segundos la mejor opción en corredor ATU, caminata y taxi UberX con precios oficiales y tiempos en hora punta. 🚍🚖`;

        await sock.sendMessage(remoteJid, { text: welcome }, { quoted: msg });
        return;
      }

      function extractTripQuery(text) {
        let clean = text.trim().replace(/[?¿!.,]+$/, '');
        // 1. "Estoy en X y quiero ir a Y" / "Estoy en X y voy a Y"
        const m1 = clean.match(/^estoy\s+en\s+(.+?)\s+y\s+(?:quiero\s+ir|voy|deseo\s+ir|para\s+ir)\s+a\s+(.+?)(?:\s+(?:con|presupuesto)\s+(?:s\/?\.?\s*)?(\d+(?:\.\d+)?)\s*soles?)?$/i);
        if (m1) return { origin: m1[1].trim(), dest: m1[2].trim(), budget: m1[3] ? parseFloat(m1[3]) : 15.0 };

        // 2. "Cómo voy/llego de X a Y" o "De X a Y"
        const m2 = clean.match(/^(?:c[oó]mo\s+(?:voy|llego|llegar|ir)\s+)?de\s+(.+?)\s+(?:a|hacia)\s+(.+?)(?:\s+(?:con|presupuesto)\s+(?:s\/?\.?\s*)?(\d+(?:\.\d+)?)\s*soles?)?$/i);
        if (m2) return { origin: m2[1].trim(), dest: m2[2].trim(), budget: m2[3] ? parseFloat(m2[3]) : 15.0 };

        // 3. "X a Y" o "X hacia Y"
        const m3 = clean.match(/^(.+?)\s+(?:a|hacia)\s+(.+?)(?:\s+(?:con|presupuesto)\s+(?:s\/?\.?\s*)?(\d+(?:\.\d+)?)\s*soles?)?$/i);
        if (m3 && !['hola', 'buenas', 'gracias', 'ok', 'alguna', 'ayuda', 'info'].includes(m3[1].toLowerCase().trim())) {
          return { origin: m3[1].trim(), dest: m3[2].trim(), budget: m3[3] ? parseFloat(m3[3]) : 15.0 };
        }

        return null;
      }

      const query = extractTripQuery(cleanText);

      if (query) {
        const { origin, dest, budget } = query;

        await sock.sendMessage(
          remoteJid,
          { text: `⏳ Calculando la ruta más conveniente entre *${origin}* y *${dest}*...` },
          { quoted: msg }
        );

        const plan = await planTrip(origin, dest, budget);
        const replyText = formatWhatsAppResponse(plan);

        await sock.sendMessage(remoteJid, { text: replyText }, { quoted: msg });
        return;
      }

      // 3. Si no reconoció el formato de viaje
      const hint =
        `👋 Recibí tu mensaje pero no identifiqué el origen y destino.\n\n` +
        `Podés escribirme de estas formas:\n` +
        `👉 *De Avenida Tacna a Plaza Butters*\n` +
        `👉 *Estoy en Av. Arequipa y quiero ir a Jr. Huallaga*\n` +
        `👉 *Miraflores a San Isidro con 5 soles*\n\n` +
        `_Rutéalo · Transporte resiliente en Lima_`;

      await sock.sendMessage(remoteJid, { text: hint }, { quoted: msg });
    } catch (err) {
      console.error('Error procesando mensaje:', err);
    }
  });
}

startBot();
