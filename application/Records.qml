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
            // History.bestWpm read below forces this binding to re-evaluate on historyChanged,
            // since bestWpmFor() is a plain invokable with no NOTIFY of its own.
            text: {
                History.bestWpm;
                return "15s: " + History.bestWpmFor("english", 15, 0).toFixed(1) + " / " + History.bestWpmFor("english", 15, 1).toFixed(1) + " punct";
            }
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
        Text {
            text: {
                History.bestWpm;
                return "30s: " + History.bestWpmFor("english", 30, 0).toFixed(1) + " / " + History.bestWpmFor("english", 30, 1).toFixed(1) + " punct";
            }
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
        Text {
            text: {
                History.bestWpm;
                return "60s: " + History.bestWpmFor("english", 60, 0).toFixed(1) + " / " + History.bestWpmFor("english", 60, 1).toFixed(1) + " punct";
            }
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
        Text {
            text: {
                History.bestWpm;
                return "120s: " + History.bestWpmFor("english", 120, 0).toFixed(1) + " / " + History.bestWpmFor("english", 120, 1).toFixed(1) + " punct";
            }
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
            text: {
                History.bestWpm;
                return "10: " + History.bestWpmForWords(10, 0).toFixed(1) + " / " + History.bestWpmForWords(10, 1).toFixed(1) + " punct";
            }
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
        Text {
            text: {
                History.bestWpm;
                return "25: " + History.bestWpmForWords(25, 0).toFixed(1) + " / " + History.bestWpmForWords(25, 1).toFixed(1) + " punct";
            }
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
        Text {
            text: {
                History.bestWpm;
                return "50: " + History.bestWpmForWords(50, 0).toFixed(1) + " / " + History.bestWpmForWords(50, 1).toFixed(1) + " punct";
            }
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
        Text {
            text: {
                History.bestWpm;
                return "100: " + History.bestWpmForWords(100, 0).toFixed(1) + " / " + History.bestWpmForWords(100, 1).toFixed(1) + " punct";
            }
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
            text: {
                History.bestWpm;
                return "best: " + History.bestWpmFor("quote", 0).toFixed(1);
            }
            font.pixelSize: 14
            color: Theme.onSurfaceVariant
        }
    }
}
