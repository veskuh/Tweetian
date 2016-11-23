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

#ifndef NOTIFICATIONUTILS_H
#define NOTIFICATIONUTILS_H

#include <QtCore/QObject>

class QTimer;

class NotificationUtils : public QObject
{
    Q_OBJECT
public:
    explicit NotificationUtils(QObject *parent = 0);

    // Create a system notification based on eventType
    Q_INVOKABLE void publishNotification(const QString &eventType, const QString &summary, const QString &body,
                                         const int count);
    // Clear system notifications based on eventType
    Q_INVOKABLE void clearNotification(const QString &eventType);

signals:
    void newNotification();

private:
    Q_DISABLE_COPY(NotificationUtils)

    QTimer *mentionColddown;
    QTimer *messageColddown;
};

#endif // NotificationUtils_H
