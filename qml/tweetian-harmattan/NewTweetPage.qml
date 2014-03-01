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
    property string screenName //for "DM"
    property string placedText: internalTweet.tweetText
    property double latitude: internalTweet.latitude
    property double longitude: internalTweet.longitude

    property string imageUrl: ""
    property string imagePath: ""

    property bool positionRequested
    canAccept: (tweetTextArea.text.length != 0 )
    onAccepted: internalTweet.postTweet(tweetId, type, tweetTextArea.text, imagePath, longitude, latitude)
    onStatusChanged: if (status === PageStatus.Activating) preventTouch.enabled = false

    SilicaFlickable {
        anchors.fill: parent

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
            //textFormat: TextEdit.PlainText
            errorHighlight: charLeftText.text < 0 && type != "RT"
            font.pixelSize: constant.fontSizeMedium
            placeholderText: qsTr("Tap to write...")
            focus: true
            color: constant.colorLight
            cursorPosition: placedText.length
            text: placedText
            height: Math.max(implicitHeight, 120)
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
                    color: "white"
                    opacity: 0.9
                    radius: constant.paddingMedium

                    Text {
                        color: "black"
                        anchors.centerIn: parent
                        font.pixelSize: tweetTextArea.font.pixelSize * 1.25
                        text: qsTr("Tap to Edit")
                    }

                    MouseArea {
                        anchors.fill: parent
                        //enabled: !header.busy
                        onClicked: {
                            tweetTextArea.forceActiveFocus()
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
            /*
            Row {
                id: newTweetButtonRow
                anchors { left: parent.left; right: parent.right }
                height: childrenRect.height
                spacing: constant.paddingMedium
                visible: type == "New" || type == "Reply"

                Button {
                    id: locationButton
                    //iconSource: settings.invertedTheme ? "Image/add_my_location_inverse.svg" : "Image/add_my_location.svg"
                    width: (parent.width - constant.paddingMedium) / 2
                    text: qsTr("Add")
                    enabled: !header.busy
                    states: [
                        State {
                            name: "loading"
                            PropertyChanges {
                                target: locationButton
                                text: qsTr("Updating...")
                            //    checked: false
                            }
                        },
                        State {
                            name: "done"
                            PropertyChanges {
                                target: locationButton
                                text: qsTr("View/Remove")
                      //          iconSource: settings.invertedTheme ? "Image/location_mark_inverse.svg"
                        //                                           : "Image/location_mark.svg"
                          //      checked: true
                            }
                        }
                    ]
                    onClicked: {
                        if (state == "done") locationDialog.open()
                        else {
                            positionSource.start()
                            state = "loading"
                        }
                    }
                }

                Button {
                    id: addImageButton
                 //   iconSource: settings.invertedTheme ? "Image/photos_inverse.svg" : "Image/photos.svg"
                    width: (parent.width - constant.paddingMedium) / 2
                    text: checked ? qsTr("View/Remove") : qsTr("Add")
                    enabled: !header.busy
                   // checked: imagePath != ""
                    onClicked: {
                        if (checked) imageDialogComponent.createObject(newTweetPage)
                        else pageStack.push(Qt.resolvedUrl("SelectImagePage.qml"), {newTweetPage: newTweetPage})
                    }
                }
            }

           // SectionHeader { text: qsTr("Quick Tweet"); visible: newTweetButtonRow.visible }

            /*Button {
                anchors { left: parent.left; right: parent.right }
                visible: newTweetButtonRow.visible
                enabled: !header.busy
                text: qsTr("Music Player: Now Playing")
                onClicked: harmattanUtils.getNowPlayingMedia()
            }
        }*/



            // This menu can't be dynamically load as it will cause "Segmentation fault" when loading MapPage
            /*ContextMenu {
            id: locationDialog

            MenuLayout {
                MenuItem {
                    text: qsTr("View location")
                    onClicked: {
                        preventTouch.enabled = true
                        pageStack.push(Qt.resolvedUrl("MapPage.qml"), {"latitude": latitude, "longitude": longitude})
                    }
                }
                MenuItem {
                    text: qsTr("Remove location")
                    onClicked: {
                        latitude = 0
                        longitude = 0
                        locationButton.state = ""
                    }
                }
            }
        }*/

            /*Component {
            id: imageDialogComponent

            Menu {
                id: imageDialog
                property bool __isClosing: false
                MenuLayout {
                    MenuItem {
                        text: qsTr("View image")
                        onClicked: Qt.openUrlExternally(imageUrl)
                    }
                    MenuItem {
                        text: qsTr("Remove image")
                        onClicked: {
                            imageUrl = ""
                            imagePath = ""
                        }
                    }
                }
                Component.onCompleted: open()
                onStatusChanged: {
                    if (status === DialogStatus.Closing) __isClosing = true
                    else if (status === DialogStatus.Closed && __isClosing) imageDialog.destroy(250)
                }
            }*/
        }

        // this is to prevent any interaction in this page when loading the MapPage
        MouseArea {
            id: preventTouch
            anchors.fill: parent
            z: 1
            enabled: false
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
