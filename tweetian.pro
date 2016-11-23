TEMPLATE = app
TARGET = harbour-tweetian

# Application version

# Since harbour does not distinguish build numbers
# we cannot just differentiate from upstream by build number
# thus using 2.x.x from now on for sailfish port
# based on upstream 1.8.3
VERSION = "2.0.8"
DEFINES += APP_VERSION=\\\"$$VERSION\\\"

# Qt Library
QT += network

HEADERS += \
    src/qmlutils.h \
    src/thumbnailcacher.h \
    src/userstream.h \
    src/networkmonitor.h \
    src/imageuploader.h \
    src/notificationutils.h

SOURCES += main.cpp \
    src/qmlutils.cpp \
    src/thumbnailcacher.cpp \
    src/userstream.cpp \
    src/networkmonitor.cpp \
    src/imageuploader.cpp \
    src/notificationutils.cpp

OTHER_FILES += i18n/tweetian_*.ts \
    harbour-tweetian.desktop \
    README.md \
    qml/tweetian-harmattan/*.qml \
    qml/tweetian-harmattan/*.js \
    qml/tweetian-harmattan/ListPageCom/*.qml \
    qml/tweetian-harmattan/MainPageCom/*.qml \
    qml/tweetian-harmattan/UserPageCom/*.qml \
    qml/tweetian-harmattan/SearchPageCom/*.qml \
    qml/tweetian-harmattan/Component/*.qml \
    qml/tweetian-harmattan/Delegate/*.qml \
    qml/tweetian-harmattan/Dialog/*.qml \
    qml/tweetian-harmattan/Utils/*js \
    qml/tweetian-harmattan/Services/*.js

CONFIG += link_pkgconfig
CONFIG += c++11
packagesExist(sailfishapp) {
    PKGCONFIG += sailfishapp mlite5
    CONFIG += qdeclarative-boostable mdatauri

    include(notifications/notifications.pri)

    desktopfile.files = $${TARGET}.desktop
    desktopfile.path = /usr/share/applications
    export (desktopfile)
    target.path = /usr/bin

    sailfish_icon.files = harbour-tweetian.png
    sailfish_icon.path = /usr/share/icons/hicolor/86x86/apps

    INCLUDEPATH += /usr/include/sailfishapp

    INSTALLS += target sailfish_icon desktopfile
    QT += dbus quick qml

    RESOURCES += qml-harmattan.qrc

    HEADERS += src/tweetianif.h
    SOURCES += src/tweetianif.cpp

    OTHER_FILES += rpm/* \
                   qml/tweetian-harmattan/WorkerScript/* \
                   qml/tweetian-harmattan/SettingsPageCom/*qml

}
