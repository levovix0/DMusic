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
  property QtObject dropPlace: QtObject {
    property QtObject border: QtObject {
      property color color: "#7A7A7A"
      property real weight: 1
      property real radius: 5
    }
    property QtObject color: QtObject {
      property color normal: "transparent"
      property color hover: "#207A7A7A"
      property color drop: "#507A7A7A"
    }
  }
}
