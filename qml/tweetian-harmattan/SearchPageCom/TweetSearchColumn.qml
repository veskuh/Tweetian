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
import "../Services/Twitter.js" as Twitter
import "../Utils/Calculations.js" as Calculate
import "../Component"
import "../Delegate"

AbstractSearch {
    id: tweetSearchListView

    property bool busy: false
    property int unreadCount: 0
    property bool firstTimeLoaded: false
    property string lastUpdate: ""

    mode: "Tweet"

    function refresh(type) {
        firstTimeLoaded = true;
        if (tweetSearchListView.count <= 0)
            type = "all";
        var sinceId = "", maxId = ""
        switch (type) {
        case "newer": sinceId = tweetSearchListView.model.get(0).id; break;
        case "older": maxId =  tweetSearchListView.model.get(tweetSearchListView.count - 1).id; break;
        case "all": tweetSearchListView.model.clear(); break;
        default: throw new Error("Invalid type");
        }
        internal.reloadType = type
        Twitter.getSearch(searchString, sinceId, Calculate.minusOne(maxId),
                          internal.searchOnSuccess, internal.searchOnFailure)
        busy = true
    }

    function positionAtTop() {
        tweetSearchListView.positionViewAtBeginning()
    }

    property bool stayAtCurrentPosition: internal.reloadType === "newer"
    footer: LoadMoreButton {
        visible: tweetSearchListView.count > 0
        enabled: !busy
        onClicked: refresh("older")
    }
    delegate: TweetDelegate {}
    model: ListModel {}

    onAtYBeginningChanged: if (atYBeginning) unreadCount = 0
    onContentYChanged: refreshUnreadCountTimer.running = true

    Timer {
        id: refreshUnreadCountTimer
        interval: 250
        repeat: false
        onTriggered: unreadCount = Math.min(tweetSearchListView.indexAt(0, tweetSearchListView.contentY + 5) + 1,
                                            unreadCount)
    }

    Text {
        anchors.centerIn: parent
        font.pixelSize: constant.fontSizeXXLarge
        color: constant.colorMid
        text: qsTr("No search result")
        visible: tweetSearchListView.count == 0 && !busy
    }

    ScrollDecorator { flickable: tweetSearchListView }

    WorkerScript {
        id: searchParser
        source: "../WorkerScript/SearchParser.js"
        onMessage: {
            if (internal.reloadType === "newer") unreadCount = messageObject.newTweetCount
            else unreadCount = 0
            busy = false
        }
    }

    QtObject {
        id: internal

        property string reloadType: "all"

        function searchOnSuccess(data) {
            if (reloadType != "older") tweetSearchListView.lastUpdate = new Date().toString()
            searchParser.sendMessage({ type: reloadType, model: tweetSearchListView.model, data: data })
        }

        function searchOnFailure(status, statusText) {
            infoBanner.showHttpError(status, statusText)
            busy = false
        }
    }
}
