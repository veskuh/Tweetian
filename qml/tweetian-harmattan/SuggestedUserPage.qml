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
import "Component"
import "Delegate"
import "Services/Twitter.js" as Twitter

Page {
    id: suggestedUserPage

    property string slug: ""

    Component.onCompleted: script.refresh()

    /*
    tools: ToolBarLayout {
        ToolIcon {
            id: backButton
            platformIconId: "toolbar-back" + (enabled ? "" : "-dimmed")
            onClicked: pageStack.pop()
        }
    }*/

    ListView {
        id: suggestedUserView
        anchors { top: header.bottom; bottom: parent.bottom; left: parent.left; right: parent.right }
        delegate: UserDelegate {}
        model: ListModel {}
    }

//    ScrollDecorator { flickableItem: suggestedUserView }

    PageHeader {
        id: header
        title: qsTr("Suggested Users")

    }

    WorkerScript {
        id: userParser
        source: "WorkerScript/UserParser.js"
        onMessage: {
        }
    }

    QtObject {
        id: script

        function refresh() {
            Twitter.getSuggestedUser(slug, onSuccess, onFailure)
        }

        function onSuccess(data) {
            header.title += ": " + data.name
            var msg = {
                type: "all",
                data: data.users,
                model: suggestedUserView.model
            }
            userParser.sendMessage(msg)
        }

        function onFailure(status, statusText) {
            infoBanner.showHttpError(status, statusText)
        }
    }
}
