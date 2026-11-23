/* Peak/off-peak hours logic for the DeepSeek Hours Clock plasmoid.
 *
 * Peak hours are configured as comma-separated UTC hour ranges with an
 * exclusive end, matching DeepSeek's published windows, e.g.
 * "1-4,6-10" means 01:00-04:00 and 06:00-10:00 UTC.
 * A single number like "5" means the 05:00-06:00 hour.
 * A range may wrap past midnight, e.g. "22-3" covers 22:00-03:00.
 *
 * DeepSeek charges peak rates Monday through Friday, excluding Chinese public
 * holidays. Weekends and those holidays are off-peak all day. DeepSeek bills
 * every weekend at the off-peak rate regardless of the office calendar, so
 * make-up workdays (调休) do NOT become peak. Source:
 * https://api-docs.deepseek.com/quick_start/pricing
 *
 * Weekday and holiday decisions are made on the Beijing (UTC+8) calendar,
 * because the peak windows (09:00-12:00 and 14:00-18:00 Beijing) are defined
 * in Beijing time.
 */

function parseRanges(str) {
    var ranges = [];
    if (str === undefined || str === null) {
        return ranges;
    }
    var parts = String(str).split(',');
    for (var i = 0; i < parts.length; i++) {
        var p = parts[i].trim();
        if (p.length === 0) {
            continue;
        }
        var m = p.split('-');
        var a = parseInt(m[0], 10);
        if (isNaN(a)) {
            continue;
        }
        var b;
        if (m.length > 1) {
            b = parseInt(m[1], 10);
            if (isNaN(b)) {
                b = a + 1;
            }
        } else {
            b = a + 1;
        }
        ranges.push({ start: a, end: b });
    }
    return ranges;
}

function inRange(range, hour) {
    /* An equal-endpoint range (e.g. "4-4") is empty. */
    if (range.start === range.end) {
        return false;
    }
    if (range.start < range.end) {
        return hour >= range.start && hour < range.end;
    }
    /* wraps past midnight, e.g. 22-3 */
    return hour >= range.start || hour < range.end;
}

function isPeakHour(ranges, hour) {
    for (var i = 0; i < ranges.length; i++) {
        if (inRange(ranges[i], hour)) {
            return true;
        }
    }
    return false;
}

/* ---- Chinese public holidays -------------------------------------------
 *
 * Full 放假 ranges for the lunar and solar-term holidays, as
 * [year, startMonth, startDay, endMonth, endDay, name]. Ranges are inclusive
 * and may cross a month boundary (Spring Festival 2028 starts 25 January and
 * ends 1 February).
 *
 * Only 2026 is officially published (State Council notice of 2025-11-04):
 *   元旦 1/1-1/3, 春节 2/15-2/23, 清明 4/4-4/6, 劳动节 5/1-5/5,
 *   端午 6/19-6/21, 中秋 9/25-9/27, 国庆 10/1-10/7.
 * Later years follow the standing rules from the revised 放假办法: Spring
 * Festival 8 days from 除夕, National Day 7 days from 1 October, Labor Day
 * 5 days, and 3 days for the rest - collapsing to the single day when the
 * holiday lands on a Wednesday. National Day merges with Mid-Autumn (8 days)
 * in 2028 and 2031.
 */
var VARIABLE_HOLIDAYS = [
    // 2026 - officially published.
    [2026, 2, 15, 2, 23, "Spring Festival"],
    [2026, 4, 4, 4, 6, "Qingming"],
    [2026, 6, 19, 6, 21, "Dragon Boat"],
    [2026, 9, 25, 9, 27, "Mid-Autumn"],
    // 2027 - Dragon Boat and Mid-Autumn both land on a Wednesday: single day.
    [2027, 2, 5, 2, 12, "Spring Festival"],
    [2027, 4, 5, 4, 7, "Qingming"],
    [2027, 6, 9, 6, 9, "Dragon Boat"],
    [2027, 9, 15, 9, 15, "Mid-Autumn"],
    // 2028 - Mid-Autumn (3 Oct) merges into the National Day block.
    [2028, 1, 25, 2, 1, "Spring Festival"],
    [2028, 4, 4, 4, 6, "Qingming"],
    [2028, 5, 28, 5, 30, "Dragon Boat"],
    [2028, 10, 3, 10, 3, "Mid-Autumn"],
    // 2029.
    [2029, 2, 12, 2, 19, "Spring Festival"],
    [2029, 4, 4, 4, 6, "Qingming"],
    [2029, 6, 16, 6, 18, "Dragon Boat"],
    [2029, 9, 22, 9, 24, "Mid-Autumn"],
    // 2030.
    [2030, 2, 2, 2, 9, "Spring Festival"],
    [2030, 4, 5, 4, 7, "Qingming"],
    [2030, 6, 5, 6, 7, "Dragon Boat"],
    [2030, 9, 12, 9, 14, "Mid-Autumn"],
    // 2031 - Mid-Autumn (1 Oct) merges into the National Day block.
    [2031, 1, 22, 1, 29, "Spring Festival"],
    [2031, 4, 5, 4, 7, "Qingming"],
    [2031, 6, 24, 6, 26, "Dragon Boat"],
    [2031, 10, 1, 10, 1, "Mid-Autumn"],
    // 2032.
    [2032, 2, 10, 2, 17, "Spring Festival"],
    [2032, 4, 4, 4, 6, "Qingming"],
    [2032, 6, 12, 6, 14, "Dragon Boat"],
    [2032, 9, 19, 9, 21, "Mid-Autumn"]
];

