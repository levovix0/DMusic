import QtQuick 2.15
import DMusic 1.0
import QtQuick.Layouts 1.15
import ".."
import "../components"
import "settings"

DPage {
  id: root
  property real scroll: 0
  property real maximumScroll: _layout.height - height + (_label.visible? 30 : 10) + 20

  function boundScroll() {
    var ms = maximumScroll > 0? maximumScroll : 0
    if (scroll < 0) scroll = 0
    else if (scroll > ms) scroll = ms
  }

  onScrollChanged: boundScroll()
  onHeightChanged: boundScroll()

  MouseArea {
    anchors.fill: parent

    onWheel: root.scroll -= wheel.angleDelta.y / 120 * 25

    ColumnLayout {
      id: _layout
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: (_label.visible? 30 : 10) - root.scroll
      spacing: 40

      DText {
        id: _label
        Layout.alignment: Qt.AlignHCenter
        visible: root.height >= 400

        font.pointSize: 28

        text: qsTr("Settings")
      }

      Loader {
        sourceComponent: root.width >= 1040? _wide_blocks : _mini_blocks
      }
    }
  }

  Component {
    id: _wide_blocks

    RowLayout {
      spacing: 20
      Layout.alignment: Qt.AlignHCenter

      ColumnLayout {
        Layout.alignment: Qt.AlignTop
        Layout.minimumWidth: 200
        Layout.maximumWidth: 250
        spacing: 20

        AccountsSettingsBlock { switcher: root.switcher }
        ColorSettingsBlock {}
      }

      ColumnLayout {
        Layout.alignment: Qt.AlignTop
        Layout.minimumWidth: 550
        Layout.maximumWidth: 600
        spacing: 20

        ThemeSettingsBlock {}
        GeneralSettingsBlock {}
      }

      ColumnLayout {
        Layout.alignment: Qt.AlignTop
        Layout.minimumWidth: 200
        Layout.maximumWidth: 250
        spacing: 20

        LanguageSettingsBlock {}
        DevelopersBlock {}
      }
    }
  }

  Component {
    id: _mini_blocks

    ColumnLayout {
      Layout.preferredWidth: 550
      spacing: 20
      Layout.alignment: Qt.AlignHCenter

      ThemeSettingsBlock {}
      GeneralSettingsBlock {}

      RowLayout {
        spacing: 20

        ColumnLayout {
          Layout.alignment: Qt.AlignTop
          Layout.preferredWidth: 215
          spacing: 20

          LanguageSettingsBlock {}
          DevelopersBlock {}
        }

        ColumnLayout {
          Layout.alignment: Qt.AlignTop
          Layout.preferredWidth: 215
          spacing: 20

          AccountsSettingsBlock { switcher: root.switcher }
          ColorSettingsBlock {}
        }
      }
    }
  }
}
