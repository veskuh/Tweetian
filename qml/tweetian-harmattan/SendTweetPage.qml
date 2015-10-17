/*
    Copyright (C) 2013 Vesa-Matti Hartikainen
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
import Sailfish.Silica 1.0

Page {
    property alias busy: indicator.running
    property Page backDestination

    property bool ready: !busy && loaded && backDestination
    property bool loaded

    backNavigation: false
    allowedOrientations: Orientation.All

    onStatusChanged: {
        if (status === PageStatus.Active)
            loaded = true
    }

    onReadyChanged: {
        if (ready && status === PageStatus.Active)
            pageStack.pop(backDestination, PageStackAction.Immediate)
    }

    BusyIndicator {
        id: indicator
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
    }
}
