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

import QtQuick 1.1
import com.nokia.symbian 1.1

ListItem{
    id: root

    property url imageSource: ""
    property string text: ""

    width: parent.width
    height: pic.height + 2 * constant.paddingMedium
    subItemIndicator: true
    platformInverted: settings.invertedTheme

    Image{
        id: pic
        anchors{ top: parent.top; left: parent.left; margins: constant.paddingMedium }
        source: root.imageSource
        sourceSize.width: constant.graphicSizeMedium
        sourceSize.height: constant.graphicSizeMedium
        cache: false
    }

    Text{
        anchors{ top: parent.top; bottom: parent.bottom; left: pic.right; right: parent.right }
        anchors.margins: constant.paddingMedium
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        font.pixelSize: constant.fontSizeMedium
        color: constant.colorLight
        text: root.text
    }
}