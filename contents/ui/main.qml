import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.plasmoid 2.0
import "../code/hours.js" as Hours

Item {
    id: root

    property date now: new Date()
    property var ranges: Hours.parseRanges(plasmoid.configuration.peakHours)
    property bool weekdaysOnly: plasmoid.configuration.weekdaysOnly
    property bool isPeak: Hours.isPeakAt(ranges, now, weekdaysOnly)
    property var transition: Hours.nextTransition(ranges, now, weekdaysOnly)

    implicitWidth: 260
    implicitHeight: 150

    readonly property color accentColor: isPeak ? "#c75c5c" : "#5ca65c"

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    readonly property int textAlign: {
        var a = plasmoid.configuration.textAlign;
        if (a === "center") { return Text.AlignHCenter; }
        if (a === "right") { return Text.AlignRight; }
        return Text.AlignLeft;
    }
    readonly property int rowAlign: {
        var a = plasmoid.configuration.textAlign;
        if (a === "center") { return Qt.AlignHCenter; }
        if (a === "right") { return Qt.AlignRight; }
        return Qt.AlignLeft;
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    function fmtClock(sec) {
        if (sec < 0) {
            return "--:--:--";
        }
        sec = Math.floor(sec);
        var h = Math.floor(sec / 3600);
        var m = Math.floor(sec / 60) % 60;
        var s = sec % 60;
        return h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    function transitionLocalStr() {
        if (transition.seconds < 0) {
            return "";
        }
        var d = new Date(now.getTime() + transition.seconds * 1000);
        var off = -d.getTimezoneOffset() / 60;
        var sign = off >= 0 ? "+" : "-";
        var abs = Math.abs(off);
        var hh = Math.floor(abs);
        var mm = Math.round((abs - hh) * 60);
        var tz = "GMT" + sign + hh + (mm > 0 ? ":" + (mm < 10 ? "0" : "") + mm : "");
        var dayPrefix = (d.toDateString() !== now.toDateString()) ? Qt.formatDate(d, "ddd") + " " : "";
        return dayPrefix + Qt.formatTime(d, "h:mm AP") + " " + tz;
    }

    property string statusText: isPeak ? "PEAK · FULL PRICE" : "OFF-PEAK · HALF PRICE"
    property string nextText: transition.seconds < 0 ? "No upcoming change" : (isPeak ? "Off-peak" : "Peak") + " starts " + transitionLocalStr()
    property string countdownText: fmtClock(transition.seconds)

    property string tooltipText: {
        var cfg = plasmoid.configuration;
        function pt(p) {
            p = Number(p) || 0;
            if (p >= 0.1) { return p.toFixed(2); }
            if (p >= 0.01) { return p.toFixed(3); }
            return p.toFixed(4);
        }
        return cfg.model + " · USD per 1M tokens\n" +
            "cache-hit  in: peak $" + pt(cfg.cacheHitPeak) + " / off-peak $" + pt(cfg.cacheHitOffPeak) + "\n" +
            "cache-miss in: peak $" + pt(cfg.cacheMissPeak) + " / off-peak $" + pt(cfg.cacheMissOffPeak) + "\n" +
            "output:        peak $" + pt(cfg.outputPeak) + " / off-peak $" + pt(cfg.outputOffPeak) + "\n" +
            "peak hours (UTC" + (root.weekdaysOnly ? ", Mon-Fri" : "") + "): " + cfg.peakHours;
    }

    Rectangle {
        anchors.fill: parent
        radius: units.gridUnit * 0.6
        color: root.accentColor
        opacity: Math.max(0, Math.min(1, plasmoid.configuration.bgOpacity))
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: units.gridUnit * 0.7
        spacing: units.smallSpacing

        RowLayout {
            Layout.alignment: root.rowAlign
            spacing: units.smallSpacing

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 8
                height: 8
                radius: 4
                color: "white"
            }

            PlasmaComponents.Label {
                text: root.statusText
                color: "white"
                font.bold: true
                font.pixelSize: Math.max(9, theme.smallestFont.pixelSize)
                font.letterSpacing: 1
            }
        }

        RowLayout {
            Layout.alignment: root.rowAlign
            Layout.fillHeight: true
            spacing: units.smallSpacing

            PlasmaComponents.Label {
                id: countdownLabel
                Layout.alignment: Qt.AlignVCenter
                text: root.countdownText
                color: "white"
                font.bold: true
                font.pixelSize: Math.max(18, root.height * 0.30)
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: Math.max(4, root.height * 0.045)
                text: "left"
                color: "white"
                opacity: 0.75
                font.pixelSize: Math.max(10, root.height * 0.10)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "white"
            opacity: 0.35
        }

        PlasmaComponents.Label {
            Layout.alignment: root.rowAlign
            horizontalAlignment: root.textAlign
            text: "→ " + root.nextText
            color: "white"
            opacity: 0.9
            font.pixelSize: Math.max(9, theme.smallestFont.pixelSize)
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true

        PlasmaComponents.ToolTip {
            text: root.tooltipText
            visible: hoverArea.containsMouse
        }
    }
}
