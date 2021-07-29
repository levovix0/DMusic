import QtQuick 2.15
import QtQuick.Window 2.15
import DMusic 1.0
import "pages"
import "components"

Rectangle {
  id: root
  height: 40

  property size windowSize
  property bool clientSideDecorations
  property bool maximized

  color: Style.header.background

  Rectangle {
    width: root.width
    height: 1
    visible: false

    color: "#404040"
  }

  DragHandler {
    enabled: root.clientSideDecorations
    onActiveChanged: if (active) { _window.startSystemMove(); _root.focus = true }
    target: null
  }

  MouseArea {
    anchors.fill: root
    enabled: root.clientSideDecorations
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

    onDoubleClicked: if (mouse.button == Qt.LeftButton) _window.maximize()
    onClicked: if (mouse.button == Qt.MiddleButton) { _window.close() } else { _root.focus = true }

    TitleManualButton {
      id: _home
      anchors.verticalCenter: parent.verticalCenter
      anchors.left: parent.left
      icon: "qrc:/resources/title/home.svg"

      onClick: _pages.gotoMainPage()
    }

    TitleManualButton {
      id: _close
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      enabled: root.clientSideDecorations

      icon: "qrc:/resources/title/close.svg"
      style: Style.header.closeButton

      onClick: _window.close()
    }

    TitleManualButton {
      id: _maximize
      anchors.right: _close.left
      anchors.verticalCenter: parent.verticalCenter
      enabled: root.clientSideDecorations && root.width >= 715

      icon: "qrc:/resources/title/maximize.svg"

      onClick: _window.maximize()
    }

    TitleManualButton {
      id: _minimize
      anchors.right: _maximize.left
      anchors.verticalCenter: parent.verticalCenter
      enabled: root.clientSideDecorations && root.width >= 620

      icon: "qrc:/resources/title/minimize.svg"

      onClick: _window.minimize()
    }

    TitleManualButton {
      id: _settings
      anchors.verticalCenter: parent.verticalCenter
      anchors.right: _minimize.left
      icon: "qrc:/resources/title/settings.svg"

      onClick: _pages.gotoSettingsPage()
    }
  }

  DTextBox {
    id: _search
    anchors.centerIn: parent
    width: 300

    style: Style.header.searchBox
    Binding { target: _search; property: "style.background"; value: Config.darkHeader? (_search.text == ""? "#1C1C1C" : Style.panel.background) : "transparent" }
    hint: qsTr("search")

    MouseArea {
      anchors.fill: parent
      visible: parent.text === ""
      cursorShape: Qt.IBeamCursor
      onClicked: parent.input.focus = true
    }
  }

  ResizeArea {
    id: _lg
    width: 12
    x: -6
    height: windowSize.height - 12
    y: 6
    enabled: root.clientSideDecorations && !maximized

    cursor: Qt.SizeHorCursor
    edge: Qt.LeftEdge
  }

  ResizeArea {
    id: _rg
    anchors.right: root.right
    anchors.rightMargin: -6
    width: 12
    height: windowSize.height - 12
    y: 6
    enabled: root.clientSideDecorations && !maximized

    cursor: Qt.SizeHorCursor
    edge: Qt.RightEdge
  }

  ResizeArea {
    id: _tg
    width: windowSize.width - 12
    x: 6
    height: 12
    y: -6
    enabled: root.clientSideDecorations && !maximized

    cursor: Qt.SizeVerCursor
    edge: Qt.TopEdge
  }

  ResizeArea {
    id: _bg
    y: windowSize.height - 6
    width: windowSize.width - 12
    x: 6
    height: 12
    enabled: root.clientSideDecorations && !maximized

    cursor: Qt.SizeVerCursor
    edge: Qt.BottomEdge
  }


  ResizeArea {
    id: _ltg
    x: -6
    y: -6
    width: 12
    height: 12
    enabled: root.clientSideDecorations && !maximized

    cursor: Qt.SizeFDiagCursor
    edge: Qt.LeftEdge | Qt.TopEdge
  }

  ResizeArea {
    id: _rtg
    anchors.right: root.right
    anchors.rightMargin: -6
    y: -6
    width: 12
    height: 12
    enabled: root.clientSideDecorations && !maximized

    cursor: Qt.SizeBDiagCursor
    edge: Qt.RightEdge | Qt.TopEdge
  }

  ResizeArea {
    id: _lbg
    y: windowSize.height - 6
    x: -6
    width: 12
    height: 12
    enabled: root.clientSideDecorations && !maximized

    cursor: Qt.SizeBDiagCursor
    edge: Qt.LeftEdge | Qt.BottomEdge
  }

  ResizeArea {
    id: _rbg
    anchors.right: root.right
    anchors.rightMargin: -6
    y: windowSize.height - 6
    width: 12
    height: 12
    enabled: root.clientSideDecorations && !maximized

    cursor: Qt.SizeFDiagCursor
    edge: Qt.RightEdge | Qt.BottomEdge
  }
}
