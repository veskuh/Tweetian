import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: dialog

    property alias model: list.model
    property alias selectedIndex: list.currentIndex
    property string titleText

    SilicaListView {
        anchors.fill: parent
        header: DialogHeader {
            acceptText: titleText
        }

        id: list

        delegate: ListItem {
            Label {
                anchors.centerIn: parent
                text: name
                color: list.currentIndex === index ? Theme.highlightColor : Theme.primaryColor

            }
            onClicked: {
                selectedIndex = index
                dialog.accept()
            }
        }
    }
}
