pragma Singleton
import QtQuick

// Weather shared by every widget that shows it: one WeatherSource per
// distinct location + units, created while some widget wants it and
// refreshed at the shortest interval asked for.
//   WeatherManager.acquire(owner, { latitude, longitude, location, units, intervalMinutes })
//   WeatherManager.release(owner)
//   WeatherManager.sourceFor(request)   // .weather .current .condition .place …
QtObject {
  id: root

  // key -> WeatherSource
  property var sources: ({})

  function acquire(owner, request) {
    _registry.acquire(owner, {
      "key": keyFor(request),
      "latitude": request?.latitude ?? "",
      "longitude": request?.longitude ?? "",
      "location": request?.location ?? "",
      "units": request?.units ?? "celsius",
      "intervalMinutes": request?.intervalMinutes ?? 30
    });
  }

  function release(owner) {
    _registry.release(owner);
  }

  // The shared source for a request, or an idle placeholder with the same
  // API until it exists
  function sourceFor(request) {
    return root.sources[keyFor(request)] ?? root._placeholder;
  }

  function keyFor(request) {
    return [request?.latitude ?? "", request?.longitude ?? "", request?.location ?? "", request?.units ?? "celsius"].join("|");
  }

  // -- Private --
  property ConsumerRegistry _registry: ConsumerRegistry {}
  readonly property var _requests: _registry.requests
  on_RequestsChanged: _sync()

  property WeatherSource _placeholder: WeatherSource {
    active: false
  }

  property Component _sourceComponent: Component {
    WeatherSource {}
  }

  // Creates the sources now wanted, retimes the kept ones, destroys the rest
  function _sync() {
    const wanted = {};
    for (const r of root._requests) {
      const w = wanted[r.key];
      wanted[r.key] = w ? Object.assign(w, {
        "intervalMinutes": Math.min(w.intervalMinutes, r.intervalMinutes)
      }) : Object.assign({}, r);
    }
    const next = {};
    for (const key in wanted) {
      const w = wanted[key];
      const source = root.sources[key] ?? root._sourceComponent.createObject(root, {
        "latitude": w.latitude,
        "longitude": w.longitude,
        "location": w.location,
        "units": w.units,
        "intervalMinutes": w.intervalMinutes
      });
      source.intervalMinutes = w.intervalMinutes;
      next[key] = source;
    }
    for (const key in root.sources) {
      if (!(key in next))
        root.sources[key].destroy();
    }
    root.sources = next;
    console.log("[WeatherManager] sources:", Object.keys(next).length, "for", root._requests.length, "consumers");
  }
}
