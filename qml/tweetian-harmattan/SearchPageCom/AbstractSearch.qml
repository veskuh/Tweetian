/*
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

SilicaListView {
    id: searchColumn
    property string mode: ""

    anchors.fill: parent

    Component.onCompleted: {
        if (!isSavedSearch || !savedSearchId) internal.checkIsSavedSearch()
        if (!searchColumn.firstTimeLoaded) searchColumn.refresh("all")
    }

    RemorsePopup { id: remorse }

    PullDownMenu {
        MenuItem {
            text: qsTr("Save Search")
            onClicked: internal.saveSearch()
            visible: !isSavedSearch
        }

        MenuItem {
            text: qsTr("Remove Saved Search")
            onClicked: remorse.execute(qsTr("Removing saved search "), function() { internal.removeSavedSearch(); } )
            visible: isSavedSearch
        }

        MenuItem {
            text: qsTr("Refresh")
            onClicked: mode == "Tweet" ? searchColumn.refresh("newer") : searchColumn.refresh("all")
        }

        MenuItem {
            text: qsTr("User Search")
            onClicked: pageStack.replace(Qt.resolvedUrl("UserSearchPage.qml"), { searchString: searchString })
            visible: mode == "Tweet"
        }

        MenuItem {
            text: qsTr("Tweet Search")
            onClicked: pageStack.replace(Qt.resolvedUrl("TweetSearchPage.qml"), { searchString: searchString })
            visible: mode == "User"
        }
    }

    header: Column {
        PageHeader {
            id: titleHeader
            title: qsTr(mode + " Search")
        }

        Item {
            id: searchTextFieldContainer
            width: searchColumn.width
            height: searchTextField.height + 2 * searchTextField.anchors.margins

            TextField {
                id: searchTextField
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 0 }
                placeholderText: qsTr("Search for tweets or users")
                text: searchString
                EnterKey.text: qsTr("Search")
                EnterKey.onClicked: {
                    searchString = searchTextField.text
                    parent.focus = true // remove activeFocus on searchTextField
                    internal.changeSearch()
                }
                onActiveFocusChanged: if (!activeFocus) resetSearchTextTimer.start()
            }

            Timer {
                id: resetSearchTextTimer
                interval: 100
                onTriggered: searchTextField.text = searchString
            }
        }
    }

    QtObject {
        id: internal

        function changeSearch() {
            searchColumn.firstTimeLoaded = false
            searchColumn.refresh("all")
            isSavedSearch = false
            savedSearchId = ""
            checkIsSavedSearch()
        }

        function savedSearchOnSuccess(data) {
            if (cache.trendsModel.count > 0)
                cache.trendsModel.insert(0,{"title": data.name, "query": data.query, "id": data.id, "type": qsTr("Saved Searches")})
            isSavedSearch = true
            savedSearchId = data.id
            loadingRect.visible = false
            infoBanner.showText(qsTr("The search %1 is saved successfully").arg("\""+data.name+"\""))
        }

        function savedSearchOnFailure(status, statusText) {
            infoBanner.showHttpError(status, statusText)
            loadingRect.visible = false
        }

        function removeSearchOnSuccess(data) {
            for (var i=0; i<cache.trendsModel.count; i++) {
                if (cache.trendsModel.get(i).title === data.name) {
                    cache.trendsModel.remove(i)
                    break
                }
            }
            isSavedSearch = false
            savedSearchId = ""
            loadingRect.visible = false
            infoBanner.showText(qsTr("The saved search %1 is removed successfully").arg("\""+data.name+"\""))
        }

        function removeSearchOnFailure(status, statusText) {
            infoBanner.showHttpError(status, statusText)
            loadingRect.visible = false
        }

        function checkIsSavedSearch() {
            for (var i=0; i<cache.trendsModel.count; i++) {
                if (cache.trendsModel.get(i).type !== qsTr("Saved Searches"))
                    break
                if (cache.trendsModel.get(i).title === searchString) {
                    isSavedSearch = true
                    savedSearchId = cache.trendsModel.get(i).id
                    break
                }
            }
        }

        function saveSearch() {
            Twitter.postSavedSearches(searchString, savedSearchOnSuccess, savedSearchOnFailure)
            loadingRect.visible = true
        }

        function removeSavedSearch() {
            Twitter.postRemoveSavedSearch(searchPage.savedSearchId, removeSearchOnSuccess, removeSearchOnFailure)
            loadingRect.visible = true
        }
    }
}
