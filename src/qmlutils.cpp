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

#include "qmlutils.h"

#include <QtCore/QDateTime>
#include <QtGui/QClipboard>
#include <QtGui/QImage>
#include <QtGui/QPainter>
#include <QtGui/QDesktopServices>
#include <QQuickPaintedItem>
#include <QQuickView>
#include <QGuiApplication>
#include <QQmlEngine>
#include <QtNetwork/QNetworkAccessManager>

static const QString IMAGE_SAVING_PATH = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
// TODO come up with proper useragent
static const QString USER_AGENT = "Tweetian/" + QLatin1String(APP_VERSION) + " (Nokia; Qt; MeeGo/1.2; Harmattan)";

QMLUtils::QMLUtils(QQuickView *view, QObject *parent) :
    QObject(parent), m_view(view), clipboard(QGuiApplication::clipboard())
{
}

void QMLUtils::copyToClipboard(const QString &text)
{
#ifdef Q_WS_SIMULATOR
    qDebug("Text copied to clipboard: %s", qPrintable(text));
#endif
    clipboard->setText(text, QClipboard::Clipboard);
    clipboard->setText(text, QClipboard::Selection);
}

QString QMLUtils::saveImage(QQuickPaintedItem *imageObject) const
{
    QString fileName = "tweetian_" + QDateTime::currentDateTime().toString("d-M-yy_h-m-s") + ".png";
    QString filePath = IMAGE_SAVING_PATH + "/" + fileName;

    QImage img(imageObject->boundingRect().size().toSize(), QImage::Format_ARGB32);
    img.fill(QColor(0,0,0,0).rgba());
    QPainter painter(&img);
    //TODO: Find a way to paint the image
    //imageObject->paint(&painter, &styleOption, 0);
    Q_ASSERT(false);
    bool saved = img.save(filePath, "PNG");

    if (!saved) {
        qWarning("QMLUtils::saveImage: Failed to save image to %s", qPrintable(filePath));
        return "";
    }

    return filePath;
}

QObject *QMLUtils::networkAccessManager() const
{
    QNetworkAccessManager *manager = m_view->engine()->networkAccessManager();
    // Not sure if this is necessary...
    QQmlEngine::setObjectOwnership(manager, QQmlEngine::CppOwnership);
    return manager;
}

QString QMLUtils::userAgent()
{
    return USER_AGENT;
}
