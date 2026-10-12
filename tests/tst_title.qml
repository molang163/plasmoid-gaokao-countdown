import QtQuick
import QtTest

TestCase {
    name: "CountdownTitle"

    Component {
        id: widgetComponent
        CountdownUnderTest {}
    }

    function makeWidget() {
        const widget = createTemporaryObject(widgetComponent, this);
        verify(widget !== null);
        return widget;
    }

    function scenarios() {
        return [
            { tag: "ordinary", now: new Date(2026, 5, 4, 12), days: 3, compact: "3天", year: 2026 },
            { tag: "tomorrow", now: new Date(2026, 5, 6, 12), days: 1, compact: "明天", year: 2026 },
            { tag: "today-before-time", now: new Date(2026, 5, 7, 8), days: 0, compact: "今天", year: 2026 },
            { tag: "today-at-time", now: new Date(2026, 5, 7, 9), days: 0, compact: "今天", year: 2026, elapsed: true },
            { tag: "today-after-time", now: new Date(2026, 5, 7, 17), days: 0, compact: "今天", year: 2026, elapsed: true },
            { tag: "expired-rolls-to-next-year", now: new Date(2026, 5, 8, 12), days: 364, compact: "364天", year: 2027 }
        ];
    }

    function test_headline_data() {
        const titles = [
            { tag: "default", value: "高考倒计时", normalized: "高考倒计时", custom: false },
            { tag: "empty", value: "", normalized: "高考倒计时", custom: false },
            { tag: "whitespace", value: " \t\n ", normalized: "高考倒计时", custom: false },
            { tag: "custom", value: "项目截止", normalized: "项目截止", custom: true },
            { tag: "trimmed-custom", value: "  考研倒计时 \t", normalized: "考研倒计时", custom: true },
            { tag: "custom-including-gaokao", value: "高考志愿填报", normalized: "高考志愿填报", custom: true }
        ];
        const rows = [];
        for (const title of titles) {
            for (const scenario of scenarios()) {
                rows.push({
                    tag: title.tag + "-" + scenario.tag,
                    title: title,
                    scenario: scenario,
                    expected: title.custom ? title.normalized
                        : scenario.days === 0 ? "今天高考"
                        : scenario.days === 1 ? "明天高考" : "高考倒计时"
                });
            }
        }
        return rows;
    }

    function test_headline(data) {
        const widget = makeWidget();
        widget.plasmoid.configuration.titleText = data.title.value;
        widget.now = data.scenario.now;
        compare(widget.titleText, data.title.normalized);
        compare(widget.headlineText, data.expected);
        compare(widget.calendarDaysLeft, data.scenario.days);
        compare(widget.compactCountdownText, data.scenario.compact);
        compare(widget.targetDate.getFullYear(), data.scenario.year);
        if (data.scenario.elapsed) {
            compare(widget.remainingMs, 0);
            compare(widget.countdownText, "今天");
        }
    }

    function test_configurationChanges_data() {
        return scenarios();
    }

    function test_configurationChanges(data) {
        const widget = makeWidget();
        widget.now = data.now;
        const defaultHeadline = widget.headlineText;
        widget.plasmoid.configuration.titleText = "  项目截止  ";
        compare(widget.headlineText, "项目截止");
        widget.plasmoid.configuration.titleText = "考研倒计时";
        compare(widget.headlineText, "考研倒计时");
        widget.plasmoid.configuration.titleText = "高考倒计时";
        compare(widget.headlineText, defaultHeadline);
        widget.plasmoid.configuration.titleText = " \t ";
        compare(widget.headlineText, defaultHeadline);
    }

    function test_dateChanges() {
        const widget = makeWidget();
        for (const title of ["高考倒计时", "项目截止"]) {
            widget.plasmoid.configuration.titleText = title;
            for (const scenario of scenarios()) {
                widget.now = scenario.now;
                const expected = title === "项目截止" ? title
                    : scenario.days === 0 ? "今天高考"
                    : scenario.days === 1 ? "明天高考" : title;
                compare(widget.headlineText, expected);
                compare(widget.compactCountdownText, scenario.compact);
            }
        }
    }

    function test_customTargetDate() {
        const widget = makeWidget();
        widget.plasmoid.configuration.titleText = "项目截止";
        widget.plasmoid.configuration.targetMonth = 12;
        widget.plasmoid.configuration.targetDay = 31;
        widget.now = new Date(2026, 11, 30, 12);
        compare(widget.calendarDaysLeft, 1);
        compare(widget.headlineText, "项目截止");
        widget.now = new Date(2026, 11, 31, 17);
        compare(widget.calendarDaysLeft, 0);
        compare(widget.headlineText, "项目截止");
        compare(widget.countdownText, "今天");
        widget.now = new Date(2027, 0, 1, 12);
        compare(widget.targetDate.getFullYear(), 2027);
        compare(widget.calendarDaysLeft, 364);
        compare(widget.headlineText, "项目截止");
    }
}
