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
import QtLocation 5.0
import QtPositioning 5.0

import "Services/Twitter.js" as Twitter
import "Services/TwitLonger.js" as TwitLonger
import "Component"
import harbour.tweetian.Uploader 1.0


Dialog {
    id: newTweetPage

    property string type: internalTweet.tweetType //"New","Reply", "RT" or "DM"
    property string tweetId: internalTweet.tweetId //for "Reply", "RT"
    property string screenName: internalTweet.screenName //for "DM"
    property string placedText: internalTweet.tweetText
    property double latitude: internalTweet.latitude
    property double longitude: internalTweet.longitude

    allowedOrientations: Orientation.Portrait | Orientation.Landscape

    property string imageUrl: ""
    property string imagePath: ""

    property bool positionRequested
    canAccept: (tweetTextArea.text.length != 0 )
    onAccepted: internalTweet.postTweet(tweetId, type, screenName, tweetTextArea.text, imagePath, latitude, longitude)

    SilicaFlickable {
        anchors.fill: parent

        contentHeight: Math.max(childrenRect.height, newTweetPage.height + 1) // Needs to be scrollable for vkb

        PullDownMenu {
            MenuItem {
                visible: imagePath != ''
                text: qsTr("Remove Image")
                onClicked: imagePath = ''
            }

            MenuItem {
                visible: imagePath == ''
                text: qsTr("Attach Image")
                onClicked: {
                    var imagePicker = pageStack.push("Sailfish.Pickers.ImagePickerPage");
                    imagePicker.selectedContentChanged.connect(function() {
                        newTweetPage.imagePath = imagePicker.selectedContent;
                     });
                }
            }

            MenuItem {
                text: qsTr("Remove Location")
                onClicked: { latitude = 0; longitude = 0; }
                visible: latitude && longitude
            }

            MenuItem {
                text: qsTr("Attach Location")
                onClicked: { positionRequested = true; positionSource.update() }
                visible: !latitude && !longitude
            }
        }

        DialogHeader {
            id: header
            acceptText: updateTitle()
            function updateTitle() {
                switch (type) {
                    case "New": return qsTr("Tweet")
                    case "Reply": return qsTr("Reply")
                    case "RT": return qsTr("Retweet")
                    case "DM": return qsTr("DM")
                }
            }
        }

        TextArea {
            id: tweetTextArea
            anchors {
                top: header.bottom; left: parent.left; right: parent.right
                margins: constant.paddingMedium
                bottomMargin: autoCompleter.height + 2 * buttonColumn.anchors.margins
            }
            errorHighlight: charLeftText.text < 0 && type != "RT"
            font.pixelSize: constant.fontSizeMedium
            placeholderText: qsTr("Tap to write...")
            focus: type == "RT" ? false : true
            color: constant.colorLight
            cursorPosition: placedText.length
            text: placedText
            onTextChanged: updateAutoCompleter()

            Text {
                id: charLeftText
                property string shortenText: tweetTextArea.text.replace(/https?:\/\/\S+/g, __replaceLink)

                function __replaceLink(w) {
                    if (w.indexOf("https://") === 0)
                        return "https://t.co/xxxxxxxxxx" // Length: 23
                    else return "http://t.co/xxxxxxxxxx" // Length: 22
                }

                anchors { right: parent.right; bottom: parent.bottom; margins: constant.paddingMedium }
                font.pixelSize: constant.fontSizeSmall
                color: constant.colorMid
                text: 140 - shortenText.length - (imagePath != '' ? constant.charReservedPerMedia : 0)
            }

            Image {
                id: locationIcon
                anchors { left: parent.right; top: parent.top; topMargin: constant.paddingMedium }
                source: "Image/location_mark.svg"
                visible: latitude && longitude
            }

            function updateAutoCompleter() {
                if (newTweetPage.status !== PageStatus.Active || !tweetTextArea.activeFocus) return
                autoCompleter.model.clear()
                var fullText = tweetTextArea.text.substring(0, tweetTextArea.cursorPosition)
                        + tweetTextArea.text.substring(tweetTextArea.cursorPosition)
                var currentWord = internalTweet.getWordAt(fullText, tweetTextArea.cursorPosition)
                if (!/^(@|#)\w*$/.test(currentWord)) return
                var msg = {
                    word: currentWord,
                    model: autoCompleter.model,
                    screenNames: cache.screenNames,
                    hashtags: cache.hashtags
                }
                autoCompleterWorkerScript.sendMessage(msg)
            }
        }

        Loader {
            anchors.fill: tweetTextArea
            sourceComponent: type == "RT" ? rtCoverComponent : undefined

            Component {
                id: rtCoverComponent

                Rectangle {
                    color: Theme.highlightColor
                    opacity: 0.9
                    radius: constant.paddingMedium
                    Text {
                        color: Theme.primaryColor
                        anchors.centerIn: parent
                        font.pixelSize: tweetTextArea.font.pixelSize * 1.25
                        text: qsTr("Tap to Edit")
                    }

                    MouseArea {
                        anchors.fill: parent
                        //enabled: !header.busy
                        onClicked: {
                            type = "New"
                        }
                    }
                }
            }
        }

        Column {
            id: buttonColumn
            anchors { left: parent.left; right: parent.right; top: tweetTextArea.bottom; margins: constant.paddingMedium }
            height: childrenRect.height
            spacing: constant.paddingMedium

            ListView {
                id: autoCompleter
                anchors { left: parent.left; right: parent.right }
                height: constant.graphicSizeMedium
                model: ListModel {}
                visible: Qt.inputMethod.visible && model.count > 0
                delegate: Label {
                    height: ListView.view.height
                    text: model.completeWord
                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            var text = tweetTextArea.text
                            var word = model.completeWord
                            var leftIndex = tweetTextArea.text.slice(0, tweetTextArea.cursorPosition).search(/\S+$/)
                            if (leftIndex < 0) leftIndex = tweetTextArea.cursorPosition

                            var rest = text.slice(leftIndex+1)
                            var rightIndex = rest.search(/\s/)
                            if (rightIndex < 0) {
                                rightIndex = rest.length
                                word += " "
                            }

                            var left = text.slice(0, leftIndex)
                            var right = text.slice(rightIndex + leftIndex +1)

                            tweetTextArea.text = left + word + right
                            tweetTextArea.cursorPosition = leftIndex + word.length
                            autoCompleter.model.clear()

                            // This should clear preedit, but for
                            // some reason we still get garbage from vkb so clear it in timer
                            // in addition to resetting focus
                            Qt.inputMethod.reset()
                            focusTimer.editText = tweetTextArea.text
                            focusTimer.cursorPosition = tweetTextArea.cursorPosition
                            focusTimer.restart()
                        }
                    }
                }
                orientation: ListView.Horizontal
                spacing: constant.paddingSmall

                Timer {
                    id: focusTimer
                    interval: 100
                    property string editText
                    property int cursorPosition
                    onTriggered: {
                        tweetTextArea.text = editText
                        tweetTextArea.cursorPosition = cursorPosition
                        tweetTextArea.forceActiveFocus()
                    }
                }
            }

            Image {
                id: imagePreview
                width: 200; height: 200
                visible: source != ''
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                source: newTweetPage.imagePath
            }            
        }
    }

    Connections {
        target: harmattanUtils
        onMediaReceived: {
            if (mediaName) tweetTextArea.text = mediaName
            else infoBanner.showText(qsTr("No music is playing currently or music player is not running"))
        }
    }

    WorkerScript { id: autoCompleterWorkerScript; source: "WorkerScript/AutoCompleter.js" }

    PositionSource {
        id: positionSource
        active: false

        onPositionChanged: {
            if (positionRequested) {
                latitude = position.coordinate.latitude
                longitude = position.coordinate.longitude
                positionRequested = false
            }
        }
    }

}
