import { initializeApp, getApps } from "firebase/app";
import { getAuth } from "firebase/auth";

function readConfig() {
  return {
    apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || "",
    authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || "",
    projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || "",
    storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || "",
    messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || "",
    appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || "",
  };
}

/** @returns {import('firebase/app').FirebaseApp | null} */
export function getFirebaseApp() {
  const cfg = readConfig();
  if (!cfg.apiKey || !cfg.projectId) {
    return null;
  }
  if (!getApps().length) {
    initializeApp(cfg);
  }
  return getApps()[0];
}

/** @returns {import('firebase/auth').Auth | null} */
export function getFirebaseAuth() {
  const app = getFirebaseApp();
  return app ? getAuth(app) : null;
}

export function isFirebaseConfigured() {
  const c = readConfig();
  return Boolean(c.apiKey && c.projectId);
}
