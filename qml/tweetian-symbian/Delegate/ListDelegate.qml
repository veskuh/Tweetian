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
import com.nokia.symbian 1.1

AbstractDelegate{
    id: root
    height: Math.max(textColumn.height, profileImage.height) + 2 * constant.paddingMedium

    Column{
        id: textColumn
        anchors{ top: parent.top; left: profileImage.right; right: parent.right }
        anchors.leftMargin: constant.paddingSmall
        anchors.margins: constant.paddingMedium
        height: childrenRect.height

        Item{
            id: titleContainer
            width: parent.width
            height: listNameText.height

            Text{
                id: listNameText
                anchors.left: parent.left
                width: Math.min(parent.width, implicitWidth)
                font.bold: true
                font.pixelSize: settings.largeFontSize ? constant.fontSizeMedium : constant.fontSizeSmall
                color: highlighted ? constant.colorHighlighted : constant.colorLight
                text: listName
                elide: Text.ElideRight
            }

            Text{
                anchors{ left: listNameText.right; leftMargin: constant.paddingSmall; right: parent.right }
                font.pixelSize: settings.largeFontSize ? constant.fontSizeMedium : constant.fontSizeSmall
                color: highlighted ? constant.colorHighlighted : constant.colorMid
                text: qsTr("By %1").arg(ownerUserName)
                elide: Text.ElideRight
            }
        }

        Text{
            width: parent.width
            visible: text != ""
            wrapMode: Text.Wrap
            font.pixelSize: settings.largeFontSize ? constant.fontSizeMedium : constant.fontSizeSmall
            color: highlighted ? constant.colorHighlighted : constant.colorLight
            text: listDescription
        }

        Text{
            width: parent.width
            font.pixelSize: settings.largeFontSize ? constant.fontSizeMedium : constant.fontSizeSmall
            color: highlighted ? constant.colorHighlighted : constant.colorMid
            text: qsTr("%1 members | %2 subscribers").arg(memberCount).arg(subscriberCount)
        }
    }

    onClicked: {
        var parameters = {
            listName: listName,
            listId: listId,
            listDescription: listDescription,
            ownerScreenName: ownerScreenName,
            memberCount: memberCount,
            subscriberCount: subscriberCount,
            protectedList: protectedList,
            followingList: following,
            ownerProfileImageUrl: profileImageUrl
        }
        window.pageStack.push(Qt.resolvedUrl("../ListPage.qml"), parameters)
    }
}