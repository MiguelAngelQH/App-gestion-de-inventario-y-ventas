import { readFileSync } from "fs";
import admin from "firebase-admin";

const serviceAccount = JSON.parse(
  readFileSync(new URL("./service-account.json", import.meta.url), "utf8")
);

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const collections = ["productos", "ventas", "compras", "clientes", "proveedores", "pagos"];

for (const name of collections) {
  const snapshot = await db.collection(name).get();
  if (snapshot.empty) {
    console.log(`Colección "${name}" ya está vacía`);
    continue;
  }
  let deleted = 0;
  const batches = [];
  let batch = db.batch();
  snapshot.docs.forEach((doc, i) => {
    batch.delete(doc.ref);
    deleted++;
    if (i % 499 === 498) {
      batches.push(batch.commit());
      batch = db.batch();
    }
  });
  batches.push(batch.commit());
  await Promise.all(batches);
  console.log(`Deleted ${deleted} docs from "${name}"`);
}

console.log("Firestore limpiado completamente");
process.exit(0);
