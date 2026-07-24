pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Row {
    id: root
    spacing: 36

    Column {
        spacing: 2

        Text {
            text: "overall"
            font.pixelSize: 13
            font.bold: true
            color: Theme.onSurface
        }
        Text {
            text: "best wpm: " + History.bestWpm.toFixed(1)
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
        Text {
            text: "tests today: " + History.testsToday
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
        Text {
            text: "streak: " + History.currentStreak
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
        Text {
            text: "longest streak: " + History.longestStreak
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
    }

    Column {
        spacing: 2

        Text {
            text: "time mode"
            font.pixelSize: 13
            font.bold: true
            color: Theme.onSurface
        }
        Text {
            text: "15s: " + (History.statsSummary["english_15_0"] || 0).toFixed(1) + " / " + (History.statsSummary["english_15_1"] || 0).toFixed(1) + " punct"
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
        Text {
            text: "30s: " + (History.statsSummary["english_30_0"] || 0).toFixed(1) + " / " + (History.statsSummary["english_30_1"] || 0).toFixed(1) + " punct"
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
        Text {
            text: "60s: " + (History.statsSummary["english_60_0"] || 0).toFixed(1) + " / " + (History.statsSummary["english_60_1"] || 0).toFixed(1) + " punct"
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
        Text {
            text: "120s: " + (History.statsSummary["english_120_0"] || 0).toFixed(1) + " / " + (History.statsSummary["english_120_1"] || 0).toFixed(1) + " punct"
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
    }

    Column {
        spacing: 2

        Text {
            text: "words mode"
            font.pixelSize: 13
            font.bold: true
            color: Theme.onSurface
        }
        Text {
            text: "10: " + (History.statsSummary["words_10_0"] || 0).toFixed(1) + " / " + (History.statsSummary["words_10_1"] || 0).toFixed(1) + " punct"
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
        Text {
            text: "25: " + (History.statsSummary["words_25_0"] || 0).toFixed(1) + " / " + (History.statsSummary["words_25_1"] || 0).toFixed(1) + " punct"
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
        Text {
            text: "50: " + (History.statsSummary["words_50_0"] || 0).toFixed(1) + " / " + (History.statsSummary["words_50_1"] || 0).toFixed(1) + " punct"
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
        Text {
            text: "100: " + (History.statsSummary["words_100_0"] || 0).toFixed(1) + " / " + (History.statsSummary["words_100_1"] || 0).toFixed(1) + " punct"
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
    }

    Column {
        spacing: 2

        Text {
            text: "quote mode"
            font.pixelSize: 13
            font.bold: true
            color: Theme.onSurface
        }
        Text {
            text: "best: " + (History.statsSummary["quote"] || 0).toFixed(1)
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
    }
}
