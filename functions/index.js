const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

/**
 * Escucha cambios en productos y envía notificación push
 * cuando el stock baja de 5 unidades o llega a 0.
 *
 * Requisitos:
 *   - Cada producto debe tener un campo 'uid' con el ID del usuario propietario.
 *   - Cada usuario debe tener su FCM token guardado en la colección
 *     'fcm_tokens/{uid}' con un campo 'token'.
 */
exports.notificarStockBajo = functions.firestore
    .document('productos/{docId}')
    .onWrite(async (change, context) => {
      const producto = change.after.exists ? change.after.data() : null;
      const anterior = change.before.exists ? change.before.data() : null;

      // Solo notificar si el producto aún existe
      if (!producto) {
        console.log('Producto eliminado, no se envía notificación.');
        return null;
      }

      const stockActual = producto.stock ?? 0;
      const stockAnterior = anterior?.stock ?? 0;

      // Solo notificar si el stock BAJÓ y está en nivel crítico
      if (stockActual >= stockAnterior || stockActual > 5) {
        return null;
      }

      const uid = producto.uid;
      if (!uid) {
        console.log(`Producto ${context.params.docId} sin uid, omitiendo.`);
        return null;
      }

      // Obtener el FCM token del usuario
      let tokenDoc;
      try {
        tokenDoc = await db.collection('fcm_tokens').doc(uid).get();
      } catch (err) {
        console.error('Error al leer fcm_tokens:', err);
        return null;
      }

      if (!tokenDoc.exists) {
        console.log(`Usuario ${uid} no tiene token FCM registrado.`);
        return null;
      }

      const token = tokenDoc.data().token;
      if (!token) {
        console.log(`Token vacío para usuario ${uid}.`);
        return null;
      }

      const nombre = producto.nombre || 'Producto';
      const mensaje = stockActual === 0
          ? `"${nombre}" se ha agotado. Repón el stock.`
          : `"${nombre}" tiene solo ${stockActual} unidades. Stock bajo.`;

      const payload = {
        notification: {
          title: '⚠️ Stock Bajo',
          body: mensaje,
        },
        token,
      };

      try {
        const response = await admin.messaging().send(payload);
        console.log(`Notificación enviada a ${uid}: ${response}`);
        return response;
      } catch (err) {
        // Si el token ya no es válido, eliminarlo
        if (err.code === 'messaging/registration-token-not-registered' ||
            err.code === 'messaging/invalid-registration-token') {
          console.log(`Token inválido para ${uid}, eliminando.`);
          await db.collection('fcm_tokens').doc(uid).delete();
        } else {
          console.error('Error al enviar notificación:', err);
        }
        return null;
      }
    });

/**
 * También notifica cuando se agrega un producto nuevo
 * que ya nace con stock bajo.
 */
exports.notificarStockBajoAlCrear = functions.firestore
    .document('productos/{docId}')
    .onCreate(async (snap, context) => {
      const producto = snap.data();
      const stock = producto.stock ?? 0;

      if (stock > 5) {
        return null;
      }

      const uid = producto.uid;
      if (!uid) return null;

      let tokenDoc;
      try {
        tokenDoc = await db.collection('fcm_tokens').doc(uid).get();
      } catch (err) {
        return null;
      }

      if (!tokenDoc.exists) return null;

      const token = tokenDoc.data().token;
      if (!token) return null;

      const nombre = producto.nombre || 'Producto';
      const mensaje = stock === 0
          ? `"${nombre}" se agregó con stock 0.`
          : `"${nombre}" se agregó con solo ${stock} unidades.`;

      try {
        await admin.messaging().send({
          notification: {
            title: '⚠️ Stock Bajo',
            body: mensaje,
          },
          token,
        });
      } catch (err) {
        if (err.code === 'messaging/registration-token-not-registered') {
          await db.collection('fcm_tokens').doc(uid).delete();
        }
      }

      return null;
    });
