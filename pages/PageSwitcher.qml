import QtQuick 2.0

Item {
  id: root

  property Component mainPage: Qt.createComponent("MainPage.qml")
  property Component settingsPage: Qt.createComponent("SettingsPage.qml")

  function gotoPage(component) {
    if (page) page.destroy()
    page = component.createObject(root)
  }

  function gotoMainPage() {
    gotoPage(mainPage)
  }

  function gotoSettingsPage() {
    gotoPage(settingsPage)
  }

  property DPage page
  Component.onCompleted: {
    gotoMainPage()
  }
}
