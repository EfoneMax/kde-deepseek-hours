/* Peak/off-peak hours logic for the DeepSeek Hours Clock plasmoid.
 *
 * Peak hours are configured as comma-separated UTC hour ranges with an
 * exclusive end, matching DeepSeek's published windows, e.g.
 * "1-4,6-10" means 01:00-04:00 and 06:00-10:00 UTC.
 * A single number like "5" means the 05:00-06:00 hour.
 * A range may wrap past midnight, e.g. "22-3" covers 22:00-03:00.
 *
 * DeepSeek charges peak rates only Monday through Friday (UTC); weekends
 * are entirely off-peak.
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

function isWeekend(date) {
    var d = date.getUTCDay();
    return d === 0 || d === 6;
}

function isPeakAt(ranges, date, weekdaysOnly) {
    if (weekdaysOnly && isWeekend(date)) {
        return false;
    }
    return isPeakHour(ranges, date.getUTCHours());
}

/* Returns { seconds } until the next peak status change, or seconds: -1
 * if the status never changes within the next 7 days. */
function nextTransition(ranges, date, weekdaysOnly) {
    var cur = isPeakAt(ranges, date, weekdaysOnly);
    var d = new Date(date);
    d.setUTCMinutes(0, 0, 0);
    d.setUTCHours(d.getUTCHours() + 1);
    for (var i = 0; i < 7 * 24; i++) {
        if (isPeakAt(ranges, d, weekdaysOnly) !== cur) {
            return { seconds: (d.getTime() - date.getTime()) / 1000 };
        }
        d = new Date(d.getTime() + 3600 * 1000);
    }
    return { seconds: -1 };
}
