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

import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: root

    property bool marginLineVisible: true
    property bool subItemIndicator: false
    property url imageSource: ""

    // READ-ONLY
    property Item imageItem: imageLoader
    property int listItemRightMargin: subItemIndicator ? iconLoader.width + iconLoader.anchors.rightMargin : 0


    signal pressAndHold

    implicitWidth: parent ? parent.width : 0
    implicitHeight: imageSource ? imageLoader.height + 2 * imageLoader.anchors.margins : 0




    Loader {
        id: iconLoader
        anchors {
            right: parent.right; rightMargin: constant.paddingMedium
            verticalCenter: parent.verticalCenter
        }
        sourceComponent: root.subItemIndicator ? subItemIcon : undefined
    }

    Component {
        id: subItemIcon


        Image {
            source: "image://theme/icon-m-right"
            //.concat(settings.invertedTheme ? "" : "-inverse").concat(root.enabled ? "" : "-disabled")
            sourceSize { width: constant.graphicSizeSmall; height: constant.graphicSizeSmall }
        }

    }

    Loader {
        id: imageLoader
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            margins: constant.paddingLarge
        }
        sourceComponent: imageSource ? imageComponent : undefined
    }

    Component {
        id: imageComponent

        Item {
            id: pic
            width: constant.graphicSizeMedium; height: constant.graphicSizeMedium
        //    mask: Image { source: "../Image/pic_mask.png"}

            Image {
                id: profileImage
                anchors.fill: parent
                sourceSize { width: parent.width; height: parent.height }
                asynchronous: true
                source: root.imageSource
            }
        }
    }


    ListView.onAdd: NumberAnimation {
        target: root
        property: "scale"
        duration: 250
        easing.type: Easing.OutBack
        from: 0.25; to: 1
    }
}
