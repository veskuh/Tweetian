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

    default property alias content: contentColumn.children
    property color sideRectColor: "transparent"
    property string imageSource: profileImageUrl
    property bool subItemIndicator: false

    property bool highlighted: pressed // read-only

    property int __originalHeight: contentHeight // private

    implicitWidth: ListView.view ? ListView.view.width : 0
    contentHeight: Math.max(contentColumn.height, profileImage.height) + 2 * constant.paddingMedium
    height: contentHeight // For contextMenu override in child

   /* Image {
        id: highlight
        anchors.fill: parent
        visible: mouseArea.pressed
        source: settings.invertedTheme ? "image://theme/meegotouch-panel-background-pressed"
                                       : "image://theme/meegotouch-panel-inverted-background-pressed"
    } */


    Loader {
        id: sideRectLoader
        anchors { right: parent.right; top: parent.top }
        sourceComponent: sideRectColor == "transparent" ? undefined : sideRect

        Component {
            id: sideRect

            Rectangle {
                height: root.height
                width: constant.paddingSmall
                color: sideRectColor
            }
        }
    }

    Item {
        id: profileImageMaskedItem
        anchors { top: parent.top; left: parent.left; topMargin: constant.paddingMedium; rightMargin: constant.paddingMedium; bottomMargin: constant.paddingMedium }
        width: constant.graphicSizeLarge; height: constant.graphicSizeLarge
    //    mask: Image { source: "../Image/pic_mask.png"}

        Image {
            id: profileImage
            anchors.fill: parent
            sourceSize { width: parent.width; height: parent.height }
            asynchronous: true

            NumberAnimation {
                id: imageLoadedEffect
                target: profileImage
                property: "opacity"
                from: 0; to: 1
                duration: 250
            }

            Binding {
                id: imageSourceBinding
                target: profileImage
                property: "source"
                value: thumbnailCacher.get(root.imageSource)
                       || (networkMonitor.online ? root.imageSource : constant.twitterBirdIcon)
                when: false
            }

            Connections {
                id: movementEndedSignal
                target: null
                onMovementEnded: {
                    imageSourceBinding.when = true
                    movementEndedSignal.target = null
                }
            }

            onStatusChanged: {
                if (status == Image.Ready) {
                    imageLoadedEffect.start()
                    if (source == root.imageSource) thumbnailCacher.store(root.imageSource, profileImage)
                }
                else if (status == Image.Error) source = constant.twitterBirdIcon
            }

            Component.onCompleted: {
                if (!root.ListView.view || !root.ListView.view.moving) imageSourceBinding.when = true
                else movementEndedSignal.target = root.ListView.view
            }
        }
    }

    Column {
        id: contentColumn
        anchors {
            top: parent.top; topMargin: constant.paddingMedium
            left: profileImageMaskedItem.right; leftMargin: constant.paddingMedium
            right: parent.right
            rightMargin: constant.paddingMedium
        }
        height: childrenRect.height
    }

    Timer {
        id: pause
        interval: 250
        onTriggered: contentHeight = __originalHeight
    }

    NumberAnimation {
        id: onAddAnimation
        target: root
        property: "scale"
        duration: 250
        from: 0.25; to: 1
        easing.type: Easing.OutBack
    }

    ListView.onAdd: {
        if (root.ListView.view.stayAtCurrentPosition) {
            if (root.ListView.view.atYBeginning) root.ListView.view.contentY += 1
            __originalHeight = contentHeight
            contentHeight = 0
            pause.start()
        }
        else onAddAnimation.start()
    }
}
