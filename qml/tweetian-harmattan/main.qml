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
    allowedOrientations: Orientation.All
    initialPage: MainPage { id: mainPage }
    cover: (settings.oauthToken != "" && settings.oauthTokenSecret != "") ? Qt.resolvedUrl("CoverPage.qml") : undefined;
    property bool pendingTweet: false

    Settings { id: settings }

    Cache { id: cache }
    Constant { id: constant }

    ThemeEffect { id: basicHapticEffect; effect: ThemeEffect.Appear }

    Rectangle {
        id: infoBanner

        width: mainPage.width
        transformOrigin: Item.TopLeft

        rotation: switch (window.orientation) {
                  case Orientation.Portrait: return 0;
                  case Orientation.Landscape: return 90;
                  case Orientation.PortraitInverted: return 180;
                  case Orientation.LandscapeInverted: return 270;
                  }


        x: switch (window.orientation) {
           case Orientation.Portrait: return 0;
           case Orientation.Landscape: return mainPage.height;
           case Orientation.PortraitInverted: return window.width;
           case Orientation.LandscapeInverted: 0;
           }

        y: switch (window.orientation) {
           case Orientation.Portrait: return 0;
           case Orientation.Landscape: return 0;
           case Orientation.PortraitInverted: return window.height;
           case Orientation.LandscapeInverted: return mainPage.width;
           }

        height: infoText.height + 2 * Theme.paddingMedium

        color: Theme.highlightBackgroundColor
        opacity: 0.0
        // On top of everything
        z: 1
        visible: opacity > 0.0

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
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        Behavior on opacity { FadeAnimation {} }

        Timer {
            id: closeTimer
            interval: 3000
            onTriggered: infoBanner.opacity = 0.0
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                closeTimer.stop()
                infoBanner.opacity = 0.0
            }
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
            infoBanner.showText(qsTr("Launching external web browser..."))
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

    QtObject {
        id: userPageHelper
        /* This object is used by UserPage.qml by the RemorsePopup when follow/unfollow executes
           We make this global to prevent error if user swipe away after follow/unfollow
        */
        property bool isFollowing: false
        function followOnSuccess(data, following) {
            isFollowing = following;
            if (isFollowing)
                infoBanner.showText(qsTr("Followed the user %1 successfully").arg("@" + data.screen_name))
            else
                infoBanner.showText(qsTr("Unfollowed the user %1 successfully").arg("@" + data.screen_name))
        }

        function followOnFailure(status, statusText) {
            infoBanner.showText(statusText)
        }
    }
    QtObject {
        id: tweetPageHelper
        function deleteTweetOnSuccess(data) {
            if (pageStack.currentPage.objectName == "tweetPage")
            {
                pageStack.pop()
            }

            infoBanner.showText(qsTr("Tweet deleted successfully"))
            mainPage.timeline.removeTweet(data.id_str)
        }

        function commonOnFailure(status, statusText) {
            infoBanner.showHttpError(status, statusText)
            if (pageStack.currentPage.objectName == "tweetPage")
            {
                pageStack.pop()
            }
        }
    }

    ImageUploader {
        id: imageUploader
        service: settings.imageUploadService
        networkAccessManager: QMLUtils.networkAccessManager()
        onSuccess: {
            if (service == ImageUploader.Twitter) internalTweet.postStatusOnSuccess(JSON.parse(replyData))
            else {
                var imageLink = ""
                if (service == ImageUploader.TwitPic) imageLink = JSON.parse(replyData).url
                else if (service == ImageUploader.MobyPicture) imageLink = JSON.parse(replyData).media.mediaurl
                else if (service == ImageUploader.Imgly) imageLink = JSON.parse(replyData).url
                Twitter.postStatus(internalTweet.tweetText+" "+imageLink, internalTweet.tweetId, internalTweet.latitude, internalTweet.longitude,
                                   internalTweet.postStatusOnSuccess, internalTweet.commonOnFailure)
            }
        }
        onFailure: internalTweet.commonOnFailure(status, statusText)

        function run() {
            imageUploader.setFile(internalTweet.tweetImage)
            if (service == ImageUploader.Twitter) {
                imageUploader.setParameter("status", internalTweet.tweetText)
                if (internalTweet.tweetId) imageUploader.setParameter("in_reply_to_status_id", internalTweet.tweetId)
                if (internalTweet.latitude != 0.0 && internalTweet.longitude != 0.0) {
                    imageUploader.setParameter("lat", internalTweet.latitude.toString())
                    imageUploader.setParameter("long", internalTweet.longitude.toString())
                }
                imageUploader.setAuthorizationHeader(Twitter.getTwitterImageUploadAuthHeader())
            }
            else {
                if (service == ImageUploader.TwitPic) imageUploader.setParameter("key", constant.twitpicAPIKey)
                else if (service == ImageUploader.MobyPicture) imageUploader.setParameter("key", constant.mobypictureAPIKey)
                imageUploader.setParameter("message", internalTweet.tweetText)
                imageUploader.setAuthorizationHeader(Twitter.getOAuthEchoAuthHeader())
            }

            imageUploader.send()
        }
    }

    QtObject {
        id: internalTweet
//        property string twitLongerId: ""
        property bool exit: false
        property string tweetType: "New"
        property string screenName: ""
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
            screenName = ""
            tweetText = ""
            tweetImage = ""
            latitude = 0.0
            longitude = 0.0
            pendingTweet = false

            /* Refresh timeline and DMs after succesfully sending tweet or DM */
            mainPage.refreshAll();
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


        function postTweet(tweetid, tweettype, screenname, tweettext, tweetimage, lat, lon)
        {
            tweetId = tweetid
            tweetType = tweettype
            screenName = screenname
            tweetText = tweettext
            tweetImage = tweetimage
            latitude = lat
            longitude = lon
            pendingTweet = true
            if (tweetType == "New" || tweetType == "Reply") {
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
                Twitter.postDirectMsg(tweetText, screenName,
                                      postStatusOnSuccess, commonOnFailure)
                pendingTweet = true
            }
        }
    }

    Component.onCompleted: {
        settings.loadSettings()
    }
}
