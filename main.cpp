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

#include <QQmlContext>
#include <QQuickView>
#include <QtCore/QTranslator>
#include <QtCore/QLocale>
#include <QtCore/QFile>
#include <QGuiApplication>
#include <QtQml>
#include "src/qmlutils.h"
#include "src/imageuploader.h"
#include "src/thumbnailcacher.h"
#include "src/userstream.h"
#include "src/networkmonitor.h"
#include "src/harmattanutils.h"

#include <QtDBus/QDBusConnection>
#include "src/tweetianif.h"
#include <sailfishapp.h>

// To support image loading from Direct Messages we register an image provider
// that captures the URLs "http://dm/<authorization-token>".
// OAuth authorization token contains image url itself in the realm parameter.
class DMImageProvider : public QQuickImageProvider
{
public:
    DMImageProvider()
        : QQuickImageProvider(QQuickImageProvider::Image,
                              QQuickImageProvider::ForceAsynchronousImageLoading)
    {
    }

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize)
    {
        const QString authToken = QUrl::fromPercentEncoding(id.toLatin1());

        // We expect a fixed format of the token: real containing URL of the
        // image is in the real parameter which comes first in the list.
        QRegExp realmRe("^OAuth realm=\"([^\"]+)\"");
        if (realmRe.indexIn(authToken) != 0) {
            return QImage();
        }

        const QString url = QUrl::fromPercentEncoding(realmRe.cap(1).toLatin1());

        QImage image;
        QEventLoop loop;
        QNetworkAccessManager mgr;

        QObject::connect(&mgr, &QNetworkAccessManager::finished, [&] (QNetworkReply* reply) {
            if (!reply->error()) {
                image.loadFromData(reply->readAll());
                if (size) {
                    *size = image.size();
                }
            }

            loop.quit();
            reply->deleteLater();
        });

        QNetworkRequest request;
        request.setUrl(QUrl(url));
        request.setRawHeader("Authorization", authToken.toUtf8());
        request.setRawHeader("User-Agent", QMLUtils::userAgent().toLatin1());
        mgr.get(request);
        loop.exec();
        return image;
    }
};


Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    QString lang = QLocale::system().name();
    lang.truncate(2); // ignore the country code

    const QStringList appArgs = app->arguments();
    foreach (const QString &arg, appArgs) {
        if (arg.startsWith(QLatin1String("--lang="))) {
            lang = arg.mid(7);
            break;
        }
    }

    QTranslator translator;
    if (QFile::exists(":/i18n/tweetian_" + lang + ".qm")) {
        qDebug("Translation for \"%s\" exists", qPrintable(lang));
        translator.load("tweetian_" + lang, ":/i18n");
    }
    else {
        qDebug("Translation for \"%s\" not exists, using the default language (en)", qPrintable(lang));
        translator.load("tweetian_en", ":/i18n");
    }
    app->installTranslator(&translator);

    QString appName("Tweetian");
    app->setApplicationName(appName);
    app->setOrganizationName("harbour-tweetian");
    app->setApplicationVersion(APP_VERSION);
    QScopedPointer<QQuickView> view(SailfishApp::createView());

    view->setTitle(appName);
    DMImageProvider* dmImageProvider = new DMImageProvider;
    view->engine()->addImageProvider(QLatin1String("dm"), dmImageProvider);

    TweetianIf* tweetianIf = new TweetianIf(app.data(), view.data());
    QDBusConnection bus = QDBusConnection::sessionBus();
    bus.registerService("com.tweetian");
    bus.registerObject("/com/tweetian", app.data());

    QMLUtils qmlUtils(view.data());
    view->rootContext()->setContextProperty("QMLUtils", &qmlUtils);
    ThumbnailCacher thumbnailCacher;
    view->rootContext()->setContextProperty("thumbnailCacher", &thumbnailCacher);
    NetworkMonitor networkMonitor;
    view->rootContext()->setContextProperty("networkMonitor", &networkMonitor);
    view->rootContext()->setContextProperty("APP_VERSION", APP_VERSION);

    HarmattanUtils harmattanUtils;
    view->rootContext()->setContextProperty("harmattanUtils", &harmattanUtils);

    QObject::connect(&harmattanUtils, SIGNAL(newNotification()), tweetianIf, SLOT(sNewNotification()));

    qmlRegisterType<ImageUploader>("harbour.tweetian.Uploader", 1, 0, "ImageUploader");
    qmlRegisterType<UserStream>("harbour.tweetian.UserStream", 1, 0, "UserStream");

    view->setSource(QUrl("qrc:/qml/tweetian-harmattan/main.qml"));
    view->showFullScreen();
    return app->exec();
}





