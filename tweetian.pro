TEMPLATE = app
TARGET = harbour-tweetian

# Application version
VERSION = 1.8.2
DEFINES += APP_VERSION=\\\"$$VERSION\\\"

# Qt Library
QT += network location positioning svg

# Qt Mobility Library
CONFIG += mobility

MOBILITY += feedback location gallery

HEADERS += \
    src/qmlutils.h \
    src/thumbnailcacher.h \
    src/userstream.h \
    src/networkmonitor.h \
    src/imageuploader.h

SOURCES += main.cpp \
    src/qmlutils.cpp \
    src/thumbnailcacher.cpp \
    src/userstream.cpp \
    src/networkmonitor.cpp \
    src/imageuploader.cpp

simulator{
    qml_harmattan.source = qml/tweetian-harmattan
    qml_harmattan.target = qml
    qml_symbian.source = qml/tweetian-symbian
    qml_symbian.target = qml
    DEPLOYMENTFOLDERS = qml_harmattan qml_symbian

    RESOURCES += qml-harmattan.qrc qml-symbian.qrc

    HEADERS += src/harmattanutils.h src/symbianutils.h
    SOURCES += src/harmattanutils.cpp src/symbianutils.cpp
}

contains(MEEGO_EDITION,harmattan){
    QT += dbus
    CONFIG += qdeclarative-boostable shareuiinterface-maemo-meegotouch share-ui-plugin share-ui-common mdatauri sailfishapp
    DEFINES += Q_OS_HARMATTAN
    RESOURCES += qml-harmattan.qrc

    include(notifications/notifications.pri)
    splash.files = splash/tweetian-splash-portrait.jpg splash/tweetian-splash-landscape.jpg
    splash.path = /opt/tweetian/splash
    INSTALLS += splash

    HEADERS += src/tweetianif.h src/harmattanutils.h
    SOURCES += src/tweetianif.cpp src/harmattanutils.cpp
}

symbian{
    TARGET.UID3 = 0x2005e90a
    TARGET.CAPABILITY += NetworkServices Location LocalServices ReadUserData WriteUserData
    TARGET.EPOCHEAPSIZE = 0x40000 0x4000000

    CONFIG += qt-components
    vendorinfo += "%{\"Dickson\"}" ":\"Dickson\""
    my_deployment.pkg_prerules = vendorinfo
    DEPLOYMENT += my_deployment
    DEPLOYMENT.display_name = Tweetian
    ICON = Tweetian.svg
    RESOURCES += qml-symbian.qrc

    # Symbian have a different syntax
    DEFINES -= APP_VERSION=\\\"$$VERSION\\\"
    DEFINES += APP_VERSION=\"$$VERSION\"

    HEADERS += src/symbianutils.h
    SOURCES += src/symbianutils.cpp

    LIBS += -lavkon -lapgrfx -leikcore -lcone -lapmime
}

OTHER_FILES += qtc_packaging/debian_harmattan/* \
    i18n/tweetian_*.ts \
    harbour-tweetian.desktop \
    README.md \
    qml/tweetian-harmattan/*.qml \
    qml/tweetian-harmattan/*.js \
    qml/tweetian-harmattan/MainPageCom/*.qml \
    qml/tweetian-harmattan/Component/*.qml \
    qml/tweetian-harmattan/Delegate/*.qml \
    qml/tweetian-harmattan/Dialog/*.qml \
    qml/tweetian-harmattan/Utils/*js \
    qml/tweetian-harmattan/CoverPage.qml

CONFIG += link_pkgconfig
packagesExist(sailfishapp) {
message("sailfishapp")
    PKGCONFIG += sailfishapp mlite5

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
    CONFIG += qdeclarative-boostable shareuiinterface-maemo-meegotouch share-ui-plugin share-ui-common mdatauri
    DEFINES += Q_OS_HARMATTAN
    RESOURCES += qml-harmattan.qrc

    HEADERS += src/tweetianif.h
    SOURCES += src/tweetianif.cpp

    HEADERS += src/harmattanutils.h
    SOURCES += src/harmattanutils.cpp
    OTHER_FILES += rpm/* \
                   qml/tweetian-harmattan/WorkerScript/* \
                   qml/tweetian-harmattan/SettingsPageCom/*qml

} else {
    # Please do not modify the following two lines. Required for deployment.
    include(qmlapplicationviewer/qmlapplicationviewer.pri)
    qtcAddDeployment()
}
