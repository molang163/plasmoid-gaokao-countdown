import QtQuick
import QtTest
import org.kde.ki18n

TestCase {
    id: suite
    name: "Countdown"

    readonly property bool chinese: Qt.locale().name === "zh_CN"
    readonly property string defaultTitle: chinese ? "高考倒计时" : "Gaokao Countdown"
    readonly property string today: chinese ? "今天" : "Today"
    readonly property string tomorrow: chinese ? "明天" : "Tomorrow"
    readonly property string examToday: chinese ? "今天高考" : "Gaokao today"
    readonly property string examTomorrow: chinese ? "明天高考" : "Gaokao tomorrow"
    readonly property string datePassed: chinese ? "日期已过" : "Date passed"

    KI18nContext {
        id: translations
        translationDomain: "plasma_applet_com.github.plasmoid-gaokao-countdown"
    }

    Component {
        id: modelComponent
        Countdown {
            configuration: TestConfiguration {}
            // Plasma supplies these context methods to the applet.
            function i18n(...args) { return translations.i18n(...args); }
            function i18np(...args) { return translations.i18np(...args); }
        }
    }

    function makeModel() {
        const model = createTemporaryObject(modelComponent, suite);
        verify(model !== null);
        return model;
    }

    function daysToGo(days) {
        return chinese ? "还有 " + days + " 天" : days + " days to go";
    }

    function compactDays(days) {
        return chinese ? days + " 天" : days + " days";
    }

    function scenarios() {
        return [
            { tag: "ordinary", now: new Date(2026, 5, 4, 12), days: 3, year: 2026 },
            { tag: "tomorrow", now: new Date(2026, 5, 6, 12), days: 1, year: 2026 },
            { tag: "today-before-time", now: new Date(2026, 5, 7, 8), days: 0, year: 2026 },
            { tag: "today-at-time", now: new Date(2026, 5, 7, 9), days: 0, year: 2026, elapsed: true },
            { tag: "today-after-time", now: new Date(2026, 5, 7, 17), days: 0, year: 2026, elapsed: true },
            { tag: "next-year", now: new Date(2026, 5, 8, 12), days: 364, year: 2027 }
        ];
    }

    function test_titles_data() {
        const titles = [
            { tag: "schema-default", text: "", expected: defaultTitle, builtin: true },
            { tag: "v1.1-default", text: "高考倒计时", expected: defaultTitle, builtin: true },
            { tag: "whitespace", text: " \t\n ", expected: defaultTitle, builtin: true },
            { tag: "custom", text: "Final exam", expected: "Final exam", builtin: false },
            { tag: "trimmed", text: "  项目截止\t", expected: "项目截止", builtin: false },
            { tag: "custom-including-gaokao", text: "高考志愿填报", expected: "高考志愿填报", builtin: false }
        ];
        const rows = [];
        for (const title of titles) {
            for (const scenario of scenarios()) {
                rows.push({ tag: title.tag + "-" + scenario.tag, title, scenario });
            }
        }
        return rows;
    }

    function test_titles(data) {
        const model = makeModel();
        model.configuration.titleText = data.title.text;
        model.now = data.scenario.now;

        compare(model.titleText, data.title.expected);
        compare(model.builtinTitle, data.title.builtin);
        compare(model.expired, false);
        compare(model.targetDate.getFullYear(), data.scenario.year);
        compare(model.calendarDaysLeft, data.scenario.days);
        if (data.scenario.days > 1) {
            compare(model.mainText, daysToGo(data.scenario.days));
            compare(model.compactCountdownText, compactDays(data.scenario.days));
            compare(model.subtitleText, model.targetDateText);
        } else if (data.scenario.days === 1) {
            compare(model.mainText, data.title.builtin ? examTomorrow : tomorrow);
            compare(model.compactCountdownText, tomorrow);
        } else {
            compare(model.mainText, data.title.builtin ? examToday : today);
            compare(model.compactCountdownText, today);
        }
        if (data.scenario.elapsed) {
            compare(model.remainingMs, 0);
            compare(model.countdownText, today);
            compare(model.progressValue, 1);
        }
    }

    function test_configurationAndClockChanges() {
        const model = makeModel();
        model.configuration.targetMonth = 12;
        model.configuration.targetDay = 31;
        model.now = new Date(2026, 11, 30, 12);
        compare(model.mainText, examTomorrow);
        model.configuration.titleText = "  Thesis defense  ";
        compare(model.titleText, "Thesis defense");
        compare(model.mainText, tomorrow);
        model.now = new Date(2026, 11, 31, 17);
        compare(model.titleText, "Thesis defense");
        compare(model.mainText, today);
        compare(model.subtitleText, model.targetDateText);
        model.configuration.titleText = " \t ";
        compare(model.titleText, defaultTitle);
        compare(model.mainText, examToday);
        model.now = new Date(2027, 0, 1, 12);
        compare(model.targetDate.getFullYear(), 2027);
        compare(model.mainText, daysToGo(364));
        verify(model.progressValue > 0 && model.progressValue < 0.01);
    }

    function test_finalHoursAndDetails() {
        const model = makeModel();
        model.now = new Date(2026, 5, 6, 23);
        compare(model.mainText, examTomorrow);
        compare(model.subtitleText, chinese ? "还有 10 小时" : "10 hours to go");
        model.now = new Date(2026, 5, 7, 8);
        compare(model.mainText, examToday);
        compare(model.subtitleText, chinese ? "还有 1 小时" : "1 hour to go");
        model.now = new Date(2026, 5, 7, 8, 59, 58);
        compare(model.remainingMs, 2000);
        compare(model.subtitleText, chinese ? "还有 1 分钟" : "1 minute to go");
        compare(model.countdownText, chinese ? "0 天 0 时 0 分 2 秒" : "0 d 0 h 0 min 2 s");
        model.configuration.showSeconds = false;
        compare(model.countdownText, chinese ? "0 天 0 时 0 分" : "0 d 0 h 0 min");
        model.now = new Date(2026, 5, 7, 9);
        compare(model.subtitleText, chinese ? "祝你考试顺利！" : "Good luck on your exam!");
    }

    function test_fixedYearDoesNotRoll() {
        const model = makeModel();
        const config = model.configuration;
        config.titleText = "Thesis defense";
        config.repeatAnnually = false;
        config.targetYear = 2026;
        config.targetMonth = 12;
        config.targetDay = 31;
        config.targetHour = 16;
        config.targetMinute = 45;
        model.now = new Date(2025, 11, 31, 16, 45);
        compare(model.targetDate.getTime(), new Date(2026, 11, 31, 16, 45).getTime());
        compare(model.calendarDaysLeft, 365);
        compare(model.targetDateText, Qt.formatDateTime(model.targetDate, Qt.locale(), Locale.ShortFormat));

        model.now = new Date(2026, 11, 31, 16, 45);
        compare(model.expired, false);
        compare(model.remainingMs, 0);
        compare(model.mainText, today);
        for (const after of [new Date(2027, 0, 1, 0), new Date(2028, 11, 30, 12)]) {
            model.now = after;
            compare(model.targetDate.getFullYear(), 2026);
            compare(model.expired, true);
            compare(model.remainingMs, 0);
            compare(model.mainText, datePassed);
            compare(model.compactCountdownText, datePassed);
            compare(model.titleText, "Thesis defense");
        }
        config.repeatAnnually = true;
        compare(model.expired, false);
        compare(model.targetDate.getFullYear(), 2028);
        compare(model.mainText, tomorrow);
    }

    function test_leapDay() {
        const model = makeModel();
        model.configuration.targetMonth = 2;
        model.configuration.targetDay = 29;
        model.now = new Date(2027, 1, 28, 13);
        compare(model.targetDate.getDate(), 28);
        compare(model.mainText, examToday);
        model.now = new Date(2027, 2, 1, 0);
        compare(model.targetDate.getFullYear(), 2028);
        compare(model.targetDate.getMonth(), 1);
        compare(model.targetDate.getDate(), 29);
        compare(model.calendarDaysLeft, 365);
    }
}
