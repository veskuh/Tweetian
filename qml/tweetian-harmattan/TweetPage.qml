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

import QtQuick 2.1
import Sailfish.Silica 1.0
import "Services/Twitter.js" as Twitter
import "Component"
import "Delegate"
import "Services/Translation.js" as Translation
import "Services/Flickr.js" as Flickr
import "Services/Pocket.js" as Pocket
import "Services/Instapaper.js" as Instapaper
import "Services/TwitLonger.js" as TwitLonger
import "Services/NokiaMaps.js" as Maps
import "Services/Youtube.js" as YouTube
import "TweetPageJS.js" as JS

Page {
    id: tweetPage

    objectName: "tweetPage"
    property variant tweet

    property bool favouritedTweet: tweet && tweet.isFavourited

    property ListModel ancestorModel: ListModel {}
    property ListModel descendantModel: ListModel {}

    Component.onCompleted: {
        //TODO: Use plain QML instead of JS to show RT and Fav count
        JS.createPicThumb()
        JS.createMapThumb()
        if (networkMonitor.online) {
            JS.createYoutubeThumb()
            JS.expandTwitLonger()

        }
        JS.getConversationFromTimelineAndMentions()
    }

    RemorsePopup {id: remorse}

    SilicaFlickable {
        id: tweetPageFlickable

        onContentHeightChanged: {
            if (ancestorRepeater.count > 0) {
                tweetPageFlickable.contentY = tweetPageFlickable.contentHeight - tweetPageFlickable.height
            }
        }

        PageHeader {
            id: header
            title: qsTr("Tweet")
            property bool busy: false
        }

        PullDownMenu {

            id: tweetMenu 

            MenuItem {
                text: qsTr("Copy tweet")
                onClicked: {
                    QMLUtils.copyToClipboard("@" + tweet.screenName + ": " + tweet.plainText)
                    infoBanner.showText(qsTr("Tweet copied to clipboard"))
                }
            }

           /* MenuItem {
                text: qsTr("Tweet permalink")
                onClicked: {
                    var permalink = "http://twitter.com/" + tweet.screenName + "/status/" + tweet.id
                    dialog.createOpenLinkDialog(permalink)
                }
                //platformStyle: MenuItemStyle { position: deleteTweetButton.visible ? "vertical-center" : "vertical-bottom" }
            }*/

            /*
            MenuItem {
                text: translatedTweetLoader.sourceComponent ? qsTr("Hide translated tweet") : qsTr("Translate tweet")
                onClicked: {
                    if (translatedTweetLoader.sourceComponent) translatedTweetLoader.sourceComponent = undefined
                    else if (cache.isTranslationTokenValid()) {
                        Translation.translate(constant, cache.translationToken, tweet.plainText,
                                              settings.translateLangCode, JS.translateOnSuccess, JS.commonOnFailure)
                        header.busy = true
                    }
                    else {
                        Translation.requestToken(constant, JS.translateTokenOnSuccess, JS.commonOnFailure)
                        header.busy = true
                    }
                }
            }*/

            MenuItem {
                id: deleteTweetButton
                text: qsTr("Delete tweet")
                visible: tweet.retweetScreenName === settings.userScreenName
                onClicked: remorse.execute(qsTr("Delete tweet"), function() {  Twitter.postDeleteStatus(tweet.id, tweetPageHelper.deleteTweetOnSuccess, tweetPageHelper.commonOnFailure) })
            }



            MenuItem {
                text: qsTr("Favourite")
                onClicked: {
                    Twitter.postFavourite(tweet.id, JS.favouriteOnSuccess, JS.commonOnFailure)
                    header.busy = true
                }
                visible: !favouritedTweet
            }

            MenuItem {
                text: qsTr("Remove favourite")
                onClicked: {
                    Twitter.postUnfavourite(tweet.id, JS.favouriteOnSuccess, JS.commonOnFailure)
                    header.busy = true
                }
                visible: favouritedTweet
            }

            MenuItem {
                text: qsTr("Retweet")
                onClicked: {
                    var prop = { type: "RT", placedText: JS.constructRetweetText(tweet), tweetId: tweet.id }
                    pageStack.push(Qt.resolvedUrl("NewTweetPage.qml"), prop)
                }
            }

            MenuItem {
                text: qsTr("Reply")
                onClicked: {
                    var prop = { type: "Reply", placedText: JS.constructReplyText(tweet), tweetId: tweet.id }
                    pageStack.push(Qt.resolvedUrl("NewTweetPage.qml"), prop)
                }
            }

        }


        anchors.fill: parent
        contentHeight: mainColumn.height + header.height


        Column {
            id: mainColumn
            anchors { top: header.bottom; left: parent.left; right: parent.right }
            height: childrenRect.height
            Column {
                id: ancestorColumn
                anchors { left: parent.left; right: parent.right }
                height: childrenRect.height

                Repeater { id: ancestorRepeater; TweetDelegate { width: ancestorColumn.width } }
            }

            Loader { sourceComponent: ancestorRepeater.count > 0 ? inReplyToHeading : undefined }

            Column {
                id: mainTweetColumn
                anchors { left: parent.left; right: parent.right }
                height: childrenRect.height + constant.paddingLarge
                spacing: constant.paddingSmall

                ListItem {
                    id: userItem
                    anchors { left: parent.left; right: parent.right }
                    height: usernameColumn.height + constant.paddingMedium
                    subItemIndicator: true
                    onClicked: pageStack.push(Qt.resolvedUrl("UserPage.qml"), {screenName: tweet.screenName})
                    Component.onCompleted: {
                        imageSource = thumbnailCacher.get(tweet.profileImageUrl)
                                || (networkMonitor.online ? tweet.profileImageUrl : constant.twitterBirdIcon)
                    }

                    Column {
                        id: usernameColumn
                        anchors { top: parent.top; left: userItem.imageItem.right; leftMargin: constant.paddingMedium; right: parent.right }
                        height: childrenRect.height

                        Item {
                            anchors { left: parent.left; right: parent.right }
                            height: childrenRect.height

                            Text {
                                id: userNameText
                                anchors.left: parent.left
                                font.pixelSize: constant.fontSizeMedium
                                font.family: Theme.fontFamily
                                color: constant.colorLight
                                font.bold: true
                                text: tweet.name
                            }

                            Image {
                                id: favouriteIcon
                                anchors { right: parent.right; rightMargin: constant.paddingMedium; verticalCenter: userNameText.verticalCenter }
                                height: constant.graphicSizeSmall
                                width: height
                                source: "image://theme/icon-s-favorite"
                                visible: favouritedTweet
                            }
                        }

                        Text {
                            font.pixelSize: constant.fontSizeMedium
                            font.family: Theme.fontFamily
                            color: userItem.highlighted ? constant.colorHighlighted : constant.colorMid
                            text: "@" + tweet.screenName
                        }
                    }
                }

                Text {
                    id: tweetText
                    anchors { left: parent.left; right: parent.right; leftMargin: constant.paddingMedium; rightMargin: constant.paddingMedium  }
                    font.pixelSize: constant.fontSizeMedium
                    font.family: Theme.fontFamily
                    color: constant.colorLight
                    textFormat: Text.RichText
                    wrapMode: Text.Wrap
                    text: tweet.richText
                    onLinkActivated: {
                        basicHapticEffect.play()
                        if (link.indexOf("@") === 0)
                            pageStack.push(Qt.resolvedUrl("UserPage.qml"), {screenName: link.substring(1)})
                        else if (link.indexOf("http") === 0)
                            dialog.createOpenLinkDialog(link, JS.addToPocket, JS.addToInstapaper)
                        else
                            pageStack.push(Qt.resolvedUrl("SearchPageCom/TweetSearchPage.qml"), {searchString: link})
                    }
                }

                Item {
                    anchors { left: parent.left; right: parent.right; leftMargin: constant.paddingMedium; rightMargin: constant.paddingMedium  }
                    height: timeAndSourceText.height

                    Text {
                        id: timeAndSourceText
                        anchors { left: parent.left; right: parent.right; }
                        font.pixelSize: constant.fontSizeSmall
                        font.family: Theme.fontFamily
                        color: constant.colorMid
                        text: Qt.formatDateTime(tweet.createdAt, Qt.DefaultLocaleShortDate) + " | " + tweet.source
                        elide: Text.ElideRight
                    }
                }

                Row {
                    anchors { left: parent.left; margins: constant.paddingMedium }
                    spacing: constant.paddingSmall
                    Label {
                        text: tweet.retweet_count + " Retweeted"
                        visible: tweet.retweet_count? tweet.retweet_count > 0 : false
                        font.pixelSize: constant.fontSizeSmall
                        font.family: Theme.fontFamily
                        color: constant.colorMid
                    }
                    Label {
                        text: tweet.favorite_count + " Favorited"
                        visible: tweet.favorite_count? tweet.favorite_count > 0 : false
                        font.pixelSize: constant.fontSizeSmall
                        font.family: Theme.fontFamily
                        color: constant.colorMid
                    }
                }

                ListItem {
                    id: retweetItem
                    anchors { left: parent.left; right: parent.right }
                    height: retweetText.height + constant.paddingMedium
                    visible: tweet.isRetweet
                    subItemIndicator: true
                    onClicked: pageStack.push(Qt.resolvedUrl("UserPage.qml"), {screenName: tweet.retweetScreenName})

                    Image {
                        id: retweetIcon
                        anchors { left: parent.left; leftMargin: constant.paddingMedium; verticalCenter: retweetText.verticalCenter }
                        height: constant.graphicSizeSmall
                        width: height
                        source: "image://theme/icon-s-retweet"

                    }

                    Text {
                        id: retweetText
                        anchors { left: retweetIcon.right; right: parent.right; leftMargin: constant.paddingSmall; rightMargin: constant.paddingMedium }
                        font.pixelSize: constant.fontSizeMedium
                        font.family: Theme.fontFamily
                        color: constant.colorMid
                        text: "@" + tweet.retweetScreenName
                    }
                }

                Flow {
                    anchors { left: parent.left; leftMargin: constant.paddingMedium; right: parent.right }
                    spacing: constant.paddingMedium

                    Repeater {
                        model: ListModel { id: thumbnailModel }

                        ThumbnailItem {
                            imageSource: model.thumb
                            iconSource: {
                                switch (model.type) {
                                case "image":
                                    return settings.invertedTheme ? "Image/photos_inverse.svg" : "Image/photos.svg"
                                case "map":
                                    return settings.invertedTheme ? "Image/location_mark_inverse.svg" : "Image/location_mark.svg"
                                case "video":
                                    return settings.invertedTheme ? "Image/video_inverse.svg" : "Image/video.svg"
                                default:
                                    console.log("Invalid type: " + model.type); return ""
                                }
                            }
                            onClicked: {
                                if (model.type === "image")
                                    pageStack.push(Qt.resolvedUrl("TweetImage.qml"), {"imageLink": model.link,"imageUrl": model.full})
                                else if (model.type === "map")
                                    pageStack.push(Qt.resolvedUrl("MapPage.qml"), {latitude: tweet.latitude, longitude: tweet.longitude})
                                else {
                                    if (model.link) {
                                        var success = Qt.openUrlExternally(model.link)
                                        if (!success) infoBanner.showText(qsTr("Error opening link: %1").arg(model.link))
                                    }
                                    else infoBanner.showText(qsTr("Streaming link is not available"))
                                }
                            }
                        }
                    }
                }
            }

            Loader { id: translatedTweetLoader; height: sourceComponent ? undefined : 0 }

            Loader { sourceComponent: descendantRepeater.count > 0 ? replyHeading : undefined }

            Column {
                id: descendantColumn
                anchors { left: parent.left; right: parent.right }
                height: childrenRect.height

                Repeater { id: descendantRepeater; TweetDelegate { width: descendantColumn.width } }
            }
        }
    }

    VerticalScrollDecorator { flickable: tweetPageFlickable }

    WorkerScript {
        id: conversationParser
        source: "WorkerScript/ConversationParser.js"
        onMessage: {
            // header.busy = false
            ancestorRepeater.model = ancestorModel
            descendantRepeater.model = descendantModel
        }
    }

    Component {
        id: inReplyToHeading

        SectionHeader { width: mainColumn.width; text: qsTr("In-reply-to") }
    }

    Component {
        id: replyHeading

        SectionHeader { width: mainColumn.width; text: qsTr("Reply") }
    }

    Component {
        id: translatedTweetComponent

        Column {
            property string translatedText

            width: mainColumn.width
            height: childrenRect.height + constant.paddingMedium
            spacing: constant.paddingMedium

            SectionHeader { text: qsTr("Translated Tweet") }

            Text {
                anchors { left: parent.left; right: parent.right; margins: constant.paddingMedium }
                font.pixelSize: constant.fontSizeLarge
                color: constant.colorLight
                text: translatedText
                wrapMode: Text.Wrap
            }
        }
    }
}
