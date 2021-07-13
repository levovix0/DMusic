import QtQuick 2.0

Loader {
  id: root

  function gotoPage(src) {
    source = src
  }

  onLoaded: {
    item.switcher = gotoPage
  }

  function gotoMainPage() {
    gotoPage("qrc:/qml/pages/MainPage.qml")
  }

  function gotoSettingsPage() {
    gotoPage("qrc:/qml/pages/SettingsPage.qml")
  }

  property DPage page
  Component.onCompleted: {
    gotoMainPage()
  }
}
