// qs/components/reusable/PipewireVolumeBar.qml
pragma ComponentBehavior: Bound
import QtQuick
import qs.services
import qs.components.reusable
import Quickshell.Services.Pipewire

Item {
  id: component

  // -- Signals --
  signal visibilityChanged(real volume)

  // -- Public API --
  property string targetApplication: ""
  property var excludedApps: []
  property bool useSystemVolume: false
  property alias orientation: bar.orientation
  property alias iconSource: bar.iconSource

  readonly property bool nodeFound: !useSystemVolume && _targetNode !== null && _targetNode.ready && _targetNode.audio
  property real volume: useSystemVolume ? AudioManager.volume : (nodeFound ? _targetNode.audio.volume : 0.0)
  property bool isMuted: useSystemVolume ? AudioManager.muted : (!nodeFound || _targetNode.audio.muted)

  // -- Configurable Appearance --
  // null

  // -- Implementation --
  implicitWidth: bar.implicitWidth
  implicitHeight: bar.implicitHeight

  property var _targetNode: null
  property bool _suppressNextVisibility: false

  // All candidate audio-stream nodes, kept persistently bound so their
  // .properties are populated (and stay populated) well before we need
  // to search them. Binding is async, so we can't just bind on demand.
  readonly property var _audioStreams: Pipewire.nodes.values.filter(n => n.isStream && n.audio)

  PwObjectTracker {
    objects: component._audioStreams.concat([component._targetNode])
  }

  // Re-run the search whenever any individual candidate node finishes
  // binding (node.ready flips true). This is what actually fixes the
  // race: tracking a node only *requests* a bind, it doesn't complete
  // it synchronously.
  Instantiator {
    model: component._audioStreams
    delegate: Item {
      id: streamWatcher
      required property var modelData
      Connections {
        target: streamWatcher.modelData
        function onReadyChanged() {
          if (streamWatcher.modelData.ready) {
            component._updateTargetNode();
          }
        }
      }
    }
  }

  StyledVolumeBar {
    id: bar
    anchors.fill: parent
    volumeLevel: component.volume
    isMuted: component.isMuted
    enabled: component.nodeFound || component.useSystemVolume
    onVolumeChanged: component.setVolume(newVolume)
    onVolumeLevelChanged: {
      if (component._suppressNextVisibility) {
        component._suppressNextVisibility = false;
        return;
      }
      component.visibilityChanged(component.volume);
    }
  }

  function setVolume(newVolume) {
    const clamped = Math.max(0.0, Math.min(1.0, newVolume));
    if (useSystemVolume) {
      AudioManager.volume = clamped;
      return;
    }
    if (nodeFound) {
      _targetNode.audio.volume = clamped;
    }
  }

  function toggleMute() {
    if (useSystemVolume) {
      AudioManager.muted = !AudioManager.muted;
      return;
    }
    if (nodeFound) {
      _targetNode.audio.muted = !_targetNode.audio.muted;
    }
  }

  onTargetApplicationChanged: _updateTargetNode()

  Component.onCompleted: {
    if (Pipewire.ready) {
      _updateTargetNode();
    }
  }

  Connections {
    target: Pipewire.nodes
    function onObjectInsertedPost(object, index) {
      if (Pipewire.ready) {
        component._updateTargetNode();
      }
    }
    function onObjectRemovedPost(object, index) {
      if (Pipewire.ready) {
        component._updateTargetNode();
      }
    }
  }

  Connections {
    target: Pipewire
    function onReadyChanged() {
      if (Pipewire.ready) {
        component._updateTargetNode();
      }
    }
  }

  function _setTargetNode(n) {
    if (_targetNode === n)
      return;
    _suppressNextVisibility = true;
    _targetNode = n;
  }

  function _updateTargetNode() {
    if (useSystemVolume || targetApplication === "") {
      if (_targetNode !== null)
        _setTargetNode(null);
      return;
    }
    const nodes = Pipewire.nodes.values;
    const searchString = targetApplication.toLowerCase();

    if (searchString === "master") {
      const excluded = (component.excludedApps || []).map(a => a.toLowerCase());
      for (let i = 0; i < nodes.length; ++i) {
        const n = nodes[i];
        if (!n.isStream || !n.audio || !n.ready) {
          continue;
        }
        const appBinary = n.properties["application.process.binary"]?.toLowerCase();
        const appName = n.properties["application.name"]?.toLowerCase();
        if (!appBinary && !appName) {
          continue;
        }
        const isExcluded = excluded.some(ex => (appBinary && appBinary.includes(ex)) || (appName && appName.includes(ex)));
        if (!isExcluded) {
          component._setTargetNode(n);
          return;
        }
      }
      // No eligible "master" node found (yet) - fall through so we still
      // clear a stale target below instead of silently keeping an old one.
    } else {
      for (let i = 0; i < nodes.length; ++i) {
        const n = nodes[i];
        if (!n.isStream || !n.audio || !n.ready) {
          continue;
        }
        const appBinary = n.properties["application.process.binary"]?.toLowerCase();
        const appName = n.properties["application.name"]?.toLowerCase();
        const appNickname = n.nickname?.toLowerCase();
        if ((appBinary && appBinary.includes(searchString)) || (appName && appName.includes(searchString)) || (appNickname && appNickname.includes(searchString))) {
          console.log("[PipewireVolumeBar] Found target node for", targetApplication, "->", appBinary || appName || appNickname);
          component._setTargetNode(n);
          return;
        }
      }
    }

    if (_targetNode !== null) {
      console.log("[PipewireVolumeBar] Lost target node for", targetApplication);
      component._setTargetNode(null);
    }
  }
}
