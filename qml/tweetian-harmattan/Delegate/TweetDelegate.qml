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

import QtQuick 2.1
import Sailfish.Silica 1.0

import "../Component"

AbstractDelegate {
    id: rootTweet
    height: contextMenu.visible ? rootTweet.contentHeight + contextMenu.height : rootTweet.contentHeight

    sideRectColor: {
        switch (settings.userScreenName) {
        case model.inReplyToScreenName: return constant.colorTextSelection
        case model.screenName: return constant.colorLight
        default: return "transparent"
        }
    }

    LongPressMenu {
        id: contextMenu
        tweet: model
    }

    Item {
        id: titleContainer
        anchors { left: parent.left; right: parent.right }
        height: userNameText.height

        Text {
            id: userNameText
            anchors.left: parent.left
            width: Math.min(parent.width, implicitWidth)
            font.pixelSize: constant.fontSizeMedium
            font.bold: true
            font.family: Theme.fontFamily

            color: highlighted ? constant.colorHighlighted : constant.colorLight
            elide: Text.ElideRight
            text: model.name
        }

        Text {
            anchors { left: userNameText.right; right: favouriteIcon.left; margins: constant.paddingMedium; verticalCenter: userNameText.verticalCenter }
            font.pixelSize: constant.fontSizeSmall

            font.family: Theme.fontFamily
            color: highlighted ? constant.colorHighlighted : constant.colorMid
            elide: Text.ElideRight
            text: "@" + model.screenName
        }

        Image {
            id: favouriteIcon
            anchors.right: parent.right
            height: constant.graphicSizeSmall
            width: height
            source: "image://theme/icon-s-favorite"
            visible: model.isFavourited
        }
    }

    Text {
        anchors { left: parent.left; right: parent.right }
        textFormat: Text.RichText
        font.pixelSize: constant.fontSizeMedium
        font.family: Theme.fontFamily
        wrapMode: Text.Wrap
        color: highlighted ? constant.colorHighlighted : constant.colorLight
        text: model.richText
        height: implicitHeight + Theme.paddingSmall
    }

    Row {
        anchors { left: parent.left; right: parent.right }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: constant.fontSizeSmall
            font.family: Theme.fontFamily
            color: highlighted ? constant.colorHighlighted : constant.colorMid
            elide: Text.ElideRight
            text: model.timeDiff + " | "
        }

        Image {
            anchors.verticalCenter: parent.verticalCenter
            height: constant.graphicSizeXSmall
            width: height
            source: "image://theme/icon-s-retweet"
            visible: model.isRetweet
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: constant.fontSizeSmall
            font.family: Theme.fontFamily
            wrapMode: Text.Wrap
            color: highlighted ? constant.colorHighlighted : constant.colorMid
            text: " @" + model.retweetScreenName + " | "
            visible: model.isRetweet
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: constant.fontSizeSmall
            font.family: Theme.fontFamily
            color: highlighted ? constant.colorHighlighted : constant.colorMid
            elide: Text.ElideRight
            text: model.source
        }
    }

    RemorseItem {
        id: remorse
    }

    onClicked: pageStack.push(Qt.resolvedUrl("../TweetPage.qml"), { tweet: model })

    onPressAndHold: {
        contextMenu.show(rootTweet);
    }
}
