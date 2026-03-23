'use strict';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "/": "index.html",
  "main.dart.js": "main.dart.js-hash",
  "index.html": "index.html-hash",
  // Añade aquí otros recursos con sus respectivos hashes
};

// Durante la instalación del service worker, se cachean todos los recursos.
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(Object.keys(RESOURCES));
    })
  );
});

// Durante la activación del service worker, se eliminan las cachés antiguas.
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keyList) => {
      return Promise.all(keyList.map((key) => {
        if (key !== CACHE_NAME) {
          return caches.delete(key);
        }
      }));
    })
  );
});

// Intercepta las solicitudes de red para servir desde la caché primero.
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request);
    })
  );
});
