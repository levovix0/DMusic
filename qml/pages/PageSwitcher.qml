import QtQuick 2.0

Loader {
  id: root

  property var pageHistory: []

  function gotoPage(src) {
    if (source) pageHistory.push(source)
    source = src
  }

  function back() {
    if (pageHistory.length > 0) {
      source = pageHistory.pop()
    }
  }

  function gotoPageOrBack(src) {
    if (source == src && pageHistory.length > 0) {
      back()
    }
    else {
      gotoPage(src)
    }
  }


  onLoaded: {
    item.switcher = gotoPage
  }

  function gotoMainPage() {
    gotoPage("qrc:/qml/pages/MainPage.qml")
  }

  function gotoSettingsPage() {
    gotoPageOrBack("qrc:/qml/pages/SettingsPage.qml")
  }

  property DPage page
  Component.onCompleted: {
    gotoMainPage()
  }
}
