pragma Singleton
import QtQuick 2.15
import Config 1.0

QtObject {
  property bool darkTheme: Config.darkTheme
  property bool darkHeader: Config.darkHeader

  property color accent: "#FCE165"

  property QtObject window: QtObject {
    property color background: darkTheme? "#181818" : "#FFFFFF"

    property QtObject border: QtObject {
      property color color: darkTheme? "transparent" : "#D9D9D9"
      property real width: darkTheme? 0 : 2
    }

    property QtObject text: QtObject {
      property color color: darkTheme? "#FFFFFF" : "#404040"
      property color darkColor: "#808080"
      property string font: "Roboto"
    }

    property QtObject icon: QtObject {
      property color color: darkTheme? "#FFFFFF" : "#404040"
    }
  }

  property QtObject header: QtObject {
    property color background: darkHeader? "#151515" : "#FFFFFF"

    property QtObject border: QtObject {
      property color color: darkHeader? "transparent" : "#D9D9D9"
      property real width: darkHeader? 0 : 2
    }

    property QtObject text: QtObject {
      property color color: darkHeader? "#FFFFFF" : "#404040"
      property color darkColor: "#808080"
      property string font: "Roboto"
    }

    property QtObject button: QtObject {
      property QtObject color: QtObject {
        property color normal: darkHeader? "#FFFFFF" : "#404040"
        property color hover: normal
        property color pressed: normal
      }
      property QtObject background: QtObject {
        property color normal: "transparent"
        property color hover: darkHeader? "#303030" : "#F0F0F0"
        property color pressed: darkHeader? "#202020" : "#D0D0D0"
      }
    }

    property QtObject closeButton: QtObject {
      property QtObject color: QtObject {
        property color normal: darkHeader? "#FFFFFF" : "#404040"
        property color hover: "#FFFFFF"
        property color pressed: "#FFFFFF"
      }
      property QtObject background: QtObject {
        property color normal: "transparent"
        property color hover: "#E03649"
        property color pressed: "#C11B2D"
      }
    }
  }

  property QtObject panel: QtObject {
    property color background: darkTheme? "#262626" : "#FFFFFF"
    property bool shadow: true
    property real radius: 10

    property QtObject border: QtObject {
      property color color: "transparent"
      property real width: 0
    }

    property QtObject text: QtObject {
      property color color: darkTheme? "#FFFFFF" : "#404040"
      property color darkColor: "#808080"
      property string font: "Roboto"
    }

    property QtObject icon: QtObject {
      property color color: darkTheme? "#FFFFFF" : "#404040"
    }
  }

  property QtObject block: QtObject {
    property color background: darkTheme? "#262626" : "#FFFFFF"
    property bool shadow: true
    property real radius: 10

    property QtObject border: QtObject {
      property color color: darkTheme? "transparent" : "#D9D9D9"
      property real width: darkTheme? 0 : 2
    }

    property QtObject text: QtObject {
      property color color: darkTheme? "#FFFFFF" : "#404040"
      property color categoryColor: "#829297"
      property color darkColor: "#808080"
      property string font: "Roboto"
    }

    property QtObject icon: QtObject {
      property color color: darkTheme? "#FFFFFF" : "#404040"
    }
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

  property QtObject login: QtObject {
    property color background: "#FFFFFF"
    property real backgroundRadius: 30
    property color text: "#000000"

    property QtObject buttonCs: QtObject {
      property color normal: "#FFCC00"
      property color hover: "#FFDB49"
      property color press: "#EABB00"
    }
    property color buttonText: "#353535"

    property color backText: "#353535"

    property color textboxHint: "#939CB0"
    property color textboxText: "#000000"
    property color textboxBacground: "transparent"
    property color textboxBorder: "#ECEEF2"

    property QtObject yandexLogo: QtObject {
      property color y: "#FC3F1D"
      property color andex: "#000000"
    }
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
