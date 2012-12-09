/*
    Copyright (C) 2012 Dickson Leong
    This file is part of Tweetian.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 1.1
import "../Utils/Calculations.js" as Calculate

Item{
    id: root
    height: 0
    width: ListView.view.width

    Item{
        id: container
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: constant.paddingLarge
        height: pullIcon.height
        width: pullIcon.width + textColumn.width + textColumn.anchors.leftMargin
        visible: root.ListView.view.__wasAtYBeginning && root.ListView.view.__initialContentY - root.ListView.view.contentY > 10

        Image{
            id: pullIcon
            anchors.left: parent.left
            source: settings.invertedTheme ? "image://theme/toolbar-next_inverse" : "image://theme/toolbar-next"
            sourceSize.width: constant.graphicSizeSmall
            sourceSize.height: constant.graphicSizeSmall
            rotation: visible && root.ListView.view.__initialContentY - root.ListView.view.contentY > 100 ? 270 : 90

            Behavior on rotation { NumberAnimation{ duration: 250 } }
        }

        Column{
            id: textColumn
            width: Math.max(pullText.width, lastUpdateText.width)
            height: childrenRect.height
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: pullIcon.right
            anchors.leftMargin: constant.paddingLarge

            Text{
                id: pullText
                font.pixelSize: constant.fontSizeMedium
                color: constant.colorLight
                text: visible && root.ListView.view.__initialContentY - root.ListView.view.contentY > 100 ?
                          qsTr("Release to refresh") : qsTr("Pull down to refresh")
            }

            Text{
                id: lastUpdateText
                font.pixelSize: constant.fontSizeSmall
                color: constant.colorMid
                visible: container.visible && root.ListView.view.lastUpdate
                onVisibleChanged: {
                    if(visible) text = qsTr("Last update: %1").arg(Calculate.timeDiff(root.ListView.view.lastUpdate))
                }
            }
        }
    }
}