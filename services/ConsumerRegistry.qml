import QtQuick

// Reference-counted consumers of a shared poller (SystemManager,
// PackageUpdates): each owner registers one request, and the service polls
// for the union of them, stopping when there are none. Not a singleton:
// each service owns one.
QtObject {
  id: registry

  // [{ owner, request }]
  property var consumers: []
  readonly property bool active: consumers.length > 0
  readonly property var requests: consumers.map(c => c.request)

  // Registers or replaces `owner`'s request. Re-registering an identical
  // request is a no-op, so a consumer that re-registers often can't churn
  // every binding derived from the requests (see the 25 GB note in
  // CLAUDE.md).
  function acquire(owner, request) {
    const existing = registry.consumers.find(c => c.owner === owner);
    if (existing && JSON.stringify(existing.request) === JSON.stringify(request))
      return;
    registry.consumers = registry.consumers.filter(c => c.owner !== owner).concat([
      {
        "owner": owner,
        "request": request
      }
    ]);
  }

  function release(owner) {
    if (registry.consumers.some(c => c.owner === owner))
      registry.consumers = registry.consumers.filter(c => c.owner !== owner);
  }
}
