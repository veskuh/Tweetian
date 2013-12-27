/*
    Copyright (C) 2013 Siteshwar Vashisht
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

CoverBackground {
        id: appCover

        Label {
            id: unreadLabel
            anchors {
                right: parent.right; rightMargin: constant.paddingMedium
            }
            visible: mainPage.totalUnreadCount > 0
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.highlightColor
            text: mainPage.totalUnreadCount
        }

        ListView {
            id: coverTweetList
            width: parent.width; height: parent.height/2
            anchors.top: unreadLabel.bottom
            model: mainPage.timeline.model

            delegate: Item {
                id: item
                anchors { left: parent.left; right: parent.right; margins: constant.paddingSmall }
                height: usernameText.height + msgText.height + constant.paddingSmall

                Image {
                   id: profileImage
                   width: 20; height: 20
                   anchors { left: parent.left; bottom: msgText.top; }
                   source: profileImageUrl

                }

                Text {
                   id: usernameText
                   anchors { left: profileImage.right; right: parent.right; leftMargin: constant.paddingSmall }

                   text: "@" + screenName
                   font { pixelSize: Theme.fontSizeTiny; family: Theme.fontFamily; bold: true }
                   wrapMode: Text.Wrap
                   color: constant.colorLight
                }

                Label {
                    id: msgText
                    anchors { left: parent.left; right: parent.right; top: usernameText.bottom }
                    text: plainText
                    maximumLineCount: 2
                    truncationMode: TruncationMode.Fade
                    font { pixelSize: Theme.fontSizeTiny; family: Theme.fontFamily }
                    wrapMode: Text.Wrap
                    color: constant.colorLight
                }
            }
        }

        CoverActionList {
            id: coverActions
            CoverAction {
                id: coverAction
                iconSource: "image://theme/icon-cover-refresh"
                /* Refresh timeline, mentions and DMs */
                onTriggered: { mainPage.refreshAll(); }
            }

            CoverAction {
                iconSource: "image://theme/icon-cover-message"
                /*Push the new tweet page on top of stack and activate window */
                onTriggered: { pageStack.push(Qt.resolvedUrl("NewTweetPage.qml"), {type: "New"}); window.activate(); }
            }
        }
    }
