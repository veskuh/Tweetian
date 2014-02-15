/*
    Copyright (C) 2012 Dickson Leong
    Copyright (C) 2014 Siteshwar Vashisht
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
import "../Component"
import "../Delegate"

AbstractSearch {
    id: userSearchListView

    property bool busy: false
    property bool firstTimeLoaded: false

    mode: "User"

    function refresh(type) {
        firstTimeLoaded = true;
        if (userSearchListView.count <= 0)
            type = "all";
        switch (type) {
        case "all": internal.page = 1; userSearchListView.model.clear(); break;
        case "older": ++internal.page; break;
        default: throw new Error("Invalid type: " + type);
        }
        internal.reloadType = type
        Twitter.getUserSearch(searchString, internal.page, internal.userSearchOnSuccess, internal.userSearchOnFailure)
        busy = true
    }

    function positionAtTop() {
        userSearchListView.positionViewAtBeginning()
    }

    footer: LoadMoreButton {
        visible: userSearchListView.count > 0
        enabled: !busy
        onClicked: refresh("older")
    }
    delegate: UserDelegate {}
    model: ListModel {}

    Text {
        anchors.centerIn: parent
        font.pixelSize: constant.fontSizeXXLarge
        color: constant.colorMid
        text: qsTr("No search result")
        visible: userSearchListView.count == 0 && !busy
    }

    ScrollDecorator { flickable: userSearchListView }

    WorkerScript {
        id: userSearchParser
        source: "../WorkerScript/UserParser.js"
        onMessage: {
            busy = false
        }
    }

    QtObject {
        id: internal

        property int page: 1
        property string reloadType: "all"

        function userSearchOnSuccess(data) {
            userSearchParser.sendMessage({ type: reloadType, data: data, model: userSearchListView.model })
        }

        function userSearchOnFailure(status, statusText) {
            infoBanner.showHttpError(status, statusText)
            busy = false
        }
    }
}
