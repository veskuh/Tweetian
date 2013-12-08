import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    SilicaFlickable {
        anchors.fill: parent

        PageHeader {
            id: title
            title: "More options"
        }

        Column {
            anchors.top: title.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.margins: Theme.paddingLarge
            spacing: Theme.paddingMedium

            Button {
                text: "About Tweetian"
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }

            Button {
                text: "User information"
                onClicked: pageStack.push(Qt.resolvedUrl("UserPage.qml"), {screenName: settings.userScreenName})
            }

            Button {
                text: "General Settings"
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPageCom/SettingGeneralTab.qml"))
            }

            Button {
                text: "Update Settings"
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPageCom/SettingRefreshTab.qml"))
            }

            Button {
                text: "Muting"
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPageCom/MuteTab.qml"))
            }
        }

    }
}
