/*
 * SPDX-FileCopyrightText: 2025 molang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    property bool showingDetails: false

    Countdown {
        id: countdown
        configuration: Plasmoid.configuration
    }

    Plasmoid.icon: "view-calendar-day"
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    toolTipMainText: countdown.titleText
    toolTipSubText: countdown.targetDateText

    switchWidth: Kirigami.Units.gridUnit * 12
    switchHeight: Kirigami.Units.gridUnit * 7
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation

    onExpandedChanged: if (expanded) countdown.now = new Date()

    // Wake at the next wall-clock minute (or second when showing the exact time).
    Timer {
        readonly property bool detailsVisible: root.showingDetails && (Plasmoid.formFactor === PlasmaCore.Types.Planar || root.expanded)
        readonly property int tick: detailsVisible && countdown.showSeconds ? 1000 : 60000
        interval: tick - (countdown.now.getTime() % tick)
        running: true
        repeat: true
        onTriggered: countdown.now = new Date()
    }

    compactRepresentation: PlasmaComponents.ToolButton {
        id: compact

        readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        Layout.minimumWidth: vertical ? Kirigami.Units.gridUnit : implicitWidth
        Layout.preferredWidth: implicitWidth
        Layout.minimumHeight: Kirigami.Units.gridUnit
        text: vertical && countdown.calendarDaysLeft > 1 ? String(countdown.calendarDaysLeft) : countdown.compactCountdownText
        icon.name: "view-calendar-day"
        display: !vertical ? PlasmaComponents.ToolButton.TextBesideIcon
            : compactTextMetrics.advanceWidth <= width - leftPadding - rightPadding
                ? PlasmaComponents.ToolButton.TextOnly : PlasmaComponents.ToolButton.IconOnly
        TextMetrics {
            id: compactTextMetrics
            text: compact.text
            font: compact.font
        }
        Accessible.name: countdown.titleText + ", " + countdown.compactCountdownText
        onClicked: root.expanded = !root.expanded
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 16
        Layout.minimumHeight: Kirigami.Units.gridUnit * 9
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: Kirigami.Units.gridUnit * 10

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    // Close to the exam, the primary line already names the Gaokao.
                    text: !root.showingDetails && countdown.builtinTitle && !countdown.expired && countdown.calendarDaysLeft <= 1
                        ? countdown.targetDateText : countdown.titleText
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.weight: Font.DemiBold
                }

                PlasmaComponents.ToolButton {
                    text: root.showingDetails ? i18n("Overview") : i18n("Details")
                    display: PlasmaComponents.ToolButton.TextOnly
                    onClicked: {
                        root.showingDetails = !root.showingDetails;
                        countdown.now = new Date();
                    }
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            Item {
                Layout.fillHeight: true
                Layout.preferredHeight: 0
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                text: root.showingDetails ? countdown.countdownText : countdown.mainText
                textFormat: Text.PlainText
                color: root.showingDetails || countdown.expired ? Kirigami.Theme.textColor : Kirigami.Theme.linkColor
                font.bold: true
                font.pixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * (root.showingDetails ? 2.2 : 3.3))
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: Math.round(Kirigami.Theme.defaultFont.pixelSize * 1.2)
                maximumLineCount: 1
                elide: Text.ElideRight
            }

            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.showingDetails ? countdown.targetDateText : countdown.subtitleText
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Item {
                Layout.fillHeight: true
                Layout.preferredHeight: 0
            }

            RowLayout {
                visible: root.showingDetails && countdown.repeatAnnually
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: i18n("Annual progress")
                    font: Kirigami.Theme.smallFont
                }

                PlasmaComponents.ProgressBar {
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: countdown.progressValue
                }

                PlasmaComponents.Label {
                    text: i18n("%1%", Math.round(countdown.progressValue * 100))
                    font: Kirigami.Theme.smallFont
                }
            }
        }
    }
}
