/*
 * SPDX-FileCopyrightText: 2025 molang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Controls as Controls
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: page

    property string cfg_titleText
    property alias cfg_repeatAnnually: repeatAnnually.checked
    property int cfg_targetYear
    property alias cfg_targetMonth: targetMonth.value
    property int cfg_targetDay
    property alias cfg_targetHour: targetHour.value
    property alias cfg_targetMinute: targetMinute.value
    property alias cfg_showSeconds: showSeconds.checked

    // February 29 is a valid annual choice even when this particular year is not a leap year.
    readonly property int calendarYear: cfg_repeatAnnually ? 2000 : cfg_targetYear || new Date().getFullYear()
    readonly property int monthLength: new Date(calendarYear, cfg_targetMonth, 0).getDate()

    function fitDayToMonth() {
        cfg_targetDay = Math.min(cfg_targetDay, monthLength);
    }

    Kirigami.FormLayout {
        Controls.TextField {
            id: titleField

            Kirigami.FormData.label: i18n("Title:")
            placeholderText: i18n("Gaokao Countdown")
            onTextEdited: page.cfg_titleText = text

            // Show the localized placeholder for the old default without interfering with typing.
            Binding {
                target: titleField
                property: "text"
                when: !titleField.activeFocus
                value: page.cfg_titleText === "高考倒计时" ? "" : page.cfg_titleText
                restoreMode: Binding.RestoreNone
            }
        }

        Controls.CheckBox {
            id: repeatAnnually

            text: i18n("Repeat every year")
            onToggled: {
                if (!checked && page.cfg_targetYear === 0) {
                    page.cfg_targetYear = new Date().getFullYear();
                }
                page.fitDayToMonth();
            }
        }

        Controls.SpinBox {
            Kirigami.FormData.label: i18n("Year:")
            visible: !repeatAnnually.checked
            from: 1000
            to: 9999
            value: page.cfg_targetYear || new Date().getFullYear()
            editable: true
            textFromValue: value => String(value)
            valueFromText: text => Number(text)
            onValueModified: {
                page.cfg_targetYear = value;
                page.fitDayToMonth();
            }
        }

        Controls.SpinBox {
            id: targetMonth

            Kirigami.FormData.label: i18n("Month:")
            from: 1
            to: 12
            editable: true
            onValueModified: page.fitDayToMonth()
        }

        Controls.SpinBox {
            Kirigami.FormData.label: i18n("Day:")
            from: 1
            to: page.monthLength
            value: page.cfg_targetDay
            editable: true
            onValueModified: page.cfg_targetDay = value
        }

        Controls.SpinBox {
            id: targetHour

            Kirigami.FormData.label: i18n("Hour:")
            from: 0
            to: 23
            editable: true
        }

        Controls.SpinBox {
            id: targetMinute

            Kirigami.FormData.label: i18n("Minute:")
            from: 0
            to: 59
            editable: true
        }

        Controls.CheckBox {
            id: showSeconds

            text: i18n("Show seconds in details")
        }
    }
}
