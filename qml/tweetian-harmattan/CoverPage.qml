import QtQuick 2.1
import Sailfish.Silica 1.0

import "Utils/Database.js" as Database

CoverBackground {
        id: appCover

        WorkerScript {
            id: tweetParser
            source: "WorkerScript/TweetsParser.js"
        }

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

        function refresh() {
            coverTweetList.model.clear();
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

        /* TODO: Update cover with new tweets. Strangely uncommenting following
           line doesn't show new tweets, this will just clear the tweet list
        */
        // onUnreadCountChanged: refresh();

        Component.onCompleted: {
            refresh();
        }

        ListView {
            id: coverTweetList
            width: parent.width; height: parent.height
            anchors.top: unreadLabel.bottom
            model: ListModel { }

            delegate: Item {
                id: item
                anchors { left: parent.left; right: parent.right; margins: constant.paddingSmall }
                height: appCover.height/3

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
