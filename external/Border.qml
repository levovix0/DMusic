/****************************************************************************
**
** Copyright (C) 2021 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of Qt Quick Studio Components.
**
** $QT_BEGIN_LICENSE:GPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3 or (at your option) any later version
** approved by the KDE Free Qt Foundation. The licenses are as published by
** the Free Software Foundation and appearing in the file LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQuick 2.10
import QtQuick.Shapes 1.0

/*!
    \qmltype BorderItem
    \inqmlmodule QtQuick.Studio.Components
    \since QtQuick.Studio.Components 1.0
    \inherits Shape

    \brief A border drawn in four segments: left, top, right, and bottom.

    The Border type is used to create borders out of four segments: left,
    top, right, and bottom. The \l drawLeft, \l drawTop, \l drawRight, and
    \l drawBottom properties can be used to determine whether each of the
    segments is visible.

    The \l borderMode property determines whether the border is drawn along
    the inside or outside edge of the item, or on top of the edge.

    The \l radius property specifies whether the border corners are rounded.
    The radius can also be specified separately for each corner. Because this
    introduces curved edges to the corners, it may be appropriate to set the
    \c antialiasing property that is inherited from \l Item to improve the
    appearance of the border.

    The \l joinStyle property specifies how to connect two border line segments.

    The \l strokeColor, \l strokeWidth, and \l strokeStyle properties specify
    the appearance of the border line. The \l dashPattern and \l dashOffset
    properties specify the appearance of dashed lines.

    The \l capStyle property specifies whether line ends are square or
    rounded.

    \section2 Example Usage

    You can use the Border component in \QDS to create different kinds of
    borders.

    \image studio-border.png

    The QML code looks as follows:

    \code
    BorderItem {
        id: openLeft
        width: 99
        height: 99
        antialiasing: true
        drawLeft: false
        strokeColor: "gray"
    }

    BorderItem {
        id: openTop
        width: 99
        height: 99
        antialiasing: true
        strokeColor: "#808080"
        drawTop: false
    }

    BorderItem {
        id: asymmetricalCorners
        width: 99
        height: 99
        antialiasing: true
        bottomLeftRadius: 0
        topRightRadius: 0
        strokeColor: "#808080"
    }

    BorderItem {
        id: dashedBorder
        width: 99
        height: 99
        antialiasing: true
        strokeStyle: 4
        strokeColor: "#808080"
    }
    \endcode
*/

