export const runtime = 'nodejs';

const script = `let firebaseReady = false;

function tryImport(url) {
  try {
    importScripts(url);
    return true;
  } catch (_err) {
    return false;
  }
}

const localReady =
  tryImport("/firebase/firebase-app-compat.js") &&
  tryImport("/firebase/firebase-messaging-compat.js");

if (!localReady) {
  const remoteReady =
    tryImport("https://www.gstatic.com/firebasejs/10.12.5/firebase-app-compat.js") &&
    tryImport("https://www.gstatic.com/firebasejs/10.12.5/firebase-messaging-compat.js");

  firebaseReady = remoteReady;
  if (!remoteReady) {
    console.warn("Failed to load Firebase messaging scripts.");
  }
} else {
  firebaseReady = true;
}

if (firebaseReady && self.firebase && self.firebase.messaging) {
  firebase.initializeApp({
    apiKey: "AIzaSyDuWuOT_PzhonVC8jIZn9OqxSHruOrDobc",
    authDomain: "tawssi.firebaseapp.com",
    projectId: "tawssi",
    storageBucket: "tawssi.firebasestorage.app",
    messagingSenderId: "746654963305",
    appId: "1:746654963305:web:a9858d9e05dc50b84bb4f8"
  });

  const messaging = firebase.messaging();

  messaging.onBackgroundMessage(function(payload) {
    const notification = payload.notification || {};
    const title = notification.title || "Notification";
    const options = {
      body: notification.body || "",
      icon: "/delivery-notification.svg",
      badge: "/delivery-notification.svg",
      data: payload.data || {}
    };
    self.registration.showNotification(title, options);
  });
} else {
  console.warn("Firebase messaging not initialized in service worker.");
}
`;

export function GET() {
  return new Response(script, {
    headers: {
      'Content-Type': 'application/javascript; charset=utf-8',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Service-Worker-Allowed': '/'
    }
  });
}