var HOLIDAY_YEAR_START = 2026;
var HOLIDAY_YEAR_END = 2032;

function holidaysKnownFor(year) {
    return year >= HOLIDAY_YEAR_START && year <= HOLIDAY_YEAR_END;
}

/* The Beijing wall clock for a UTC instant, read through the UTC getters. */
function beijingDay(date) {
    var d = new Date(date.getTime() + 8 * 3600000);
    return {
        year: d.getUTCFullYear(),
        month: d.getUTCMonth() + 1,
        day: d.getUTCDate(),
        weekday: d.getUTCDay()
    };
}

function weekdayOf(year, month, day) {
    return new Date(Date.UTC(year, month - 1, day)).getUTCDay();
}

/* Fixed-date 放假 ranges. New Year is 3 days from 1 January (collapsing to
 * the single day when 1 January is a Wednesday); Labor Day is 5 days from
 * 1 May; National Day is 7 days from 1 October, or 8 when it absorbs
 * Mid-Autumn. */
function fixedHoliday(year, month) {
    if (month === 1) {
        return { start: 1, end: weekdayOf(year, 1, 1) === 3 ? 1 : 3, name: "New Year" };
    }
    if (month === 5) {
        return { start: 1, end: weekdayOf(year, 5, 1) === 3 ? 1 : 5, name: "Labor Day" };
    }
    if (month === 10) {
        return { start: 1, end: (year === 2028 || year === 2031) ? 8 : 7, name: "National Day" };
    }
    return null;
}

/* The holiday name for a Beijing day, or null if it is a working day. */
function holidayName(bj) {
    if (!holidaysKnownFor(bj.year)) {
        return null;
    }
    /* Variable (lunar / solar-term) ranges win: Mid-Autumn must be named
     * before the fixed National Day block absorbs the same dates. */
    var key = bj.month * 100 + bj.day;
    for (var i = 0; i < VARIABLE_HOLIDAYS.length; i++) {
        var h = VARIABLE_HOLIDAYS[i];
        if (h[0] !== bj.year) {
            continue;
        }
        var start = h[1] * 100 + h[2];
        var end = h[3] * 100 + h[4];
        if (start <= key && key <= end) {
            return h[5];
        }
    }
    var fixed = fixedHoliday(bj.year, bj.month);
    if (fixed && bj.day >= fixed.start && bj.day <= fixed.end) {
        return fixed.name;
    }
    return null;
}

function isWeekend(bj) {
    return bj.weekday === 0 || bj.weekday === 6;
}

function isPeakAt(ranges, date, weekdaysOnly, holidays) {
    var bj = beijingDay(date);
    if (holidays && holidayName(bj) !== null) {
        return false;
    }
    if (weekdaysOnly && isWeekend(bj)) {
        return false;
    }
    return isPeakHour(ranges, date.getUTCHours());
}

/* Why the current instant is off-peak, when it is not simply the weekday
 * gap: a holiday name, "Weekend", or null. */
function offpeakReason(date, weekdaysOnly, holidays) {
    var bj = beijingDay(date);
    if (holidays) {
        var name = holidayName(bj);
        if (name !== null) {
            return name;
        }
    }
    if (weekdaysOnly && isWeekend(bj)) {
        return "Weekend";
    }
    return null;
}

/* Returns { seconds } until the next peak status change, or seconds: -1 if
 * the status never changes within the next 21 days. The longest off-peak run
 * in the encoded tables is about 10 days (Spring Festival), so 21 days is
 * ample headroom. */
function nextTransition(ranges, date, weekdaysOnly, holidays) {
    var cur = isPeakAt(ranges, date, weekdaysOnly, holidays);
    var d = new Date(date);
    d.setUTCMinutes(0, 0, 0);
    d.setUTCHours(d.getUTCHours() + 1);
    for (var i = 0; i < 21 * 24; i++) {
        if (isPeakAt(ranges, d, weekdaysOnly, holidays) !== cur) {
            return { seconds: (d.getTime() - date.getTime()) / 1000 };
        }
        d = new Date(d.getTime() + 3600 * 1000);
    }
    return { seconds: -1 };
}
