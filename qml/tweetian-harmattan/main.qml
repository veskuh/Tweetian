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
import QtFeedback 5.0
import harbour.tweetian.Uploader 1.0
import "Services/Twitter.js" as Twitter

ApplicationWindow {
    id: window
    initialPage: MainPage { id: mainPage }
    cover: (settings.oauthToken != "" && settings.oauthTokenSecret != "") ? Qt.resolvedUrl("CoverPage.qml") : undefined;
    property bool pendingTweet: false
    //showStatusBar: inPortrait
    //showToolBar: true

    Settings { id: settings }

    Cache { id: cache }
    Constant { id: constant }

    ThemeEffect { id: basicHapticEffect; effect: ThemeEffect.Appear }

    Rectangle {
        id: infoBanner

        width: parent.width
        height: infoText.height + 2 * Theme.paddingMedium

        color: Theme.highlightBackgroundColor
        opacity: 0.0
        // On top of everything
        z: 1

        function showText(text) {
            infoText.text = text
            opacity = 0.9
            console.log("INFO: " + text)
            closeTimer.restart()
        }

        function showHttpError(errorCode, errorMessage) {
            if (errorCode === 0) showText(qsTr("Server or connection error"))
            else if (errorCode === 429) showText(qsTr("Rate limit reached, please try again later"))
            else showText(qsTr("Error: %1").arg(errorMessage + " (" + errorCode + ")"))
        }

        Label {
            id: infoText
            anchors.top: parent.top
            anchors.topMargin: Theme.paddingMedium
            x: Theme.paddingMedium
            width: parent.width - 2 * Theme.paddingMedium
            color: Theme.highlightColor
            maximumLineCount: 2
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        Behavior on opacity { FadeAnimation {} }

        Timer {
            id: closeTimer
            interval: 2000
            onTriggered: infoBanner.opacity = 0.0
        }
    }

    Item {
        id: loadingRect
        anchors.fill: parent
        visible: false
        z: 2

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.5
        }

        BusyIndicator {
            visible: loadingRect.visible
            running: visible
            anchors.centerIn: parent
        }
    }

    QtObject {
        id: dialog

        property Component __openLinkDialog: null
        property Component __dynamicQueryDialog: null
        property Component __messageDialog: null
        property Component __tweetLongPressMenu: null

        function createOpenLinkDialog(link, pocketCallback, instapaperCallback) {
            /*if (!__openLinkDialog) __openLinkDialog = Qt.createComponent("Dialog/OpenLinkDialog.qml")
            var showAddPageServices = pocketCallback && instapaperCallback ? true : false
            var prop = { link: link, showAddPageServices: showAddPageServices }
            var dialog = __openLinkDialog.createObject(pageStack.currentPage, prop)
            if (showAddPageServices) {
                dialog.addToPocketClicked.connect(pocketCallback)
                dialog.addToInstapaperClicked.connect(instapaperCallback)
            }*/
            Qt.openUrlExternally(link)
        }

        function createQueryDialog(titleText, titleIcon, message, acceptCallback) {
            if (!__dynamicQueryDialog) __dynamicQueryDialog = Qt.createComponent("Dialog/DynamicQueryDialog.qml")
            var prop = { titleText: titleText, icon: titleIcon, message: message }
            var dialog = __dynamicQueryDialog.createObject(pageStack.currentPage, prop)
            dialog.accepted.connect(acceptCallback)
        }

        function createMessageDialog(titleText, message) {
            if (!__messageDialog) __messageDialog = Qt.createComponent("Dialog/MessageDialog.qml")
            __messageDialog.createObject(pageStack.currentPage, { titleText: titleText, message: message })
        }

        function createTweetLongPressMenu(model) {
            if (!__tweetLongPressMenu) __tweetLongPressMenu = Qt.createComponent("Dialog/LongPressMenu.qml")
            __tweetLongPressMenu.createObject(pageStack.currentPage, { model: model })
        }
    }

    ImageUploader {
        id: imageUploader
        service: settings.imageUploadService
        networkAccessManager: QMLUtils.networkAccessManager()
        onSuccess: {
            if (service == ImageUploader.Twitter) tweet_internal.postStatusOnSuccess(JSON.parse(replyData))
            else {
                var imageLink = ""
                if (service == ImageUploader.TwitPic) imageLink = JSON.parse(replyData).url
                else if (service == ImageUploader.MobyPicture) imageLink = JSON.parse(replyData).media.mediaurl
                else if (service == ImageUploader.Imgly) imageLink = JSON.parse(replyData).url
                Twitter.postStatus(tweet_internal.tweetText+" "+imageLink, tweet_internal.tweetId, tweet_internal.latitude, tweet_internal.longitude,
                                   tweet_internal.postStatusOnSuccess, tweet_internal.commonOnFailure)
            }
        }
        onFailure: tweet_internal.commonOnFailure(status, statusText)

        function run() {
            imageUploader.setFile(tweet_internal.tweetImage)
            if (service == ImageUploader.Twitter) {
                imageUploader.setParameter("status", tweet_internal.text)
                if (tweet_internal.tweetId) imageUploader.setParameter("in_reply_to_status_id", tweet_internal.tweetId)
                if (tweet_internal.latitude != 0.0 && tweet_internal.longitude != 0.0) {
                    imageUploader.setParameter("lat", tweet_internal.latitude.toString())
                    imageUploader.setParameter("long", tweet_internal.longitude.toString())
                }
                imageUploader.setAuthorizationHeader(Twitter.getTwitterImageUploadAuthHeader())
            }
            else {
                if (service == ImageUploader.TwitPic) imageUploader.setParameter("key", constant.twitpicAPIKey)
                else if (service == ImageUploader.MobyPicture) imageUploader.setParameter("key", constant.mobypictureAPIKey)
                imageUploader.setParameter("message", tweetTextArea.text)
                imageUploader.setAuthorizationHeader(Twitter.getOAuthEchoAuthHeader())
            }

            imageUploader.send()
        }
    }

    QtObject {
        id: tweet_internal
//        property string twitLongerId: ""
        property bool exit: false
        property string tweetType: "New"
        property string tweetText: ""
        property string tweetImage: ""
        property string tweetId: ""
        property double latitude: 0.0
        property double longitude: 0.0
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

            tweetId = ""
            tweetType = ""
            tweetImage = ""
            tweetText = ""
            longitude = 0.0
            latitude = 0.0
        }
        /*
        function twitLongerOnSuccess(twitLongerId, shortenTweet) {
            internal.twitLongerId = twitLongerId
            Twitter.postStatus(shortenTweet, tweetId ,latitude, longitude,
                               postTwitLongerStatusOnSuccess, commonOnFailure)
        }

        function postTwitLongerStatusOnSuccess(data) {
            TwitLonger.postIDCallback(constant, twitLongerId, data.id_str)
            switch (tweetType) {
            case "New": infoBanner.showText(qsTr("Tweet sent successfully")); break;
            case "Reply": infoBanner.showText(qsTr("Reply sent successfully")); break;
            }
            pendingTweet = false
        }
        function postTweetLonger()
        {
            var replyScreenName = placedText ? placedText.substring(1, placedText.indexOf(" ")) : ""
            TwitLonger.postTweet(constant, settings.userScreenName, tweetTextArea.text, tweetId, replyScreenName,
                                 twitLongerOnSuccess, commonOnFailure)
        }
*/
        function commonOnFailure(status, statusText) {
            infoBanner.showHttpError(status, statusText)
            pendingTweet = false
            pageStack.push(Qt.resolvedUrl("NewTweetPage.qml"))
        }


        function postTweet(tweetid, tweettype, tweettext, tweetimage, lon, lat)
        {
            latitude = lat
            longitude = lon
            tweetText = tweettext
            tweetImage = tweetimage
            tweetType = tweettype
            tweetId = tweetid
            tweetImage = tweetimage
            pendingTweet = true
            if (tweetType == "New" || tweeType == "Reply") {
                if (tweetImage != '') {
                    imageUploader.run();
                }
                else /* if (tweettext.length()) */{
                        Twitter.postStatus(tweetText, tweetId ,latitude, longitude,
                                           postStatusOnSuccess, commonOnFailure)
                        pendingTweet = true
                }
/* FIXME
                else if (tweetTextArea.errorHighlight && switchLong.checked) { // actually checked is pointless to check since we dont come here if not checked and message is to long
                    internal.postTweetLonger()
                }
                */
            }
            else if (tweetType == "RT") {
                console.log("id" + tweetId)
                Twitter.postRetweet(tweetId, postStatusOnSuccess, commonOnFailure)
                pendingTweet = true
            }
            else if (tweetType == "DM") {
                Twitter.postDirectMsg(tweetTextArea.text, screenName,
                                      postStatusOnSuccess, commonOnFailure)
                pendingTweet = true
            }
        }
    }

    Component.onCompleted: {
        settings.loadSettings()
    }
}
