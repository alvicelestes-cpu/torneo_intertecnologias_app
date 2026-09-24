{{flutter_js}}
{{flutter_build_config}}

// Interceptar y desactivar cualquier registro de Service Worker en loadEntrypoint
if (window._flutter && window._flutter.loader) {
  var originalLoadEntrypoint = window._flutter.loader.loadEntrypoint;
  if (typeof originalLoadEntrypoint === 'function') {
    window._flutter.loader.loadEntrypoint = function(options) {
      options = options || {};
      options.serviceWorkerVersion = null;
      options.serviceWorker = null;
      return originalLoadEntrypoint.call(window._flutter.loader, options);
    };
  }
}

// Añadir parámetro de versión dinámica/timestamp a mainJsPath para invalidar caché en cada carga
if (window._flutter && window._flutter.buildConfig && window._flutter.buildConfig.builds) {
  var buildTimestamp = new Date().getTime();
  window._flutter.buildConfig.builds.forEach(function(b) {
    if (b.mainJsPath) {
      b.mainJsPath = b.mainJsPath + '?v=' + buildTimestamp;
    }
  });
}

// Cargar la aplicación SIN registrar ningún Service Worker con caché offline agresiva
_flutter.loader.load({
  serviceWorkerSettings: null,
});
