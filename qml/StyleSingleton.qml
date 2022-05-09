pragma Singleton
import QtQuick 2.15
import Config 1.0

QtObject {
  id: root
  property bool darkTheme: Config.darkTheme
  property bool darkHeader: Config.darkTheme || Config.darkHeader

  property color accent: Config.colorAccentDark
  property color lightAccent: Config.colorAccentLight

  property color white: "#FFFFFF"
  property color c40: "#404040"
  property color cBorder: "#D9D9D9"

  property QtObject window: QtObject {
    property color background: darkTheme? "#202020" : white
    property color accent: darkTheme? root.accent : root.lightAccent

    property QtObject border: QtObject {
      property color color: darkTheme? "transparent" : cBorder
      property real width: darkTheme? 0 : 2
    }

    property QtObject sellection: QtObject {
      property color background: darkTheme? "#303030" : "#F0F0F0"
      property color pressedBackground: darkTheme? "#181818" : "#E2E2E2"
      property real radius: 5

      // property QtObject border: QtObject {
      //   property color color: darkTheme? "transparent" : cBorder
      //   property real width: darkTheme? 0 : 2
      // }
    }

    property QtObject text: QtObject {
      property color color: darkTheme? white : c40
      property color darkColor: "#808080"
      property string font: "Roboto"
    }

    property QtObject icon: QtObject {
      property QtObject normal: QtObject {
        property color color: darkTheme? "#C1C1C1" : c40
        property color hoverColor: darkTheme? white : "#808080"
      }
      property QtObject accent: QtObject {
        property color color: window.accent
        property color hoverColor: Qt.darker(color, 1.5)
      }
    }

    property QtObject checkBox: QtObject {
      property color color: accent
      property QtObject border: QtObject {
        property color color: darkTheme? accent : cBorder
        property real width: 2
      }
    }
  }

  property QtObject header: QtObject {
    property color background: darkHeader? "#202020" : white
    property color accent: darkHeader? root.accent : root.lightAccent

    property QtObject border: QtObject {
      property color color: darkHeader? "transparent" : cBorder
      property real width: darkHeader? 0 : 2
    }

    property QtObject text: QtObject {
      property color color: darkHeader? white : c40
      property color darkColor: "#808080"
      property string font: "Roboto"
    }

    property QtObject button: QtObject {
      property QtObject color: QtObject {
        property color normal: darkHeader? white : c40
        property color hover: normal
        property color pressed: normal
      }
      property QtObject background: QtObject {
        property color normal: "transparent"
        property color hover: darkHeader? "#303030" : "#F0F0F0"
        property color pressed: darkHeader? "#262626" : "#D0D0D0"
      }
    }

    property QtObject searchBox: QtObject {
      property real height: 24
      property real radius: height / 2
      property QtObject background: QtObject {
        property color normal: header.background
        property color input: darkHeader? "#262626" : header.background
      }

      property QtObject text: QtObject {
        property color color: darkHeader? white : c40
        property color darkColor: color
        property string font: "Roboto"
        property int hAlign: Text.AlignHCenter
      }

      property QtObject border: QtObject {
        property QtObject color: QtObject {
          property color normal: "#00D9D9D9"
          property color input: darkHeader? "transparent" : cBorder
        }
        property real width: darkHeader? 0 : 2
      }

      property real textScale: 0.55
      property real hintScale: 0.55
    }

    property QtObject closeButton: QtObject {
      property QtObject color: QtObject {
        property color normal: darkHeader? white : c40
        property color hover: white
        property color pressed: white
      }
      property QtObject background: QtObject {
        property color normal: "transparent"
        property color hover: "#E03649"
        property color pressed: "#C11B2D"
      }
    }
  }

  property QtObject panel: QtObject {
    property color background: darkHeader? "#262626" : white
    property color accent: darkHeader? root.accent : root.lightAccent
    property bool shadow: true
    property real radius: 5

    property QtObject border: QtObject {
      property color color: "transparent"
      property real width: 0
    }

    property QtObject sellection: QtObject {
      property color background: darkHeader? "#202020" : "#F0F0F0"
      property color pressedBackground: darkHeader? "#181818" : "#E2E2E2"
      property real radius: 5

      property QtObject border: QtObject {
        property color color: darkHeader? "transparent" : cBorder
        property real width: darkHeader? 0 : 2
      }
    }

    property QtObject text: QtObject {
      property color color: darkHeader? white : c40
      property color unsellectedColor: darkHeader? "#C5C5C5" : c40
      property color sellectedColor: darkHeader? white : "#202020"
      property color darkColor: "#808080"
      property color artistColor: darkHeader? "#CCCCCC" : "#515151"
      property color commentColor: "#999999"
      property string font: "Roboto"
    }

    property QtObject item: QtObject {
      property color background: darkHeader? "#404040" : "#E2E2E2"
      property color foreground: darkHeader? "#AAAAAA" : "#808080"
      property bool dropShadow: darkHeader? false : true
    }

    property QtObject textBox: QtObject {
      property real height: 20
      property real radius: 3
      property QtObject background: QtObject {
        property color normal: darkHeader? "#202020" : "transparent"
        property color input: normal
      }

      property QtObject text: QtObject {
        property color color: darkHeader? white : c40
        property color darkColor: "#808080"
        property string font: "Roboto"
        property int hAlign: Text.AlignLeft
      }

      property QtObject border: QtObject {
        property QtObject color: QtObject {
          property color normal: darkHeader? "transparent" : cBorder
          property color input: darkHeader? "transparent" : cBorder
        }
        property real width: darkHeader? 0 : 2
      }

      property real textScale: 0.8
      property real hintScale: 0.7
    }

    property QtObject icon: QtObject {
      property QtObject normal: QtObject {
        property color color: darkHeader? "#C1C1C1" : c40
        property color hoverColor: darkHeader? white : "#808080"
        property color pressedColor: darkHeader? Qt.darker(color, 1.25) : Qt.lighter(color, 1.25)
      }
      property QtObject accent: QtObject {
        property color color: panel.accent
        property color hoverColor: darkHeader? Qt.lighter(color, 1.25) : Qt.darker(color, 1.25)
        property color pressedColor: darkHeader? Qt.darker(color, 1.25) : Qt.lighter(color, 1.25)
      }
    }

    property QtObject checkBox: QtObject {
      property color color: accent
      property QtObject border: QtObject {
        property color color: darkTheme? accent : cBorder
        property real width: 2
      }
    }
  }

  property QtObject block: QtObject {
    property color background: darkTheme? "#262626" : white
    property color accent: darkTheme? root.accent : root.lightAccent
    property bool shadow: true
    property real radius: 10

    property QtObject border: QtObject {
      property color color: darkTheme? "transparent" : cBorder
      property real width: darkTheme? 0 : 2
    }

    property QtObject text: QtObject {
      property color color: darkTheme? white : c40
      property color categoryColor: "#829297"
      property color darkColor: "#808080"
      property string font: "Roboto"
    }

    property QtObject icon: QtObject {
      property QtObject normal: QtObject {
        property color color: darkTheme? "#C1C1C1" : c40
        property color hoverColor: darkTheme? white : "#808080"
      }
      property QtObject accent: QtObject {
        property color color: block.accent
        property color hoverColor: Qt.darker(color, 1.5)
      }
    }

    property QtObject checkBox: QtObject {
      property color color: accent
      property QtObject border: QtObject {
        property color color: darkTheme? accent : cBorder
        property real width: 2
      }
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
        property color hover: c40
        property color press: "#303030"
      }
    }
  }

  property QtObject login: QtObject {
    property color background: white
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
