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


Page {
    id: newTweetPage

    property string type: "New" //"New","Reply", "RT" or "DM"
    property string tweetId //for "Reply", "RT"
    property string screenName //for "DM"
    property string placedText: ""
    property double latitude: 0
    property double longitude: 0

    property string imageUrl: ""
    property string imagePath: ""

    property bool positionRequested

    backNavigation: !header.busy
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

        PageHeader {
            id: header
            //headerIcon: type == "DM" ? "Image/create_message.svg" : "image://theme/icon-m-toolbar-edit-white-selected"
            title: updateTitle()
            property bool busy: false

            function updateTitle() {
                if (imageUploader.progress > 0) return qsTr("Uploading...") + Math.round(imageUploader.progress * 100) + "%"

                switch (type) {
                case "New": return qsTr("New Tweet")
                case "Reply": return qsTr("Reply to %1").arg(placedText.substring(0, placedText.indexOf(" ")))
                case "RT": return qsTr("Retweet")
                case "DM": return qsTr("DM to %1").arg("@" + screenName)
                }
            }
            //visible: inPortrait || !inputContext.softwareInputPanelVisible
            //height: visible ? undefined : 0
        }

        TextArea {
            id: tweetTextArea
            anchors {
                top: header.bottom; left: parent.left; right: parent.right
                margins: constant.paddingMedium
                bottomMargin: autoCompleter.height + 2 * buttonColumn.anchors.margins
            }
            //readOnly: header.busy
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
                var currentWord = internal.getWordAt(fullText, tweetTextArea.cursorPosition)
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

            Button {
                id: tweetButton
                text: {
                    switch (type) {
                    case "New": return qsTr("Tweet")
                    case "Reply": return qsTr("Reply")
                    case "RT": return qsTr("Retweet")
                    case "DM": return qsTr("DM")
                    }
                }
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: (tweetTextArea.text.length != 0 ) // || addImageButton.checked)
                         && ((settings.enableTwitLonger /* && !addImageButton.checked */)  || !tweetTextArea.errorHighlight)
                onClicked: {
                    if (type == "New" || type == "Reply") {
                        if (imagePath != '') {
                            imageUploader.run();
                        }
                        else {
                            if (tweetTextArea.errorHighlight) internal.createUseTwitLongerDialog()
                            else {
                                Twitter.postStatus(tweetTextArea.text, tweetId ,latitude, longitude,
                                                   internal.postStatusOnSuccess, internal.commonOnFailure)
                                header.busy = true
                            }
                        }
                    }
                    else if (type == "RT") {
                        console.log("id" + tweetId)
                        Twitter.postRetweet(tweetId, internal.postStatusOnSuccess, internal.commonOnFailure)
                        header.busy = true
                    }
                    else if (type == "DM") {
                        Twitter.postDirectMsg(tweetTextArea.text, screenName,
                                              internal.postStatusOnSuccess, internal.commonOnFailure)
                        header.busy = true
                    }
                }
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

    ImageUploader {
        id: imageUploader
        service: settings.imageUploadService
        networkAccessManager: QMLUtils.networkAccessManager()
        onSuccess: {
            if (service == ImageUploader.Twitter) internal.postStatusOnSuccess(JSON.parse(replyData))
            else {
                var imageLink = ""
                if (service == ImageUploader.TwitPic) imageLink = JSON.parse(replyData).url
                else if (service == ImageUploader.MobyPicture) imageLink = JSON.parse(replyData).media.mediaurl
                else if (service == ImageUploader.Imgly) imageLink = JSON.parse(replyData).url
                Twitter.postStatus(tweetTextArea.text+" "+imageLink, tweetId, latitude, longitude,
                                   internal.postStatusOnSuccess, internal.commonOnFailure)
            }
        }
        onFailure: internal.commonOnFailure(status, statusText)

        function run() {
            imageUploader.setFile(imagePath)
            if (service == ImageUploader.Twitter) {
                imageUploader.setParameter("status", tweetTextArea.text)
                if (tweetId) imageUploader.setParameter("in_reply_to_status_id", tweetId)
                if (latitude != 0 && longitude != 0) {
                    imageUploader.setParameter("lat", latitude.toString())
                    imageUploader.setParameter("long", longitude.toString())
                }
                imageUploader.setAuthorizationHeader(Twitter.getTwitterImageUploadAuthHeader())
            }
            else {
                if (service == ImageUploader.TwitPic) imageUploader.setParameter("key", constant.twitpicAPIKey)
                else if (service == ImageUploader.MobyPicture) imageUploader.setParameter("key", constant.mobypictureAPIKey)
                imageUploader.setParameter("message", tweetTextArea.text)
                imageUploader.setAuthorizationHeader(Twitter.getOAuthEchoAuthHeader())
            }
            header.busy = true
            imageUploader.send()
        }
    }

    QtObject {
        id: internal

        property string twitLongerId: ""
        property bool exit
        property string tweetType: type

        /**
          Extract a word from str at the specificed pos.
          Example:
          var text = "Hello world"
          var word = getWordAt(text, n)

          n = 0; word = ""
          n = 1/2/3/4/5; word = "Hello"
          n = 6; word = ""
          n = 7/8/9/10/11; word = "world"
          n > text.length; unexpected behaviour
        */
        function getWordAt(str, pos) {
            var left = str.slice(0, pos).search(/\S+$/)
            if (left < 0) return ""

            var right = str.slice(pos).search(/\s/)
            if (right < 0) return str.slice(left)

            return str.slice(left, right + pos)
        }

        function postStatusOnSuccess(data) {
            switch (tweetType) {
            case "New": infoBanner.showText(qsTr("Tweet sent successfully")); break;
            case "Reply": infoBanner.showText(qsTr("Reply sent successfully")); break;
            case "DM":infoBanner.showText(qsTr("Direct message sent successfully")); break;
            case "RT": infoBanner.showText(qsTr("Retweet sent successfully")); break;
            }
            pageStack.pop()
        }

        function twitLongerOnSuccess(twitLongerId, shortenTweet) {
            internal.twitLongerId = twitLongerId
            Twitter.postStatus(shortenTweet, tweetId ,latitude, longitude,
                               postTwitLongerStatusOnSuccess, commonOnFailure)
        }

        function postTwitLongerStatusOnSuccess(data) {
            TwitLonger.postIDCallback(constant, twitLongerId, data.id_str)
            switch (type) {
            case "New": infoBanner.showText(qsTr("Tweet sent successfully")); break;
            case "Reply": infoBanner.showText(qsTr("Reply sent successfully")); break;
            }
            pageStack.pop()
        }

        function commonOnFailure(status, statusText) {
            infoBanner.showHttpError(status, statusText)
            header.busy = false
        }

        function createUseTwitLongerDialog() {
            var message = qsTr("Your tweet is more than 140 characters. \
Do you want to use TwitLonger to post your tweet?\n\
Note: The tweet content will be publicly visible even if your tweet is private.")
            dialog.createQueryDialog(qsTr("Use TwitLonger?"), "", message, function() {
                var replyScreenName = placedText ? placedText.substring(1, placedText.indexOf(" ")) : ""
                TwitLonger.postTweet(constant, settings.userScreenName, tweetTextArea.text, tweetId, replyScreenName,
                                     twitLongerOnSuccess, commonOnFailure)
                // header.busy = true
            })
        }
    }
}
