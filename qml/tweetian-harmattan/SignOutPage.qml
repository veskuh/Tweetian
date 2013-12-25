/*
    Copyright (C) 2013 Siteshwar Vashisht
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

import "SettingsPageCom/AccountTabScript.js" as AccountScript

Page {
    id: signOutPage

    SilicaFlickable {
        anchors.fill: parent
        PullDownMenu {
            MenuItem {
                text: qsTr("No")
                onClicked: pageStack.pop();
            }
            MenuItem {
                text: qsTr("Yes")
                onClicked: {
                    AccountScript.twitterSignOut();
                }
            }
        }

        Text {
            anchors { horizontalCenter: parent.horizontalCenter; margins: constant.paddingMedium }
            text: qsTr("Are you sure you want to sign out ?")
            wrapMode: Text.Wrap
            color: constant.colorLight
        }
    }
}
