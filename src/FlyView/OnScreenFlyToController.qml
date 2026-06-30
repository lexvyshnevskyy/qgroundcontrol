import QtQuick

// Operator "fly to clicked object" overlay.
//
// When armed, a click on the video sends a custom MAVLink command
// (MAV_CMD_USER_1) to the onboard FlightController companion, which flies the
// drone to the object it is currently tracking and freezes/lands within a
// configurable distance. The click position is sent normalized (0..1) so the
// companion can pick the nearest tracked target if desired.
Item {
    id: rootItem

    property var  vehicle
    property real videoWidth:  0
    property real videoHeight: 0
    property bool armed:       false

    readonly property bool _ready: armed && !!vehicle && videoWidth > 0 && videoHeight > 0

    signal targetSent(real nx, real ny)

    function mouseClicked(mouseX, mouseY) {
        if (!_ready) {
            return
        }

        // Remove letterbox margins and normalize to the displayed video frame.
        var marginH = (width - videoWidth) / 2
        var marginV = (height - videoHeight) / 2
        var nx = Math.max(Math.min((mouseX - marginH) / videoWidth, 1.0), 0.0)
        var ny = Math.max(Math.min((mouseY - marginV) / videoHeight, 1.0), 0.0)

        vehicle.sendFlyToClickedTarget(nx, ny, true)

        _pingX = mouseX
        _pingY = mouseY
        pingAnimation.restart()
        rootItem.targetSent(nx, ny)
    }

    function abort() {
        if (vehicle) {
            vehicle.sendFlyToClickedTarget(0.5, 0.5, false)
        }
    }

    // --- Click feedback marker ---
    property real _pingX: 0
    property real _pingY: 0

    Rectangle {
        id: ping
        width: 48
        height: 48
        radius: width / 2
        color: "transparent"
        border.color: "#00e0ff"
        border.width: 3
        opacity: 0
        x: rootItem._pingX - width / 2
        y: rootItem._pingY - height / 2

        SequentialAnimation {
            id: pingAnimation
            running: false
            ParallelAnimation {
                NumberAnimation { target: ping; property: "opacity"; from: 0.9; to: 0.0; duration: 600 }
                NumberAnimation { target: ping; property: "scale";   from: 0.5; to: 1.6; duration: 600 }
            }
        }
    }
}
