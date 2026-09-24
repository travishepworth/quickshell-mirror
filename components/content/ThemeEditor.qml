pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.reusable
import qs.components.forms
import qs.components.content.base

// The theme list: one entry per theme (a dark/light pair is one theme),
// stock and generated, plus the light mode switch that picks the variant.
// Themes apply immediately, so there's nothing to save.
TitledCard {
  id: root

  readonly property var family: ThemeManager.currentFamily
  // Rebuilt only when the theme folders are rescanned
  readonly property var stockFamilies: ThemeManager.themeFamilies.filter(family => !family.generated)
  readonly property var generatedFamilies: ThemeManager.themeFamilies.filter(family => family.generated)

  title: I18n.tr("Theme")
  showActions: false

  headerExtras: SchemaSwitch {
    label: "Light mode" // I18n.tr("Light mode")
    // Translated by SchemaSwitch: I18n.tr("This theme has no light variant.")
    // I18n.tr("This theme has no dark variant.") I18n.tr("Switch between the theme's dark and light variants.")
    description: !root.family || (root.family.dark && root.family.light) ? "Switch between the theme's dark and light variants." : root.family.dark ? "This theme has no light variant." : "This theme has no dark variant."
    checked: !Appearance.darkMode
    enabled: !!root.family?.dark && !!root.family?.light
    onToggled: value => ThemeManager.setLightMode(value)
  }

  component FamilyButton: StyledTextButton {
    required property var modelData
    readonly property bool current: root.family !== null && (root.family.dark || root.family.light) === (modelData.dark || modelData.light)
    Layout.fillWidth: true
    text: modelData.label
    backgroundColor: current ? Theme.accent : Theme.backgroundHighlight
    textColor: current ? Theme.background : Theme.foreground
    onClicked: ThemeManager.applyFamily(modelData)
  }

  SchemaSection {
    title: "Themes" // I18n.tr("Themes")
    Layout.leftMargin: Widget.padding
    Layout.rightMargin: Widget.padding

    Repeater {
      model: root.stockFamilies
      delegate: FamilyButton {}
    }
  }

  SchemaSection {
    title: "Generated Themes" // I18n.tr("Generated Themes")
    // Translated by SchemaSection: I18n.tr("Generating from the wallpaper...")
    // I18n.tr("Made from your wallpaper when you pick one.")
    description: ThemeManager.isGenerating ? "Generating from the wallpaper..." : "Made from your wallpaper when you pick one."
    Layout.leftMargin: Widget.padding
    Layout.rightMargin: Widget.padding

    Repeater {
      model: root.generatedFamilies
      delegate: FamilyButton {}
    }

    StyledText {
      visible: root.generatedFamilies.length === 0
      text: I18n.tr("None yet")
      opacity: 0.6
    }
  }
}
