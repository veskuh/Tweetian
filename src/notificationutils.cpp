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

#include "notificationutils.h"

#include <QtCore/QTimer>
#include <QDebug>

#include <MNotification>
#include <MRemoteAction>
#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusInterface>
#include <QtDBus/QDBusConnectionInterface>
#include <QtDBus/QDBusReply>

namespace {
    const int NOTIFICATION_COLDDOWN_INVERVAL = 5000;
}

NotificationUtils::NotificationUtils(QObject *parent) :
    QObject(parent), mentionColddown(new QTimer(this)), messageColddown(new QTimer(this))
{
    mentionColddown->setInterval(NOTIFICATION_COLDDOWN_INVERVAL);
    mentionColddown->setSingleShot(true);
    messageColddown->setInterval(NOTIFICATION_COLDDOWN_INVERVAL);
    messageColddown->setSingleShot(true);
}

void NotificationUtils::publishNotification(const QString &eventType, const QString &summary, const QString &body,
                                         const int count)
{
    if (count == 0) {
        qWarning() << "Empty notification: " << body;
        return;
    }
    emit newNotification();

    if (eventType == "tweetian.mention" ? mentionColddown->isActive() : messageColddown->isActive())
        return;

    QString identifier = eventType.mid(9);

    MNotification notification(eventType, summary, body);
    notification.setCount(count);
    notification.setIdentifier(identifier);
    MRemoteAction action("com.tweetian", "/com/tweetian", "com.tweetian", identifier);
    notification.setAction(action);
    notification.publish();

    if (eventType == "tweetian.mention") mentionColddown->start();
    else messageColddown->start();
}

void NotificationUtils::clearNotification(const QString &eventType)
{
    QList<MNotification*> activeNotifications = MNotification::notifications();
    QMutableListIterator<MNotification*> i(activeNotifications);
    while (i.hasNext()) {
        MNotification *notification = i.next();
        if (notification->eventType() == eventType)
            notification->remove();
    }
}