Shape {
    id: root
    width: 200
    height: 150

/*!
    The radius used to draw rounded corners.

    The default value is 10.

    If radius is non-zero, the corners will be rounded, otherwise they will
    be sharp. The radius can also be specified separately for each corner by
    using the \l bottomLeftRadius, \l bottomRightRadius, \l topLeftRadius, and
    \l topRightRadius properties.
*/
    property int radius: 10

/*!
    The radius of the top left border corner.

    \sa radius
*/
    property int topLeftRadius: radius

/*!
    The radius of the bottom left border corner.

    \sa radius
*/
    property int bottomLeftRadius: radius

/*!
    The radius of the top right border corner.

    \sa radius
*/
    property int topRightRadius: radius

/*!
    The radius of the bottom right border corner.

    \sa radius
*/
    property int bottomRightRadius: radius

/*!
    Whether the border corner is beveled.
*/
    property bool bevel: false

/*!
    The bevel of the top left border corner.

    \sa bevel
*/
    property bool topLeftBevel: bevel

/*!
    The bevel of the top right border corner.

    \sa bevel
*/
    property bool topRightBevel: bevel

/*!
    The bevel of the bottom right border corner.

    \sa bevel
*/
    property bool bottomRightBevel: bevel

/*!
    The bevel of the bottom left border corner.

    \sa bevel
*/
    property bool bottomLeftBevel: bevel

    //property alias gradient: path.fillGradient

/*!
    The style of the border line.

    \value ShapePath.SolidLine
           A solid line. This is the default value.
    \value ShapePath.DashLine
           Dashes separated by a few pixels.
           The \l dashPattern property specifies the dash pattern.

    \sa Qt::PenStyle
*/
    property alias strokeStyle: path.strokeStyle

/*!
    The width of the border line.

    When set to a negative value, no line is drawn.

    The default value is 4.
*/
    property alias strokeWidth: path.strokeWidth

/*!
    The color of the border line.

    When set to \c transparent, no line is drawn.

    The default value is \c red.

    \sa QColor
*/
    property alias strokeColor: path.strokeColor

/*!
    The dash pattern of the border line specified as the dashes and the gaps
    between them.

    The dash pattern is specified in units of the pen's width. That is, a dash
    with the length 5 and width 10 is 50 pixels long.

    Each dash is also subject to cap styles, and therefore a dash of 1 with
    square cap set will extend 0.5 pixels out in each direction resulting in
    a total width of 2.

    The default \l capStyle is \c {ShapePath.SquareCap}, meaning that a square
    line end covers the end point and extends beyond it by half the line width.

    The default value is (4, 2), meaning a dash of 4 * \l strokeWidth pixels
    followed by a space of 2 * \l strokeWidth pixels.

    \sa QPen::setDashPattern()
*/
    property alias dashPattern: path.dashPattern

/*!
    The join style used to connect two border line segments.

    \value ShapePath.MiterJoin
           The outer edges of the lines are extended to meet at an angle, and
           this area is filled.
    \value ShapePath.BevelJoin
           The triangular notch between the two lines is filled.
           This is the default value.
    \value ShapePath.RoundJoin
           A circular arc between the two lines is filled.

    \sa Qt::PenJoinStyle
*/
    property alias joinStyle: path.joinStyle

/*!
    The starting point of the dash pattern for the border line.

    The offset is measured in terms of the units used to specify the dash
    pattern. For example, a pattern where each stroke is four units long,
    followed by a gap of two units, will begin with the stroke when drawn
    as a line. However, if the dash offset is set to 4.0, any line drawn
    will begin with the gap. Values of the offset up to 4.0 will cause part
    of the stroke to be drawn first, and values of the offset between 4.0 and
    6.0 will cause the line to begin with part of the gap.

    The default value is 0.

    \sa QPen::setDashOffset()
*/
    property alias dashOffset: path.dashOffset

/*!
    The cap style of the line.

    \value ShapePath.FlatCap
           A square line end that does not cover the end point of the line.
    \value ShapePath.SquareCap
           A square line end that covers the end point and extends beyond it
           by half the line width. This is the default value.
    \value ShapePath.RoundCap
           A rounded line end.

    \sa Qt::PenCapStyle
*/
    property alias capStyle: path.capStyle

    //property alias fillColor: path.fillColor

/*!
    Whether the top border is visible.

    The border segment is drawn if this property is set to \c true.
*/
    property bool drawTop: true

/*!
    Whether the bottom border is visible.

    The border segment is drawn if this property is set to \c true.
*/
    property bool drawBottom: true

/*!
    Whether the right border is visible.

    The border segment is drawn if this property is set to \c true.
*/
    property bool drawRight: true

/*!
    Whether the left border is visible.

    The border segment is drawn if this property is set to \c true.
*/
    property bool drawLeft: true

    layer.enabled: antialiasing
    layer.smooth: antialiasing
    layer.textureSize: Qt.size(width * 2, height * 2)

/*!
    Where the border is drawn.

    \value Border.Inside
           The border is drawn along the inside edge of the item and does not
           affect the item width.
           This is the default value.
    \value Border.Middle
           The border is drawn over the edge of the item and does not
           affect the item width.
    \value Border.Outside
           The border is drawn along the outside edge of the item and increases
           the item width by the value of \l strokeWidth.

    \sa strokeWidth
*/
    property int borderMode: 0

    property real borderOffset: {

        if (root.borderMode === 0)
            return path.strokeWidth * 10.0 / 20.0
        if (root.borderMode === 1)
            return 0

        return -path.strokeWidth * 10.0 / 20.0
    }


    Item {
        anchors.fill: parent
        anchors.margins: {
            if (root.borderMode === 0)
                return 0
            if (root.borderMode === 1)
                return -root.strokeWidth / 2.0


            return -root.strokeWidth
        }
    }

    ShapePath {
        id: path
        joinStyle: ShapePath.MiterJoin

        strokeWidth: 4
        strokeColor: "red"
        fillColor: "transparent"

        startX: root.topLeftRadius + root.borderOffset
        startY: root.borderOffset


    }


    Item {
        id: shapes

        PathLine {
            x: root.width - root.topRightRadius - root.borderOffset
            y: root.borderOffset
            property bool add: root.drawTop
        }

        PathArc {
            x: root.width - root.borderOffset
            y: root.topRightRadius + root.borderOffset
            radiusX: topRightBevel ? 50000 : root.topRightRadius
            radiusY: topRightBevel ? 50000 : root.topRightRadius
            property bool add: root.drawTop && root.drawRight
        }

        PathMove {
            x: root.width - root.borderOffset
            y: root.topRightRadius + root.borderOffset
            property bool add: !root.drawTop
        }


        PathLine {
            x: root.width - root.borderOffset
            y: root.height - root.bottomRightRadius - root.borderOffset
            property bool add: root.drawRight
        }

        PathArc {
            x: root.width - root.bottomRightRadius - root.borderOffset
            y: root.height - root.borderOffset
            radiusX: bottomRightBevel ? 50000 : root.bottomRightRadius
            radiusY: bottomRightBevel ? 50000 : root.bottomRightRadius
            property bool add: root.drawRight && root.drawBottom
        }

        PathMove {
            x: root.width - root.bottomRightRadius - root.borderOffset
            y: root.height - root.borderOffset
            property bool add: !root.drawRight
        }

        PathLine {
            x: root.bottomLeftRadius + root.borderOffset
            y: root.height - root.borderOffset
            property bool add: root.drawBottom
        }

        PathArc {
            x: root.borderOffset
            y: root.height - root.bottomLeftRadius - root.borderOffset
            radiusX: bottomLeftBevel ? 50000 : root.bottomLeftRadius
            radiusY: bottomLeftBevel ? 50000 : root.bottomLeftRadius
            property bool add: root.drawBottom && root.drawLeft
        }

        PathMove {
            x: root.borderOffset
            y: root.height - root.bottomLeftRadius - root.borderOffset
            property bool add: !root.drawBottom
        }

        PathLine {
            x: root.borderOffset
            y: root.topLeftRadius + root.borderOffset
            property bool add: root.drawLeft
        }

        PathArc {
            x: root.topLeftRadius + root.borderOffset
            y: root.borderOffset
            radiusX: topLeftBevel ? 50000 : root.topLeftRadius
            radiusY: topLeftBevel ? 50000 : root.topLeftRadius
            property bool add: root.drawTop && root.drawLeft
        }
    }

    function invalidatePaths() {
        if (!root.__completed)
            return

        for (var i = 0; i < shapes.resources.length; i++) {
            var s = shapes.resources[i];
            if (s.add)
                path.pathElements.push(s)
        }

    }

    property bool __completed: false

    Component.onCompleted: {
        root.__completed = true
        invalidatePaths()
    }
}
