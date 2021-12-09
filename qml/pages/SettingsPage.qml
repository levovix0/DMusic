import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import DMusic 1.0
import ".."
import "../components"
import "settings"

DPage {
  id: root
  property real scroll: 0

  ScrollView {
    id: _scroll
    anchors.fill: parent
    clip: true
    leftPadding: 10
    bottomPadding: 10
    rightPadding: 10
    topPadding: _label.visible? 30 : 10

    ScrollBar.vertical.policy: ScrollBar.AlwaysOff
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    MouseArea {
      width: root.width
      height: _layout.height
      onClicked: GlobalFocus.item = ""

      ColumnLayout {
        id: _layout
        width: root.width
        spacing: 40

        DText {
          id: _label
          Layout.alignment: Qt.AlignHCenter
          visible: root.height >= 400

          font.pointSize: 28

          text: qsTr("Settings")
        }

        Loader {
          Layout.alignment: Qt.AlignHCenter
          sourceComponent: root.width >= 1040? _wide_blocks : _mini_blocks
        }
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
