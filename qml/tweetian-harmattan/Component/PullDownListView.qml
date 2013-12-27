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

SilicaListView {
    id: root

    property string lastUpdate: ""
    signal pulledDown()

    // Private
    // On Silica We use pulldown menu for refresh instead
    /*property bool __wasAtYBeginning: false
    property int __initialContentY: 0
    property bool __toBeRefresh: false

    flickableDirection: Flickable.VerticalFlick
    //header: PullToRefreshHeader {}
    onMovementStarted: {
        __wasAtYBeginning = atYBeginning
        __initialContentY = contentY
    }
    onMovementEnded: {
        if (__toBeRefresh) {
            pulledDown()
            __toBeRefresh = false
        }
    }
    onContentYChanged: detectPullDownTimer.running = true

    Timer {
        id: detectPullDownTimer
        interval: 250
        onTriggered: if (__wasAtYBeginning && __initialContentY - contentY > 100) __toBeRefresh = true
    }*/
}
