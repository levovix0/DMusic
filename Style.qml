pragma Singleton
import QtQuick 2.0

QtObject {
  property QtObject text: QtObject {
    property color color: "#FFFFFF"
    property string font: "Roboto"
  }
  property QtObject panel: QtObject {
    property color background: "#262626"
  }
  property QtObject window: QtObject {
    property color background: "#181818"
  }
}
