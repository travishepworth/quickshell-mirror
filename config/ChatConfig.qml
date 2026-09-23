pragma Singleton
import QtQuick
import qs.services

// Reader for the Chat section. API keys are not config: see SecretsManager.
QtObject {
  readonly property var _c: ConfigManager.config.Chat

  readonly property bool enabled: _c.enabled
  readonly property string defaultBackend: _c.defaultBackend
  readonly property var backends: _c.backends
  readonly property string defaultModel: backends[defaultBackend]?.defaultModel ?? ""
}
