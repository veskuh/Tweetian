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
import "Services/Twitter.js" as Twitter
import "Component"

Page {
    id: signInPage

    allowedOrientations: Orientation.All
    property string tokenTempo: ""
    property string tokenSecretTempo: ""

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: mainColumn.height + 2 * mainColumn.anchors.topMargin

        Column {
            id: mainColumn
            anchors {
                left: parent.left; right: parent.right; top: parent.top
                topMargin: constant.paddingMedium
                leftMargin: Theme.paddingLarge
                rightMargin: Theme.paddingLarge
            }
            spacing: constant.paddingMedium

            PageHeader {
                id: header
                title: qsTr("Sign In to Twitter")
                property bool busy: false
            }

            Text {
                anchors { left: parent.left; right: parent.right }
                font.pixelSize: constant.fontSizeXLarge
                color: constant.colorLight
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Welcome to Tweetian")
            }

            Text {
                anchors { left: parent.left; right: parent.right }
                font.pixelSize: constant.fontSizeMedium
                color: constant.colorLight
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: qsTr("To use Tweetian, you must sign in to your Twitter account first. \
Click the button below will launch an external web browser for you to sign in to your Twitter account.")
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: signInButton.width
                height: signInButton.height + 2 * constant.paddingXLarge

                Button {
                    id: signInButton
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("Sign In")
                    enabled: !header.busy
                    onClicked: internal.signInButtonClicked()
                }
            }

            Text {
                anchors { left: parent.left; right: parent.right }
                font.pixelSize: constant.fontSizeMedium
                color: constant.colorLight
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: qsTr("After sign in, a PIN code will display. Enter the PIN code in the text field \
below and click done.")
            }

            TextField {
                id: pinCodeTextField
                anchors {
                    left: parent.left; right: parent.right
                    // TextField has implicit large paddings
                    leftMargin: -Theme.paddingLarge
                    rightMargin: -Theme.paddingLarge
                }

                enabled: !header.busy
                inputMethodHints: Qt.ImhDigitsOnly
                placeholderText: "Enter PIN code"
                label: "PIN"
                EnterKey.enabled: text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: internal.doneButtonClicked()
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: pinCodeTextField.text != "" && !header.busy
                text: qsTr("Done")
                onClicked: internal.doneButtonClicked()
            }
        }

        VerticalScrollDecorator { flickable: flickable }
    }

    QtObject {
        id: internal

        function signInButtonClicked() {
            Twitter.postRequestToken(function(token, tokenSecret) {
                tokenTempo = token;
                tokenSecretTempo = tokenSecret;
                var signInUrl = "https://api.twitter.com/oauth/authorize?oauth_token=" + tokenTempo;
                Qt.openUrlExternally(signInUrl);
                infoBanner.showText(qsTr("Launching external web browser..."));
                header.busy = false;
                console.log("Launching web browser with url:", signInUrl);
             }, function(status, statusText) {
                 if (status === 401)
                     console.log(qsTr("Error: Unable to authorize with Twitter. \
Make sure the time/date of your phone is set correctly."))
                 else
                     infoBanner.showHttpError(status, statusText);
                 //header.busy = false;
             });
            // header.busy = true;
        }

        function doneButtonClicked() {
            Twitter.postAccessToken(tokenTempo, tokenSecretTempo, pinCodeTextField.text,
            function (token, tokenSecret, screenName) {
                settings.oauthToken = token
                settings.oauthTokenSecret = tokenSecret
                settings.userScreenName = screenName
                infoBanner.showText(qsTr("Signed in successfully"))
                settings.settingsLoaded()
                pageStack.pop(null)
            }, function(status, statusText) {
                if (status === 401) {
                    pinCodeTextField.text = "";
                    infoBanner.showText(qsTr("Error: Unable to authorize with Twitter. \
Please sign in again and enter the correct PIN code."))
                }
                else infoBanner.showHttpError(status, statusText);
                header.busy = false;
            });
            header.busy = true;
        }
    }
}
