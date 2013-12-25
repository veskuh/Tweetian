import QtQuick 2.1
import Sailfish.Silica 1.0

import "Utils/Database.js" as Database

CoverBackground {
        id: appCover
        property variant unreadCount: mainPage.getTotalUnreadCount()

        Label {
            id: unreadLabel
            anchors {
                right: parent.right; rightMargin: constant.paddingMedium
            }
            visible: appCover.unreadCount > 0
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.highlightColor

            text: appCover.unreadCount
         }

        function refresh() {
            var timeline = Database.getTimeline();
            if (timeline.length > 2) {
                timeline = timeline.slice(0, 2);
            }

            var msg = {
                type: "database",
                data: timeline,
                model: coverTweetList.model
            }

            tweetParser.sendMessage(msg);
        }

        /* TODO: It won't show new tweets on cover, we need to store tweets in database after fetching */
        onUnreadCountChanged: refresh()

        Component.onCompleted: {
            refresh();
        }

        ListView {
            id: coverTweetList
            width: parent.width; height: parent.height
            anchors.top: unreadLabel.bottom
            model: ListModel{ }
            delegate: Item {
                id: item
                anchors { left: parent.left; right: parent.right; margins: constant.paddingSmall }
                height: appCover.height/3

                Text {
                   id: usernameText
                   anchors { left: parent.left; right: parent.right }

                   text: "@" + screenName
                   font { pixelSize: Theme.fontSizeTiny; family: Theme.fontFamily; bold: true }
                   wrapMode: Text.Wrap
                   color: constant.colorLight
               }

                 Text {
                    id: msgText
                    anchors { left: parent.left; right: parent.right; top: usernameText.bottom }
                    text: getDisplayText(plainText, item)
                    font { pixelSize: Theme.fontSizeTiny; family: Theme.fontFamily }
                    wrapMode: Text.Wrap
                    color: constant.colorLight

                    function getDisplayText(text, item) {
                        var maxLength = Math.floor((item.height*3)/4);
                        if (text.length > maxLength)
                            return text.substring(0, maxLength) + "...";
                        return text;
                    }
                 }
            }
        }

        WorkerScript {
            id: tweetParser
            source: "WorkerScript/TweetsParser.js"
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
