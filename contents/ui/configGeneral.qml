/*
 * SPDX-FileCopyrightText: 2025 molang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    property alias cfg_titleText: titleText.text
    property alias cfg_targetMonth: targetMonth.value
    property alias cfg_targetDay: targetDay.value
    property alias cfg_targetHour: targetHour.value
    property alias cfg_targetMinute: targetMinute.value
    property alias cfg_showSeconds: showSeconds.checked

    Kirigami.FormLayout {
        Controls.TextField {
            id: titleText

            Kirigami.FormData.label: i18n("标题：")
            placeholderText: i18n("高考倒计时")
        }

        Controls.SpinBox {
            id: targetMonth

            Kirigami.FormData.label: i18n("月份：")
            from: 1
            to: 12
            editable: true
        }

        Controls.SpinBox {
            id: targetDay

            Kirigami.FormData.label: i18n("日期：")
            from: 1
            to: 31
            editable: true
        }

        Controls.SpinBox {
            id: targetHour

            Kirigami.FormData.label: i18n("小时：")
            from: 0
            to: 23
            editable: true
        }

        Controls.SpinBox {
            id: targetMinute

            Kirigami.FormData.label: i18n("分钟：")
            from: 0
            to: 59
            editable: true
        }

        Controls.CheckBox {
            id: showSeconds

            text: i18n("显示秒数")
        }
    }
}
