pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.content.base
import qs.components.views.keybinds

// The keybinds page: Hyprland's binds by section, as cards in columns,
// with a search over labels, sections and keys
BaseView {
  id: root

  readonly property real pageWidth: root.grid.unit * 2.6 + OverlayConfig.cardSpacing
  readonly property int columnCount: Math.max(1, Math.floor(root.pageWidth / (root.grid.unit * 0.8)))

  readonly property string query: KeybindManager.query.trim().toLowerCase()

  function _matches(text) {
    return !!text && text.toLowerCase().includes(root.query);
  }

  function _bindMatches(bind) {
    return root._matches(bind.label) || bind.combos.some(combo => combo.mods.concat(combo.keys).some(key => root._matches(key)));
  }

  // From the binds and the search only, so nothing rebuilds while it's shown
  readonly property var sections: {
    const all = KeybindManager.keybindings.filter(section => section.binds.length > 0);
    if (root.query === "")
      return all;
    return all.map(section => {
      const binds = root._matches(section.title) ? section.binds : section.binds.filter(bind => root._bindMatches(bind));
      return binds.length > 0 ? Object.assign({}, section, {
        "binds": binds
      }) : null;
    }).filter(section => section !== null);
  }

  // Masonry: each section goes to the shortest column, by row count
  readonly property var columns: {
    const result = [];
    const heights = [];
    for (let i = 0; i < root.columnCount; i++) {
      result.push([]);
      heights.push(0);
    }
    for (const section of root.sections) {
      const target = heights.indexOf(Math.min(...heights));
      result[target].push(section);
      heights[target] += 1.5 + section.binds.length + (section.undescribed ? 2 : 0);
    }
    return result;
  }

  Item {
    implicitWidth: root.pageWidth
    implicitHeight: root.grid.span(4)

    TitledCard {
      color: Theme.background
      title: I18n.tr("Keybinds")
      showActions: false

      headerExtras: RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Widget.spacing
        Layout.bottomMargin: Widget.spacing
        spacing: Widget.spacing * 2

        StyledTextEntry {
          id: search
          Layout.fillWidth: true
          Layout.preferredHeight: Widget.height
          placeholderText: I18n.tr("Search keybinds")
          Component.onCompleted: input.text = KeybindManager.query
          onTextChanged: KeybindManager.query = text
        }

        StyledText {
          text: I18n.tr("{0} binds", KeybindManager.count)
          opacity: 0.6
        }
      }

      StyledText {
        visible: root.query !== "" && root.sections.length === 0
        text: I18n.tr("No keybinds match \"{0}\"", KeybindManager.query)
        opacity: 0.6
        Layout.fillWidth: true
        Layout.topMargin: Widget.padding
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Widget.spacing * 2

        Repeater {
          model: root.columnCount

          delegate: ColumnLayout {
            id: column
            required property int index
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.alignment: Qt.AlignTop
            spacing: Widget.spacing * 2

            Repeater {
              model: root.columns[column.index]

              delegate: KeybindSection {
                required property var modelData
                section: modelData
              }
            }
          }
        }
      }
    }
  }
}
