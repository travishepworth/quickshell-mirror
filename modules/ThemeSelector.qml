pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import qs.config
import qs.services
import qs.components.reusable
import qs.components.widgets.popouts
import qs.components.widgets.menu

// does the job for now. On the plan for a good re-write
Item {
  id: themeSelectorRoot

  // --- Configuration ---
  readonly property int wallpaperPreviewSize: 120
  readonly property int columnSpacing: Widget.padding * 2
  readonly property int internalPadding: Widget.padding

  Connections {
    target: ThemeManager
    function onGenerationFailed(errorText) {
      Notifs.sendNotification("Theme Generation", "Failed to generate themes", "There was an error while processing the wallpaper. Details: " + errorText, {});
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: EdgePopout {
      id: root
      required property ShellScreen modelData

      screen: modelData
      edge: Bar.Top
      position: 0.5
      triggerLength: 50
      closeOnClickOutside: true

      content: Component {
        Item {
          implicitWidth: mainLayout.implicitWidth + themeSelectorRoot.internalPadding * 2
          implicitHeight: mainLayout.implicitHeight + themeSelectorRoot.internalPadding * 2

          RowLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: themeSelectorRoot.internalPadding
            spacing: themeSelectorRoot.columnSpacing

            //=================================================================
            // LEFT: Wallpaper Grid
            //=================================================================
            StyledScrollView {
              id: wallpaperScrollView
              Layout.fillHeight: true

              Layout.preferredWidth: themeSelectorRoot.wallpaperPreviewSize * 1 + themeSelectorRoot.internalPadding * 3
              Layout.preferredHeight: (themeSelectorRoot.wallpaperPreviewSize + themeSelectorRoot.internalPadding) * 3

              contentPadding: themeSelectorRoot.internalPadding
              showScrollBar: true

              GridView {
                id: wallpaperGrid
                width: wallpaperScrollView.availableWidth
                model: ThemeManager.wallpaperModel
                cellWidth: themeSelectorRoot.wallpaperPreviewSize + themeSelectorRoot.internalPadding
                cellHeight: themeSelectorRoot.wallpaperPreviewSize + themeSelectorRoot.internalPadding

                delegate: Item {
                  required property var modelData
                  width: wallpaperGrid.cellWidth
                  height: wallpaperGrid.cellHeight

                  property bool isActive: Appearance.wallpaper === modelData.fileUrl
                  property bool isHovered: wallpaperMouseArea.hovered
                  Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                  Rectangle {
                    anchors.fill: parent
                    anchors.margins: 0
                    radius: Appearance.borderRadius
                    border.width: Appearance.borderWidth * 2
                    border.color: isActive ? Theme.accent : (isHovered ? Theme.accentAlt : "transparent")
                    clip: true

                    Behavior on border.color {
                      ColorAnimation {
                        duration: Appearance.animNormal
                      }
                    }

                    Image {
                      id: wallpaperImage
                      anchors.fill: parent
                      source: modelData.fileUrl
                      fillMode: Image.PreserveAspectCrop
                      asynchronous: true
                    }

                    MouseArea {
                      id: wallpaperMouseArea
                      anchors.fill: parent
                      hoverEnabled: true
                      property bool hovered: false
                      cursorShape: Qt.PointingHandCursor
                      onClicked: ThemeManager.setWallpaperAndGenerate(modelData.fileUrl)
                      onEntered: hovered = true
                      onExited: hovered = false
                    }
                  }
                }
              }

              StyledText {
                anchors.centerIn: parent
                text: "No wallpapers found in pictures/wallpapers"
                textColor: Theme.foregroundAlt
                visible: ThemeManager.wallpaperModel.count === 0 && !ThemeManager.isGenerating
              }

              Rectangle {
                anchors.fill: parent
                color: "#99000000"
                radius: Appearance.borderRadius
                visible: ThemeManager.isGenerating

                BusyIndicator {
                  anchors.centerIn: parent
                  running: parent.visible
                }
              }
            }

            //=================================================================
            // RIGHT: Controls
            //=================================================================
            ColumnLayout {
              Layout.preferredWidth: 250
              Layout.fillHeight: true
              spacing: themeSelectorRoot.internalPadding

              // --- Dark Mode Toggle ---
              StyledContainer {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                backgroundColor: Theme.background
                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: themeSelectorRoot.internalPadding
                  anchors.rightMargin: themeSelectorRoot.internalPadding

                  StyledText {
                    text: "Dark?"
                    Layout.fillWidth: true
                  }
                  StyledSwitch {
                    // CORRECTED: Bind 'checked' to the actual dark mode state.
                    checked: Appearance.darkMode
                
                    // CORRECTED: Disable the switch if auto-switching is off or there's no paired theme.
                    enabled: Appearance.autoThemeSwitch && ThemeManager.currentTheme.paired
                
                    onToggled: ThemeManager.toggleDarkMode()
                  }
                }
              }

              // --- Theme Source Tabs ---
              TabBar {
                id: themeSourceTabs
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                tabs: [
                  {
                    name: "Stock"
                  },
                  {
                    name: "Pywal"
                  }
                ]
                onTabClicked: index => themeStack.currentIndex = index
              }

              // --- Theme Lists (in a Stack) ---
              StackLayout {
                id: themeStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: themeSourceTabs.currentTab

                // View for Default Themes
                StyledScrollView {
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  contentPadding: themeSelectorRoot.internalPadding
                  showScrollBar: true

                  ListView {
                    model: ThemeManager.defaultThemes
                    spacing: themeSelectorRoot.internalPadding / 2
                    delegate: StyledTextButton {
                      required property var modelData
                      width: parent.width
                      text: modelData.name
                      backgroundColor: Appearance.theme === modelData.name ? Theme.accent : Theme.backgroundHighlight
                      textHoverColor: Appearance.theme === modelData.name ? Theme.foreground : Theme.background
                  
                      // CORRECTED: Specify that this is NOT a generated theme.
                      onClicked: ThemeManager.applyTheme(modelData.name, false)
                    }
                  }

                  StyledText {
                    anchors.centerIn: parent
                    text: "No default themes found."
                    textColor: Theme.foregroundAlt
                    visible: ThemeManager.defaultThemes.count === 0
                  }
                }

                // View for Generated (Pywal) Themes
                StyledScrollView {
                  Layout.fillWidth: true
                  Layout.fillHeight: true
                  contentPadding: themeSelectorRoot.internalPadding
                  showScrollBar: true

                  ListView {
                    model: ThemeManager.generatedThemes
                    spacing: themeSelectorRoot.internalPadding / 2
                    delegate: StyledTextButton {
                      required property var modelData
                      width: parent.width
                      text: modelData.name
                      backgroundColor: Appearance.theme === ("generated/" + modelData.name) ? Theme.accent : Theme.backgroundHighlight
                      textHoverColor: Appearance.theme === ("generated/" + modelData.name) ? Theme.foreground : Theme.background
                  
                      // CORRECTED: Specify that this IS a generated theme.
                      onClicked: ThemeManager.applyTheme(modelData.name, true)
                    }
                  }

                  StyledText {
                    anchors.centerIn: parent
                    text: "Select a wallpaper to generate themes."
                    textColor: Theme.foregroundAlt
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    visible: ThemeManager.generatedThemes.count === 0
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
