let firebaseReady = false;

try {
  importScripts("https://www.gstatic.com/firebasejs/10.12.5/firebase-app-compat.js");
  importScripts("https://www.gstatic.com/firebasejs/10.12.5/firebase-messaging-compat.js");
  firebaseReady = true;
} catch (err) {
  console.warn("Failed to load Firebase from gstatic, trying local fallback...", err);
  try {
    importScripts("/firebase/firebase-app-compat.js");
    importScripts("/firebase/firebase-messaging-compat.js");
    firebaseReady = true;
  } catch (fallbackErr) {
    console.error("Failed to load Firebase from local fallback", fallbackErr);
  }
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
      icon: "/logo_green.png",
      data: payload.data || {}
    };
    self.registration.showNotification(title, options);
  });
} else {
  console.warn("Firebase messaging not initialized in service worker.");
}
