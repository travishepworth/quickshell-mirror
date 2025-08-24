pragma Singleton
import QtQml
import "root:/themes" as Themes

QtObject {
    // Map theme names to their singleton objects
    readonly property var registry: {
        return {
            // "Catppuccin": Themes.Catppuccin,
            // "Dracula":    Themes.Dracula,
            "Gruvbox":    Themes.Gruvbox
        };
    }

    function get(name) {
        return registry[name] || Themes.Gruvbox;
    }
}

