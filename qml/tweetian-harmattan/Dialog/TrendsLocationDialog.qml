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

import ".."

Dialog {
    id: root
    allowedOrientations: Orientation.All
    property bool __isClosing: false

    property alias selectedIndex: trendsLocationList.currentIndex

    Constant { id: constant }

    SilicaListView {
        id: trendsLocationList
        anchors { fill: parent; leftMargin: constant.paddingMedium; }
        model: trendsLocationModel
        header: PageHeader { title: qsTr("Trends Location"); }
        delegate: BackgroundItem {
            Text {
                text: name
                font.family: Theme.fontFamily
                color: highlighted ? constant.colorHighlighted : constant.colorLight
            }

            onClicked: {
                trendsLocationList.currentIndex = index;
                root.accept();
            }
        }
    }

    Component.onCompleted:open()
}
