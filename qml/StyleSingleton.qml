pragma Singleton
import QtQuick 2.0

QtObject {
  property QtObject text: QtObject {
    property color color: "#FFFFFF"
    property color categoryColor: "#829297"
    property color darkColor: "#808080"
    property string font: "Roboto"
  }
  property QtObject button: QtObject {
    property QtObject background: QtObject {
      property QtObject normal: QtObject {
        property color normal: "#262626"
        property color hover: "#303030"
        property color press: "#202020"
      }
      property QtObject panel: QtObject {
        property color normal: "#363636"
        property color hover: "#404040"
        property color press: "#303030"
      }
    }
  }
  property QtObject panel: QtObject {
    property color background: "#262626"
  }
  property QtObject block: QtObject {
    property color background: "#202020"
    property real radius: 10
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
  property color accent: "#FCE165"
}
