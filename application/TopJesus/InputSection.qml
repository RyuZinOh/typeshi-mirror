pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root

    property string value: ""

    signal valueEdited(string text)
    signal cancelled
    signal submitted

    height: numericBox.height

    function focusInput() {
        numericInput.forceActiveFocus();
        numericInput.selectAll();
    }

    Rectangle {
        id: numericBox
        width: parent.width
        height: numericInput.contentHeight + 24
        radius: 14
        color: Theme.surfaceContainerHigh
        border.color: numericInput.activeFocus ? Theme.primaryColor : Theme.outlineVariant
        border.width: 1

        Behavior on height {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutQuart
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: 150
            }
        }

        TextInput {
            id: numericInput
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            horizontalAlignment: TextInput.AlignLeft
            verticalAlignment: TextInput.AlignVCenter
            font.pixelSize: 20
            font.bold: true
            color: Theme.onSurface
            maximumLength: 3
            text: root.value
            validator: RegularExpressionValidator {
                regularExpression: /[0-9]{0,3}/
            }

            onTextChanged: root.valueEdited(numericInput.text)

            Keys.onEscapePressed: event => {
                root.cancelled();
                event.accepted = true;
            }
            Keys.onReturnPressed: event => {
                root.submitted();
                event.accepted = true;
            }
            Keys.onEnterPressed: event => {
                root.submitted();
                event.accepted = true;
            }
        }
    }
}
