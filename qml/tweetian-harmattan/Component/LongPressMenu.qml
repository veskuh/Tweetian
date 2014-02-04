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

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../Component"

ContextMenu {
    id: root

    property variant tweet

    MenuItem {
        text: qsTr("Reply")
        onClicked: {
            var prop = {
                type: "Reply",
                tweetId: tweet.id,
                placedText: "@" + tweet.retweetScreenName + " "
            }
            pageStack.push(Qt.resolvedUrl("../NewTweetPage.qml"), prop)
        }
    }

    MenuItem {
        text: qsTr("Retweet")
        onClicked: {
            var text = "RT @" + tweet.retweetScreenName + ": ";
            if (tweet.isRetweet) text += "RT @" + tweet.screenName + ": ";
            text += tweet.plainText;
            pageStack.push(Qt.resolvedUrl("../NewTweetPage.qml"), {type: "RT", placedText: text, tweetId: tweet.id})
        }
    }

    MenuItem {
        text: qsTr("%1 Profile").arg("<font color=\"LightSeaGreen\">@" + tweet.retweetScreenName + "</font>")
        onClicked: pageStack.push(Qt.resolvedUrl("../UserPage.qml"), { screenName: tweet.retweetScreenName })
    }

    MenuItem {
        id: rtScreenName
        text: qsTr("%1 Profile").arg("<font color=\"LightSeaGreen\">@" + tweet.screenName + "</font>")
        visible: tweet.isRetweet
        onClicked: pageStack.push(Qt.resolvedUrl("../UserPage.qml"), { screenName: tweet.screenName })
    }
}
