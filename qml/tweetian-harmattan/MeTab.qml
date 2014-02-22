/*
    Copyright (C) 2012 Dickson Leong
              (C) 2014 Vesa-Matti Hartikainen
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

import QtQuick 2.0
import Sailfish.Silica 1.0
import "Services/Twitter.js" as Twitter
import "Component"
import "Utils/Calculations.js" as Calculate
import "Utils/Parser.js" as Parser
import "SettingsPageCom/AccountTabScript.js" as AccountScript

Item {
    id: userPage

    implicitHeight: mainView.height; implicitWidth: mainView.width

    property string screenName
    property variant user: ({})
    property bool isFollowing: false

    function initialize() {
        if (user.hasOwnProperty("screenName"))
            internal.showUserData();
        else if (screenName === settings.userScreenName && cache.userInfo) {
            user = cache.userInfo;
            internal.showUserData();
        }
        else internal.refresh();
    }

    function positionAtTop() {
        userFlickable.contentY = 0
    }

    SilicaFlickable {
        id: userFlickable
        anchors.fill: parent
        flickableDirection: Flickable.VerticalFlick
        contentHeight: userColumn.height

        Column {
            id: userColumn
            anchors { top: parent.top; left: parent.left; right: parent.right }

            Item {
                id: headerItem
                anchors { left: parent.left; right: parent.right }
                height: mainView.height / 3.25

                Image {
                    id: headerImage
                    anchors.fill: parent
                    cache: false
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    source: {
                        if (user.profileBannerUrl)
                            return user.profileBannerUrl.concat(userPage.isPortrait ? "/web" : "/mobile_retina")
                        else
                            return "Image/banner_empty.png"
                    }
                    opacity: 0.9
                    onStatusChanged: if (status === Image.Error) source = "Image/banner_empty.png"
                }

                Item {
                    id: headerTopItem
                    anchors { left: parent.left; right: parent.right }
                    height: childrenRect.height

                    Rectangle {
                        id: profileImageContainer
                        anchors { right: parent.right; top: parent.top; margins: constant.paddingMedium }
                        width: profileImage.width + (border.width / 2); height: width
                        color: "black"
                        border.width: 2
                        border.color: profileImageMouseArea.pressed ? constant.colorTextSelection : constant.colorMid

                        Image {
                            id: profileImage
                            anchors.centerIn: parent
                            height: userNameText.height + screenNameText.height; width: height
                            cache: false
                            fillMode: Image.PreserveAspectCrop
                            source: user.profileImageUrl ? user.profileImageUrl.replace("_normal", "_bigger") : ""
                        }

                        MouseArea {
                            id: profileImageMouseArea
                            anchors.fill: parent
                            onClicked: {
                                var prop = { imageUrl: user.profileImageUrl.replace("_normal", "") }
                                pageStack.push(Qt.resolvedUrl("TweetImage.qml"), prop)
                            }
                        }
                    }

                    Text {
                        id: userNameText
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: profileImageContainer.left
                            margins: constant.paddingMedium
                        }
                        font.bold: true
                        font.pixelSize: constant.fontSizeMedium
                        font.family: Theme.fontFamily
                        color: "white"
                        style: Text.Raised
                        styleColor: "black"
                        text: user.name || ""
                        horizontalAlignment: Text.AlignRight
                    }

                    Text {
                        id: screenNameText
                        anchors {
                            top: userNameText.bottom
                            right: profileImageContainer.left; rightMargin: constant.paddingMedium
                            left: parent.left; leftMargin: constant.paddingMedium
                        }
                        font.pixelSize: constant.fontSizeMedium
                        font.family: Theme.fontFamily
                        color: "white"
                        style: Text.Raised
                        styleColor: "black"
                        text: user.screenName ? "@" + user.screenName : ""
                        horizontalAlignment: Text.AlignRight

                    }
                }

                Text {
                    id: descriptionText
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: headerTopItem.bottom
                        bottom: parent.bottom
                        margins: constant.paddingMedium
                    }
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: userPage.isPortrait ? 5 : 4 // TODO: remove hardcoded value
                    font.pixelSize: constant.fontSizeSmall
                    font.family: Theme.fontFamily
                    verticalAlignment: Text.AlignBottom
                    color: "white"
                    style: Text.Raised
                    styleColor: "black"
                    text: user.description || ""
                }
            }

            Rectangle {
                anchors { left: parent.left; right: parent.right }
                height: 1
                color: constant.colorDisabled
            }

            Repeater {
                id: userInfoRepeater

                function append(title, subtitle, clickedString) {
                    var item = {
                        title: title,
                        subtitle: subtitle,
                        clickedString: clickedString || ""
                    }
                    model.append(item)
                }

                anchors { left: parent.left; right: parent.right }
                model: ListModel {}
                delegate: ListItem {
                    id: listItem
                    parent: userInfoRepeater
                    height: Math.max(listItemColumn.height + 2 * constant.paddingMedium, 80)
                    subItemIndicator: model.clickedString
                    enabled: (!subItemIndicator || title === "Website")
                             || !user.isProtected
                             || isFollowing
                             || userPage.screenName === settings.userScreenName
                    onClicked: if (model.clickedString) eval(model.clickedString)
                    // TODO: Remove eval() if possible

                    Column {
                        id: listItemColumn
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left; leftMargin: constant.paddingLarge
                            right: parent.right
                            rightMargin: listItem.listItemRightMargin + constant.paddingMedium
                        }
                        height: childrenRect.height

                        Text {
                            id: titleText
                            anchors { left: parent.left; right: parent.right }
                            wrapMode: Text.Wrap

                            font.family: Theme.fontFamily
                            font.pixelSize: constant.fontSizeMedium
                            color: listItem.enabled ? constant.colorLight : constant.colorDisabled
                            text: title
                        }
                        Text {
                            id: subTitleText
                            anchors { left: parent.left; right: parent.right }
                            visible: subtitle !== ""
                            wrapMode: Text.Wrap
                            font.pixelSize: constant.fontSizeMedium
                            font.family: Theme.fontFamily
                            color: listItem.enabled ? constant.colorMid : constant.colorDisabled
                            text: subtitle
                        }
                    }
                }
            }
        }
        PullDownMenu {
            RemorsePopup { id: remorse }

            MenuItem {
                text: qsTr("Sign Out")
                onClicked: {
                    remorse.execute(qsTr("Signing out from Twitter"), function() { AccountScript.twitterSignOut(); } )
                }
            }
            MenuItem {
                text: "About Tweetian"
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }

            MenuItem {
                text: "Settings"
                onClicked: pageStack.push(Qt.resolvedUrl("MorePage.qml"))
            }
        }
    }

    VerticalScrollDecorator { flickable: userFlickable }

    QtObject {
        id: internal

        function refresh() {
            userInfoRepeater.model.clear()
            Twitter.getUserInfo(userPage.screenName, userInfoOnSuccess, userInfoOnFailure)
            loadingRect.visible = true
        }

        function showUserData() {
            if (user.url) userInfoRepeater.append(qsTr("Website"), user.url, "dialog.createOpenLinkDialog(subtitle)")
            if (user.location) userInfoRepeater.append(qsTr("Location"), user.location)
            userInfoRepeater.append(qsTr("Joined"), Qt.formatDate(new Date(user.createdAt), Qt.SystemLocaleShortDate))
            userInfoRepeater.append(qsTr("Tweets"), user.tweetsCount + " | " +
                                    Calculate.tweetsFrequency(user.createdAt, user.tweetsCount),
                                    "internal.pushUserPage(\"UserPageCom/UserTweetsPage.qml\")")
            userInfoRepeater.append(qsTr("Following"), user.followingCount.toString(),
                                    "internal.pushUserPage(\"UserPageCom/UserFollowingPage.qml\")")
            userInfoRepeater.append(qsTr("Followers"), user.followersCount.toString(),
                                    "internal.pushUserPage(\"UserPageCom/UserFollowersPage.qml\")")
            userInfoRepeater.append(qsTr("Favourites"), user.favouritesCount.toString(),
                                    "internal.pushUserPage(\"UserPageCom/UserFavouritesPage.qml\")")
            userInfoRepeater.append(qsTr("Subscribed List"), "",
                                    "internal.pushUserPage(\"UserPageCom/UserSubscribedListsPage.qml\")")
            userInfoRepeater.append(qsTr("Listed"), user.listedCount.toString(),
                                    "internal.pushUserPage(\"UserPageCom/UserListedPage.qml\")")
            isFollowing = user.isFollowing;
        }

        function userInfoOnSuccess(data) {
            user = Parser.parseUser(data);
            if (userPage.screenName === settings.userScreenName)
                cache.userInfo = user;
            showUserData();
            loadingRect.visible = false
        }

        function userInfoOnFailure(status, statusText) {
            if (status === 404) console.log(qsTr("The user %1 does not exist").arg("@" + userPage.screenName))
            else console.log(statusText)
            loadingRect.visible = false
        }

        function followOnSuccess(data, following) {
            isFollowing = following;
            if (isFollowing) console.log(qsTr("Followed the user %1 successfully").arg("@" + data.screen_name))
            else console.log(qsTr("Unfollowed the user %1 successfully").arg("@" + data.screen_name))
            loadingRect.visible = false
        }

        function followOnFailure(status, statusText) {
            console.log(statusText)
            loadingRect.visible = false
        }

        function pushUserPage(pageString) {
            pageStack.push(Qt.resolvedUrl(pageString), { user: user })
        }
    }
}
