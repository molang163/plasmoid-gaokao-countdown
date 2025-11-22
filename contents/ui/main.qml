/*
 * Copyright (C)  2025 molang
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 */

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root
    preferredRepresentation: fullRepresentation

    fullRepresentation: Rectangle {
        id: mainRect
        Layout.minimumWidth: 320
        Layout.minimumHeight: 120
        width: 320
        height: 120

        color: PlasmaCore.Theme.backgroundColor
        radius: 12
        border.color: PlasmaCore.Theme.highlightColor
        border.width: 1

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: "高考倒计时"
                font.pixelSize: 20
                color: PlasmaCore.Theme.textColor
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                id: countdownText
                text: "..."
                font.pixelSize: 28
                font.bold: true
                color: PlasmaCore.Theme.textColor
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                id: noteText
                text: ""
                font.pixelSize: 12
                color: PlasmaCore.Theme.disabledTextColor
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                var now = new Date()
                var year = now.getFullYear()
                var t = new Date(year, 5, 7, 0, 0, 0)

                if (now > t) {
                    t = new Date(year + 1, 5, 7, 0, 0, 0)
                }

                var diff = t.getTime() - now.getTime()
                if (diff < 0) diff = 0

                    var days = Math.floor(diff / (1000 * 60 * 60 * 24))
                    var hours = Math.floor((diff / (1000 * 60 * 60)) % 24)
                    var minutes = Math.floor((diff / (1000 * 60)) % 60)
                    var seconds = Math.floor((diff / 1000) % 60)

                    countdownText.text = days + "天 " + hours + "时 " + minutes + "分 " + seconds + "秒"
                    noteText.text = "距离高考还剩 " + days + " 天"
            }
        }
    }
}
