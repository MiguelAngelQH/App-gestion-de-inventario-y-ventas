import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import fs from 'fs';
import path from 'path';

function loadServiceAccount(): Record<string, unknown> | null {
  const keyFromEnv = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
  if (keyFromEnv) {
    try { return JSON.parse(keyFromEnv); } catch { /* ignore */ }
  }

  const paths = [
    path.join(process.cwd(), 'service-account.json'),
    ...(process.env.GOOGLE_APPLICATION_CREDENTIALS
      ? [process.env.GOOGLE_APPLICATION_CREDENTIALS]
      : []),
  ];

  for (const p of paths) {
    try {
      if (fs.existsSync(p)) {
        return JSON.parse(fs.readFileSync(p, 'utf-8'));
      }
    } catch { /* ignore */ }
  }

  return null;
}

if (!getApps().length) {
  const serviceAccount = loadServiceAccount();

  if (serviceAccount) {
    initializeApp({
      credential: cert(serviceAccount as Record<string, string>),
      projectId: (serviceAccount.project_id as string) || undefined,
    });
  } else {
    throw new Error(
      'No se encontró service-account.json. ' +
      'Coloca el archivo en la raíz del proyecto o configura ' +
      'FIREBASE_SERVICE_ACCOUNT_KEY en .env.local'
    );
  }
}

export const db = getFirestore();
export const auth = getAuth();
