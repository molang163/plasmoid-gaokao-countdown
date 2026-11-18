/*
 * SPDX-FileCopyrightText: 2025 molang
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQml

QtObject {
    id: model

    required property var configuration
    property date now: new Date()

    readonly property string configuredTitle: String(configuration.titleText || "").trim()
    // The pre-translation schema stored the Chinese default as a literal title.
    readonly property bool builtinTitle: configuredTitle === "" || configuredTitle === "高考倒计时"
    readonly property string titleText: builtinTitle ? i18n("Gaokao Countdown") : configuredTitle
    readonly property bool repeatAnnually: configuration.repeatAnnually !== false
    readonly property bool showSeconds: configuration.showSeconds !== false

    readonly property int msecPerDay: 86400000
    readonly property date targetDate: nextTargetDate(now)
    readonly property int dayDifference: calendarDayNumber(targetDate) - calendarDayNumber(now)
    readonly property int calendarDaysLeft: Math.max(0, dayDifference)
    readonly property bool expired: dayDifference < 0
    readonly property real remainingMs: Math.max(0, targetDate.getTime() - now.getTime())
    readonly property string targetDateText: Qt.formatDateTime(targetDate, Qt.locale(), Locale.ShortFormat)
    readonly property string compactCountdownText: compactText()
    readonly property string mainText: primaryText()
    readonly property string subtitleText: subtitle()
    readonly property string countdownText: preciseCountdown()
    readonly property real progressValue: annualProgress()

    function boundedInt(value, fallback, minimum, maximum) {
        const number = Number(value);
        return isFinite(number) ? Math.min(maximum, Math.max(minimum, Math.round(number))) : fallback;
    }

    function targetForYear(year) {
        const month = boundedInt(configuration.targetMonth, 6, 1, 12);
        const lastDay = new Date(year, month, 0).getDate();
        const day = boundedInt(configuration.targetDay, 7, 1, lastDay);
        const hour = boundedInt(configuration.targetHour, 9, 0, 23);
        const minute = boundedInt(configuration.targetMinute, 0, 0, 59);
        return new Date(year, month - 1, day, hour, minute);
    }

    function calendarDayNumber(date) {
        // Count local calendar dates even across daylight-saving transitions.
        return Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()) / msecPerDay;
    }

    function nextTargetDate(reference) {
        const year = reference.getFullYear();
        if (!repeatAnnually) {
            return targetForYear(configuration.targetYear || year);
        }
        const candidate = targetForYear(year);
        return calendarDayNumber(reference) > calendarDayNumber(candidate)
            ? targetForYear(year + 1) : candidate;
    }

    function compactText() {
        if (expired) {
            return i18n("Date passed");
        }
        if (calendarDaysLeft === 0) {
            return i18n("Today");
        }
        if (calendarDaysLeft === 1) {
            return i18n("Tomorrow");
        }
        return i18np("%1 day", "%1 days", calendarDaysLeft);
    }

    function primaryText() {
        if (expired) {
            return compactCountdownText;
        }
        if (calendarDaysLeft === 0) {
            return builtinTitle ? i18n("Gaokao today") : compactCountdownText;
        }
        if (calendarDaysLeft === 1) {
            return builtinTitle ? i18n("Gaokao tomorrow") : compactCountdownText;
        }
        return i18np("%1 day to go", "%1 days to go", calendarDaysLeft);
    }

    function subtitle() {
        if (expired || calendarDaysLeft > 1) {
            return targetDateText;
        }
        if (remainingMs === 0) {
            return builtinTitle ? i18n("Good luck on your exam!") : targetDateText;
        }
        const totalMinutes = Math.ceil(remainingMs / 60000);
        const hours = Math.floor(totalMinutes / 60);
        const minutes = totalMinutes % 60;
        if (!hours) {
            return i18np("%1 minute to go", "%1 minutes to go", minutes);
        }
        if (!minutes) {
            return i18np("%1 hour to go", "%1 hours to go", hours);
        }
        return i18n("%1 h %2 min to go", hours, minutes);
    }

    function preciseCountdown() {
        if (remainingMs === 0) {
            return compactCountdownText;
        }
        const seconds = Math.floor(remainingMs / 1000);
        const minutes = Math.floor(seconds / 60);
        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);
        return showSeconds
            ? i18n("%1 d %2 h %3 min %4 s", days, hours % 24, minutes % 60, seconds % 60)
            : i18n("%1 d %2 h %3 min", days, hours % 24, minutes % 60);
    }

    function annualProgress() {
        if (!repeatAnnually) {
            return 0;
        }
        const previous = targetForYear(targetDate.getFullYear() - 1).getTime();
        const elapsed = now.getTime() - previous;
        return Math.min(1, Math.max(0, elapsed / (targetDate.getTime() - previous)));
    }
}
