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
