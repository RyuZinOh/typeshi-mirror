pragma ComponentBehavior: Bound
import QtQuick
import typeShitter

Item {
    id: root
    anchors.fill: parent
    z: 200

    readonly property int cellSize: 15
    readonly property int cellSpacing: 4
    readonly property int weeksToShow: 34
    readonly property var dayLabels: ["Sunday", "", "Tuesday", "", "Thursday", "", "Saturday"]
    readonly property int labelColumnWidth: 68
    readonly property int labelGridSpacing: 8
    readonly property int sidePadding: 10
    readonly property int topGridSpacing: 4

    property var dayMap: ({})
    property var weeks: []
    property int totalTests: 0

    property bool open: false
    property real progress: 0

    property real originX: 0
    property real originY: 0
    property real originWidth: 120
    property real originHeight: 48

    property int hoveredWeekIndex: -1
    property int hoveredDayIndex: -1
    property var hoveredDayData: null

    readonly property real targetWidth: contentCol.implicitWidth + root.sidePadding * 2
    readonly property real targetHeight: contentCol.implicitHeight + 32
    readonly property real targetX: root.originX
    readonly property real targetY: Math.max(20, root.originY + root.originHeight - root.targetHeight)

    visible: root.progress > 0.001

    function openFrom(x, y, w, h) {
        root.originX = x;
        root.originY = y;
        root.originWidth = w;
        root.originHeight = h;
        root.rebuild();
        root.open = true;
    }

    function close() {
        root.open = false;
        root.hoveredWeekIndex = -1;
        root.hoveredDayIndex = -1;
        root.hoveredDayData = null;
    }

    function pad2(n) {
        if (n < 10) {
            return "0" + n;
        }
        return "" + n;
    }

    function dateKey(d) {
        return d.getFullYear() + "-" + root.pad2(d.getMonth() + 1) + "-" + root.pad2(d.getDate());
    }

    function rebuild() {
        const summary = History.dailySummary();
        const map = {};
        let total = 0;
        for (let i = 0; i < summary.length; i++) {
            map[summary[i].date] = summary[i];
            total += summary[i].tests;
        }
        root.dayMap = map;
        root.totalTests = total;

        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const endOfWeek = new Date(today.getFullYear(), today.getMonth(), today.getDate());
        endOfWeek.setDate(endOfWeek.getDate() + (6 - today.getDay()));

        const totalDays = root.weeksToShow * 7;
        const start = new Date(endOfWeek.getFullYear(), endOfWeek.getMonth(), endOfWeek.getDate());
        start.setDate(start.getDate() - totalDays + 1);

        const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        const dayNames = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"];

        const cols = [];
        for (let w = 0; w < root.weeksToShow; w++) {
            const col = [];
            for (let d = 0; d < 7; d++) {
                const dayOffset = w * 7 + d;
                const day = new Date(start.getFullYear(), start.getMonth(), start.getDate());
                day.setDate(day.getDate() + dayOffset);

                const key = root.dateKey(day);
                const entry = map[key];
                const label = dayNames[day.getDay()] + " " + day.getDate() + " " + monthNames[day.getMonth()].toLowerCase() + " " + day.getFullYear();
                col.push({
                    date: key,
                    dateLabel: label,
                    inFuture: day.getTime() > today.getTime(),
                    tests: entry ? entry.tests : 0,
                    bestWpm: entry ? entry.bestWpm : 0
                });
            }
            cols.push(col);
        }
        root.weeks = cols;
    }

    function intensity(tests) {
        if (tests <= 0) {
            return 0;
        }
        if (tests === 1) {
            return 1;
        }
        if (tests <= 3) {
            return 2;
        }
        if (tests <= 6) {
            return 3;
        }
        return 4;
    }

    function cellColor(tests) {
        const level = root.intensity(tests);
        if (level === 0) {
            return Theme.surfaceContainerHigh;
        }
        const c = Theme.primaryColor;
        const alphas = [0, 0.25, 0.45, 0.7, 1.0];
        return Qt.rgba(c.r, c.g, c.b, alphas[level]);
    }

    Keys.onEscapePressed: root.close()

    NumberAnimation {
        id: progressAnim
        target: root
        property: "progress"
        duration: 420
        easing.type: Easing.OutCubic
    }

    onOpenChanged: {
        progressAnim.stop();
        progressAnim.from = root.progress;
        progressAnim.to = root.open ? 1 : 0;
        progressAnim.easing.type = root.open ? Easing.OutCubic : Easing.InCubic;
        progressAnim.start();
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.progress > 0.5
        onClicked: root.close()
    }

    Rectangle {
        id: panel
        x: root.originX + (root.targetX - root.originX) * root.progress
        y: root.originY + (root.targetY - root.originY) * root.progress
        width: root.originWidth + (root.targetWidth - root.originWidth) * root.progress
        height: root.originHeight + (root.targetHeight - root.originHeight) * root.progress
        radius: 20
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1
        clip: true

        Column {
            id: contentCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: root.sidePadding - 20
            anchors.topMargin: 14
            spacing: 8

            transformOrigin: Item.TopLeft
            scale: 0.88 + 0.12 * root.progress
            opacity: Math.max(0, Math.min(1, (root.progress - 0.4) / 0.5))

            Item {
                id: headerRow
                width: gridContainer.width
                height: Math.max(totalLabel.implicitHeight, legendRow.implicitHeight)

                Text {
                    id: totalLabel
                    x: root.labelColumnWidth + root.labelGridSpacing
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.totalTests + " tests total"
                    font.pixelSize: 12
                    color: Theme.onSurfaceVariant
                }

                Row {
                    id: legendRow
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5

                    Text {
                        text: "less"
                        font.pixelSize: 10
                        color: Theme.onSurfaceVariant
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Repeater {
                        model: 5

                        delegate: Rectangle {
                            required property int index
                            width: 10
                            height: 10
                            radius: 3
                            color: {
                                if (index === 0) {
                                    return Theme.surfaceContainerHigh;
                                }
                                const c = Theme.primaryColor;
                                const alphas = [0, 0.25, 0.45, 0.7, 1.0];
                                return Qt.rgba(c.r, c.g, c.b, alphas[index]);
                            }
                        }
                    }

                    Text {
                        text: "more"
                        font.pixelSize: 10
                        color: Theme.onSurfaceVariant
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Item {
                width: 1
                height: root.topGridSpacing
            }

            Item {
                id: gridContainer
                width: gridRow.width
                height: gridRow.height

                Row {
                    id: gridRow
                    spacing: root.labelGridSpacing

                    Column {
                        id: labelColumn
                        spacing: root.cellSpacing
                        anchors.top: parent.top

                        Repeater {
                            model: root.dayLabels

                            delegate: Item {
                                required property string modelData
                                width: root.labelColumnWidth
                                height: root.cellSize

                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: parent.modelData
                                    font.pixelSize: 10
                                    color: Theme.onSurfaceVariant
                                }
                            }
                        }
                    }

                    Row {
                        id: weeksRow
                        spacing: root.cellSpacing

                        Repeater {
                            model: root.weeks

                            delegate: Column {
                                id: weekCol
                                required property var modelData
                                required property int index
                                spacing: root.cellSpacing

                                Repeater {
                                    model: weekCol.modelData

                                    delegate: Rectangle {
                                        id: dayCell
                                        required property var modelData
                                        required property int index

                                        readonly property bool isHovered: !dayCell.modelData.inFuture && root.hoveredWeekIndex === weekCol.index && root.hoveredDayIndex === dayCell.index

                                        width: root.cellSize
                                        height: root.cellSize
                                        radius: 4
                                        color: dayCell.modelData.inFuture ? "transparent" : root.cellColor(dayCell.modelData.tests)
                                        border.width: (dayCell.modelData.inFuture || dayCell.isHovered) ? 1 : 0
                                        border.color: dayCell.isHovered ? Theme.primaryColor : Theme.outlineVariant
                                        opacity: dayCell.modelData.inFuture ? 0.25 : 1

                                        Behavior on border.color {
                                            ColorAnimation {
                                                duration: 100
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            enabled: !dayCell.modelData.inFuture
                                            onEntered: {
                                                root.hoveredWeekIndex = weekCol.index;
                                                root.hoveredDayIndex = dayCell.index;
                                                root.hoveredDayData = dayCell.modelData;
                                            }
                                            onExited: {
                                                if (root.hoveredWeekIndex === weekCol.index && root.hoveredDayIndex === dayCell.index) {
                                                    root.hoveredWeekIndex = -1;
                                                    root.hoveredDayIndex = -1;
                                                    root.hoveredDayData = null;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: sharedTooltip
                    visible: root.hoveredDayData !== null
                    z: 1000
                    width: tooltipText.width + 14
                    height: tooltipText.height + 8
                    radius: 8
                    color: Theme.surfaceContainerHighest
                    border.color: Theme.outlineVariant
                    border.width: 1

                    readonly property real cellCenterX: root.labelColumnWidth + root.labelGridSpacing + root.hoveredWeekIndex * (root.cellSize + root.cellSpacing) + root.cellSize / 2
                    readonly property real cellTopY: root.hoveredDayIndex * (root.cellSize + root.cellSpacing)
                    readonly property real cellBottomY: cellTopY + root.cellSize

                    x: Math.max(2, Math.min(cellCenterX - width / 2, gridContainer.width - width - 2))
                    y: root.hoveredDayIndex === 0 ? cellBottomY + 8 : cellTopY - height - 8

                    Text {
                        id: tooltipText
                        anchors.centerIn: parent
                        text: root.hoveredDayData ? (root.hoveredDayData.tests > 0 ? root.hoveredDayData.tests + (root.hoveredDayData.tests === 1 ? " test" : " tests") : "no tests") + " on " + root.hoveredDayData.dateLabel : ""
                        font.pixelSize: 10
                        color: Theme.onSurface
                    }
                }
            }
        }
    }
}
