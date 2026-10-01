import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.5 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents

ColumnLayout {
    id: page

    property alias cfg_bgOpacity: opacitySlider.value
    property alias cfg_weekdaysOnly: weekdaysBox.checked
    property alias cfg_respectHolidays: holidaysBox.checked
    property alias cfg_peakHours: hoursField.text
    property alias cfg_cacheHitPeak: hitPeakField.text
    property alias cfg_cacheHitOffPeak: hitOffField.text
    property alias cfg_cacheMissPeak: missPeakField.text
    property alias cfg_cacheMissOffPeak: missOffField.text
    property alias cfg_outputPeak: outPeakField.text
    property alias cfg_outputOffPeak: outOffField.text
    property string cfg_model
    property string cfg_textAlign

    property var flashPrices: {
        "cacheHitPeak": "0.006", "cacheHitOffPeak": "0.003",
        "cacheMissPeak": "0.3", "cacheMissOffPeak": "0.15",
        "outputPeak": "1.2", "outputOffPeak": "0.6"
    }
    property var proPrices: {
        "cacheHitPeak": "0.044", "cacheHitOffPeak": "0.022",
        "cacheMissPeak": "1.32", "cacheMissOffPeak": "0.66",
        "outputPeak": "3.96", "outputOffPeak": "1.98"
    }

    function setPrices(p) {
        cfg_cacheHitPeak = p.cacheHitPeak;
        cfg_cacheHitOffPeak = p.cacheHitOffPeak;
        cfg_cacheMissPeak = p.cacheMissPeak;
        cfg_cacheMissOffPeak = p.cacheMissOffPeak;
        cfg_outputPeak = p.outputPeak;
        cfg_outputOffPeak = p.outputOffPeak;
    }

    function applyModel(index) {
        var names = ["deepseek-flash", "deepseek-v4-pro", "custom"];
        cfg_model = names[index];
        if (index === 0) { setPrices(flashPrices); }
        else if (index === 1) { setPrices(proPrices); }
    }

    Kirigami.FormLayout {
        Layout.fillWidth: true

        QQC2.ComboBox {
            id: modelCombo
            Kirigami.FormData.label: "Model:"
            model: ["deepseek-flash", "deepseek-v4-pro", "custom"]
            currentIndex: cfg_model === "deepseek-flash" ? 0 : (cfg_model === "deepseek-v4-pro" ? 1 : 2)
            onActivated: page.applyModel(index)
        }

        QQC2.Slider {
            id: opacitySlider
            Kirigami.FormData.label: "Background opacity: " + Math.round(value * 100) + "%"
            Layout.fillWidth: true
            Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            from: 0
            to: 1
            stepSize: 0.05
        }

        QQC2.ComboBox {
            id: alignCombo
            Kirigami.FormData.label: "Text alignment:"
            model: ["left", "center", "right"]
            currentIndex: cfg_textAlign === "center" ? 1 : (cfg_textAlign === "right" ? 2 : 0)
            onActivated: cfg_textAlign = model[index]
        }

        PlasmaComponents.TextField {
            id: hoursField
            Kirigami.FormData.label: "Peak hours (UTC):"
            placeholderText: "1-4,6-10"
        }

        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "Hour ranges have an exclusive end: 1-4,6-10 means 01:00-04:00 and 06:00-10:00 UTC. A range may wrap past midnight, e.g. 22-3."
            wrapMode: Text.WordWrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        }

        QQC2.CheckBox {
            id: weekdaysBox
            text: "Peak hours Monday-Friday only (UTC)"
        }

        QQC2.CheckBox {
            id: holidaysBox
            text: "Chinese public holidays are off-peak all day"
        }

        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "Holiday dates are encoded for 2026–2032 (2026 official; later years estimated). Weekends, including make-up workdays, stay off-peak."
            wrapMode: Text.WordWrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
        }

        QQC2.Label {
            Kirigami.FormData.label: ""
            text: "Prices in USD per 1M tokens:"
            font.bold: true
        }

        PlasmaComponents.TextField {
            id: hitPeakField
            Kirigami.FormData.label: "Cache-hit in, peak:"
        }

        PlasmaComponents.TextField {
            id: hitOffField
            Kirigami.FormData.label: "Cache-hit in, off-peak:"
        }

        PlasmaComponents.TextField {
            id: missPeakField
            Kirigami.FormData.label: "Cache-miss in, peak:"
        }

        PlasmaComponents.TextField {
            id: missOffField
            Kirigami.FormData.label: "Cache-miss in, off-peak:"
        }

        PlasmaComponents.TextField {
            id: outPeakField
            Kirigami.FormData.label: "Output, peak:"
        }

        PlasmaComponents.TextField {
            id: outOffField
            Kirigami.FormData.label: "Output, off-peak:"
        }

        QQC2.Button {
            text: "Reset to deepseek-flash defaults"
            onClicked: {
                modelCombo.currentIndex = 0;
                cfg_model = "deepseek-flash";
                cfg_peakHours = "1-4,6-10";
                cfg_weekdaysOnly = true;
                cfg_respectHolidays = true;
                setPrices(flashPrices);
            }
        }
    }
}
