// firebase-messaging-sw.js
// Required for Flutter Web push notifications via Firebase Cloud Messaging.
// This file MUST be served from the root of your web app.

importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

// ── Firebase project config (fastway-64ae7) ────────────────────────────────
firebase.initializeApp({
  apiKey:            "AIzaSyAaT6iKDv5DyFSO-3aTG5GXocxoPk_0IR8",
  authDomain:        "fastway-64ae7.firebaseapp.com",
  projectId:         "fastway-64ae7",
  storageBucket:     "fastway-64ae7.firebasestorage.app",
  messagingSenderId: "914160982717",
  appId:             "1:914160982717:web:cd135bfe9284570dfff5d4",
  measurementId:     "G-DHHBVNBY1Z",
});

// ── Background message handler ────────────────────────────────────────────
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("[FCM SW] Background message received:", payload);

  const title = payload.notification?.title ?? "Fastway";
  const body  = payload.notification?.body  ?? "";
  const icon  = payload.notification?.icon  ?? "/favicon.png";

  self.registration.showNotification(title, {
    body,
    icon,
    data: payload.data ?? {},
    badge: "/favicon.png",
  });
});

// ── Notification click handler ────────────────────────────────────────────
self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  const data = event.notification.data ?? {};
  let url = "/";

  if (data.type === "order_placed" || data.type === "order_status" || data.type === "order_update") {
    url = data.order_id ? `/orders/${data.order_id}` : "/orders";
  } else if (data.type === "cart_abandonment") {
    url = "/cart";
  } else if (data.type === "return_submitted" || data.type === "return") {
    url = "/orders";
  } else if (data.type === "back_in_stock" && data.product_id) {
    url = `/products/${data.product_id}`;
  }

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes(self.location.origin) && "focus" in client) {
          client.navigate(url);
          return client.focus();
        }
      }
      return clients.openWindow(url);
    })
  );
});
