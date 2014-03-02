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
import "Component"
import "Services/Twitter.js" as Twitter

Page {
    id: aboutPage

    SilicaFlickable {
        id: aboutPageFlickable
        anchors.fill: parent
        contentHeight: aboutColumn.height

        Column {
            PageHeader {
                title: qsTr("About Tweetian")
            }

            id: aboutColumn
            anchors { left: parent.left; right: parent.right }
            height: childrenRect.height

            SectionHeader { text: qsTr("About Tweetian") }

            Item {
                anchors { left: parent.left; right: parent.right }
                height: aboutText.height + 2 * aboutText.anchors.margins

                Text {
                    id: aboutText
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left; right: parent.right
                        margins: constant.paddingMedium
                    }
                    wrapMode: Text.Wrap
                    font.pixelSize: constant.fontSizeMedium
                    color: constant.colorLight
                    text: qsTr("Tweetian is a feature-rich Twitter app for smartphones, powered by Qt and QML. \
It has a simple, native and easy-to-use UI that will surely make you enjoy the Twitter experience on your \
smartphone. Tweetian is open source and licensed under GPL v3.")
                }
            }

            SectionHeader { text: qsTr("Version") }

            Item {
                anchors { left: parent.left; right: parent.right }
                height: versionText.height + 2 * versionText.anchors.margins

                Text {
                    id: versionText
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left; right: parent.right
                        margins: constant.paddingMedium
                    }
                    font.pixelSize: constant.fontSizeMedium
                    color: constant.colorLight
                    wrapMode: Text.Wrap
                    text: APP_VERSION
                }
            }

            SectionHeader { text: qsTr("Original Author") }

            AboutPageItem {
                imageSource: "Image/DicksonBetaDP.png"
                text: "@DicksonBeta"
                onClicked: pageStack.push(Qt.resolvedUrl("UserPage.qml"), {screenName: "DicksonBeta"})
            }

            SectionHeader { text: qsTr("About Sailfish OS port") }

            Item {
                anchors { left: parent.left; right: parent.right }
                height: sailfishText.height + 2 * sailfishText.anchors.margins

                Text {
                    id: sailfishText
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left; right: parent.right
                        margins: constant.paddingMedium
                    }
                    font.pixelSize: constant.fontSizeMedium
                    color: constant.colorLight
                    wrapMode: Text.Wrap
                    text: "Sailfish-port is maintained by Vesa-Matti Hartikainen (@veskuh) and Siteshwar Vashisht (@SiteshwarV), with icons and code from Stephan Beyerle (@Morpog)."
                }

            }
            AboutPageItem {
                imageSource: "Image/avatar_placeholder.png"
                text: "@veskuh"
                onClicked: pageStack.push(Qt.resolvedUrl("UserPage.qml"), {screenName: "veskuh"})
            }
            AboutPageItem {
                imageSource: "Image/avatar_placeholder.png"
                text: "@siteshwarv"
                onClicked: pageStack.push(Qt.resolvedUrl("UserPage.qml"), {screenName: "siteshwarv"})
            }
            AboutPageItem {
                imageSource: "Image/avatar_placeholder.png"
                text: "@Morpog"
                onClicked: pageStack.push(Qt.resolvedUrl("UserPage.qml"), {screenName: "Morpog"})
            }

            SectionHeader { text: qsTr("Powered By") }

            AboutPageItem {
                imageSource: "Image/twitter-bird-white-on-blue.png"
                text: "Twitter"
                onClicked: pageStack.push(Qt.resolvedUrl("UserPage.qml"), {screenName: "twitter"})
            }

            AboutPageItem {
                imageSource: "Image/qt_icon.png"
                text: "Qt"
                onClicked: pageStack.push(Qt.resolvedUrl("UserPage.qml"), {screenName: "qtproject"})
            }

            SectionHeader { text: qsTr("Legal") }

            AboutPageItem {
                id: privacyButton
                imageSource: "Image/twitter-bird-white-on-blue.png"
                text: qsTr("Twitter Privacy Policy")
                onClicked: {
                    Twitter.getPrivacyPolicy(callback.privacyOnSuccess, callback.onFailure)
                    loadingRect.visible = true
                }
            }

            AboutPageItem {
                id: tosButton
                imageSource: "Image/twitter-bird-white-on-blue.png"
                text: qsTr("Twitter Terms of Service")
                onClicked: {
                    Twitter.getTermsOfService(callback.tosOnSuccess, callback.onFailure)
                    loadingRect.visible = true
                }
            }
        }
    }

    VerticalScrollDecorator { flickable: aboutPageFlickable }

    QtObject {
        id: callback

        function privacyOnSuccess(data) {
            var param = {text: data.privacy, headerText: privacyButton.text, headerIcon: privacyButton.imageSource}
            pageStack.push(Qt.resolvedUrl("TextPage.qml"), param)
            loadingRect.visible = false
        }

        function tosOnSuccess(data) {
            var param = {text: data.tos, headerText: tosButton.text, headerIcon: tosButton.imageSource}
            pageStack.push(Qt.resolvedUrl("TextPage.qml"), param)
            loadingRect.visible = false
        }

        function onFailure(status, statusText) {
            infoBanner.showHttpError(status, statusText)
            loadingRect.visible = false
        }
    }
}
