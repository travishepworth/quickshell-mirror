pragma Singleton
import QtQuick

/**
 * Upgrades older config.json layouts to the current one (see
 * config/json/config.schema.json). Pure functions only: ConfigManager runs
 * migrate() on load, then writes the result back once.
 *
 * The version history was reset: the current layout is version 1, so there
 * are no steps yet. When the layout changes, bump currentVersion (and the
 * schema's version default) and add a step to migrate():
 *
 *   if (version < 2)
 *     result = _v1ToV2(result, secrets, changes);
 *
 * Secrets (chat API keys) found in a config belong in `secrets`, so they
 * never get written back into config.json.
 */
QtObject {
  id: root

  readonly property int currentVersion: 1

  /**
   * @param config  Parsed config.json (not modified)
   * @return { config, secrets, changes, migrated }
   *   secrets: { backendName: apiKey } pulled out of the old config
   *   changes: human-readable list of what was done, for the log
   */
  function migrate(config) {
    let result = JSON.parse(JSON.stringify(config ?? {}));
    const secrets = {};
    const changes = [];
    const version = result.version ?? 1;

    return {
      config: result,
      secrets: secrets,
      changes: changes,
      migrated: version < root.currentVersion
    };
  }
}
