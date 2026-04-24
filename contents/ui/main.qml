/*
 * SPDX-FileCopyrightText: 2025 molang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    readonly property int msecPerDay: 24 * 60 * 60 * 1000
    readonly property string fallbackTitle: i18n("高考倒计时")
    readonly property string titleText: normalizedTitle()
    readonly property int targetMonth: boundedInt(plasmoid.configuration.targetMonth, 6, 1, 12)
    readonly property int targetDay: boundedInt(plasmoid.configuration.targetDay, 7, 1, 31)
    readonly property int targetHour: boundedInt(plasmoid.configuration.targetHour, 9, 0, 23)
    readonly property int targetMinute: boundedInt(plasmoid.configuration.targetMinute, 0, 0, 59)
    readonly property bool showSeconds: plasmoid.configuration.showSeconds !== false

    property date now: new Date()

    readonly property date targetDate: nextTargetDate(now)
    readonly property int calendarDaysLeft: Math.max(0, Math.round((startOfDay(targetDate) - startOfDay(now)) / msecPerDay))
    readonly property real remainingMs: Math.max(0, targetDate.getTime() - now.getTime())
    readonly property int daysRemaining: Math.floor(remainingMs / msecPerDay)
    readonly property int hoursRemaining: Math.floor((remainingMs / (60 * 60 * 1000)) % 24)
    readonly property int minutesRemaining: Math.floor((remainingMs / (60 * 1000)) % 60)
    readonly property int secondsRemaining: Math.floor((remainingMs / 1000) % 60)
    readonly property date previousTargetDate: previousTarget(targetDate)
    readonly property real cycleMs: Math.max(1, targetDate.getTime() - previousTargetDate.getTime())
    readonly property real progressValue: Math.max(0, Math.min(1, (now.getTime() - previousTargetDate.getTime()) / cycleMs))
    readonly property int progressPercent: Math.round(progressValue * 100)
    readonly property color accentColor: urgencyColor()
    readonly property string targetDateText: Qt.formatDateTime(targetDate, "yyyy年M月d日 HH:mm")
    readonly property string headlineText: headline()
    readonly property string countdownText: countdown()
    readonly property string compactCountdownText: compactCountdown()
    readonly property string noteText: note()

    Plasmoid.icon: "appointment-soon"
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    toolTipMainText: root.titleText
    toolTipSubText: i18n("目标时间：%1", root.targetDateText)

    switchWidth: Kirigami.Units.gridUnit * 12
    switchHeight: Kirigami.Units.gridUnit * 7
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation

    function normalizedTitle() {
        const configured = String(plasmoid.configuration.titleText || "").trim();
        return configured.length > 0 ? configured : root.fallbackTitle;
    }

    function boundedInt(value, fallback, minimum, maximum) {
        const parsed = Number(value);
        if (!isFinite(parsed)) {
            return fallback;
        }
        return Math.min(maximum, Math.max(minimum, Math.round(parsed)));
    }

    function daysInMonth(year, month) {
        return new Date(year, month, 0).getDate();
    }

    function targetForYear(year) {
        const day = Math.min(root.targetDay, daysInMonth(year, root.targetMonth));
        return new Date(year, root.targetMonth - 1, day, root.targetHour, root.targetMinute, 0, 0);
    }

    function previousTarget(nextTarget) {
        return targetForYear(nextTarget.getFullYear() - 1);
    }

    function startOfDay(date) {
        return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime();
    }

    function nextTargetDate(reference) {
        const currentYearTarget = targetForYear(reference.getFullYear());
        if (startOfDay(reference) > startOfDay(currentYearTarget)) {
            return targetForYear(reference.getFullYear() + 1);
        }
        return currentYearTarget;
    }

    function headline() {
        if (root.calendarDaysLeft === 0) {
            return i18n("今天高考");
        }
        if (root.calendarDaysLeft === 1) {
            return i18n("明天高考");
        }
        return root.titleText;
    }

    function countdown() {
        if (root.calendarDaysLeft === 0 && root.remainingMs <= 0) {
            return i18n("今天");
        }
        if (root.showSeconds) {
            return i18n("%1天 %2时 %3分 %4秒", root.daysRemaining, root.hoursRemaining, root.minutesRemaining, root.secondsRemaining);
        }
        return i18n("%1天 %2时 %3分", root.daysRemaining, root.hoursRemaining, root.minutesRemaining);
    }

    function compactCountdown() {
        if (root.calendarDaysLeft === 0) {
            return i18n("今天");
        }
        if (root.calendarDaysLeft === 1) {
            return i18n("明天");
        }
        return i18n("%1天", root.calendarDaysLeft);
    }

    function note() {
        if (root.calendarDaysLeft === 0) {
            return i18n("目标时间：%1", root.targetDateText);
        }
        return i18n("距离目标日期还剩 %1 天", root.calendarDaysLeft);
    }

    function urgencyColor() {
        if (root.calendarDaysLeft <= 7) {
            return Kirigami.Theme.negativeTextColor;
        }
        return Kirigami.Theme.highlightColor;
    }

    function refreshNow() {
        root.now = new Date();
    }

    Timer {
        interval: root.showSeconds ? 1000 : 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshNow()
    }

    compactRepresentation: MouseArea {
        id: compactRoot

        Layout.minimumWidth: Math.max(Kirigami.Units.gridUnit * 4, compactRow.implicitWidth + Kirigami.Units.smallSpacing * 2)
        Layout.preferredWidth: Layout.minimumWidth
        Layout.minimumHeight: Kirigami.Units.gridUnit * 2
        Layout.preferredHeight: Layout.minimumHeight

        hoverEnabled: true
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "appointment-soon"
                implicitWidth: Kirigami.Units.iconSizes.small
                implicitHeight: Kirigami.Units.iconSizes.small
                color: root.accentColor
            }

            PlasmaComponents.Label {
                id: compactLabel

                text: root.compactCountdownText
                color: root.calendarDaysLeft <= 7 ? root.accentColor : Kirigami.Theme.textColor
                elide: Text.ElideRight
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                maximumLineCount: 1
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    fullRepresentation: Item {
        id: fullRoot

        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.minimumHeight: Kirigami.Units.gridUnit * 9
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: Kirigami.Units.gridUnit * 11

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing * 1.5

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "appointment-soon"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                    color: root.accentColor
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PlasmaComponents.Label {
                        text: root.headlineText
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.bold: true
                        maximumLineCount: 1
                    }

                    PlasmaComponents.Label {
                        text: root.targetDateText
                        Layout.fillWidth: true
                        color: Kirigami.Theme.disabledTextColor
                        elide: Text.ElideRight
                        font: Kirigami.Theme.smallFont
                        maximumLineCount: 1
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.Label {
                        text: root.calendarDaysLeft
                        color: root.accentColor
                        font.bold: true
                        font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 5.2)
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    ColumnLayout {
                        spacing: 0

                        PlasmaComponents.Label {
                            text: i18n("天")
                            color: root.accentColor
                            font.bold: true
                            font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.8)
                        }

                        PlasmaComponents.Label {
                            text: root.countdownText
                            color: Kirigami.Theme.textColor
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }
                }
            }

            PlasmaComponents.ProgressBar {
                Layout.fillWidth: true
                from: 0
                to: 1
                value: root.progressValue
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: root.noteText
                    Layout.fillWidth: true
                    color: Kirigami.Theme.disabledTextColor
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                PlasmaComponents.Label {
                    text: i18n("%1%", root.progressPercent)
                    color: Kirigami.Theme.disabledTextColor
                    horizontalAlignment: Text.AlignRight
                    maximumLineCount: 1
                }
            }
        }
    }
}
