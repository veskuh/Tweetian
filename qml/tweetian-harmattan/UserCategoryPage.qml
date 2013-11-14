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
import "Services/Twitter.js" as Twitter

Page {
    id: userCategoryPage

    Component.onCompleted: script.refresh()

    ListView {
        id: userCategoryView
        anchors { top: header.bottom; bottom: parent.bottom; left: parent.left; right: parent.right }
        delegate: userCategoryDelegate
        model: ListModel {}
    }

    //ScrollDecorator { flickableItem: userCategoryView }

    PageHeader {
        id: header
        title: qsTr("Suggested User Categories")
    }

    QtObject {
        id: script

        function onSuccess(data) {
            for (var i=0; i<data.length; i++) {
                userCategoryView.model.append(data[i])
            }
            header.busy = false
        }

        function onFailure(status, statusText) {
            infoBanner.showHttpError(status, statusText)
            header.busy = false
        }

        function refresh() {
            userCategoryView.model.clear()
            Twitter.getSuggestedUserCategories(onSuccess, onFailure)
            header.busy = true
        }
    }

    Component {
        id: userCategoryDelegate

        ListItem {
            id: userCategoryItem
            width: ListView.view.width
            height: Math.max(categoryText.height + 2 * constant.paddingLarge, 80)
            subItemIndicator: true
            marginLineVisible: false

            Text {
                id: categoryText
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: userCategoryItem.left; leftMargin: constant.paddingLarge
                    right: countBubble.left; rightMargin: constant.paddingMedium
                }
                elide: Text.ElideRight
                text: model.name
                font.pixelSize: constant.fontSizeLarge
                font.family: Theme.fontFamily
                color: constant.colorLight
            }

            Label {
                id: countBubble
                anchors {
                    right: parent.right; rightMargin: constant.paddingMedium + listItemRightMargin
                    verticalCenter: parent.verticalCenter
                }
                text: model.size
            }

            onClicked: pageStack.push(Qt.resolvedUrl("SuggestedUserPage.qml"), {slug: model.slug})
        }
    }
}
