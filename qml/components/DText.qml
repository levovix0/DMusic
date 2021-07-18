import QtQuick 2.0
import DMusic 1.0

Text {
  property var style: Style.window.text
  color: style.color
  font.pointSize: 10
  font.family: style.font
}
