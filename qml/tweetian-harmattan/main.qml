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

ApplicationWindow {
    id: window
    initialPage: MainPage { id: mainPage }
    cover: CoverBackground {

        CoverActionList {
            CoverAction {
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

    Component.onCompleted: {
        settings.loadSettings()
    }
}
