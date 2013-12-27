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

Page {
    id: muteTab

    PageHeader {
        id: header
        title: qsTr("Mute")
    }

    TextArea {
        id: muteTextArea
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom

            margins: constant.paddingMedium
            bottomMargin: Qt.inputMethod.visible
                          ? anchors.margins : buttonContainer.height + 2 * buttonContainer.anchors.margins
        }
        font.pixelSize: constant.fontSizeXLarge
        placeholderText: qsTr("Example:\n%1").arg("@nokia #SwitchtoLumia\nsource:Tweet_Button\niPhone")
        text: settings.muteString
    }

    Item {
        id: buttonContainer
        anchors { top: muteTextArea.bottom; left: parent.left; right: parent.right; margins: constant.paddingMedium }
        height: helpButton.height + (saveText.visible ? saveText.anchors.topMargin + saveText.height : 0)

        Button {
            id: helpButton
            anchors { top: parent.top; left: parent.left }
            width: (parent.width - saveButton.anchors.leftMargin) / 2
            text: qsTr("Help")
            onClicked: dialog.createMessageDialog(qsTr("Mute"), infoText.mute)
        }

        Button {
            id: saveButton
            anchors {
                top: parent.top; right: parent.right
                left: helpButton.right; leftMargin: constant.paddingMedium
            }
            text: qsTr("Save")
            enabled: settings.muteString !== muteTextArea.text
            onClicked: settings.muteString = muteTextArea.text
        }

        Text {
            id: saveText
            anchors {
                top: helpButton.bottom; topMargin: constant.paddingMedium
                left: parent.left; right: parent.right
            }
            visible: saveButton.enabled
            wrapMode: Text.Wrap
            text: qsTr("Changes will not be save until you press the save button")
            font.pixelSize: constant.fontSizeSmall
            color: constant.colorLight
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
