import QtQuick 2.0
import bomi 1.0

Slider {
    id: seeker
    property Component markerStyle
    property alias time: seeker.value
    property TimeDuration bind
    property bool toolTip: !bind
    property int target: -1

    onBindChanged: {
        if (bind)
            bind.time = Qt.binding(function ( ) { return mouseArea.time; })
    }

    Component {
        id: dummy;
        Item {
            property var marker
            property var chapter
            x: seeker.width * chapter.rate
            function updateTarget() {
                if (marker.hovered && seeker.bind)
                    seeker.target = chapter.time
                else
                    seeker.target = -1
            }
            function seek() { seeker.time = chapter.time; }
            onMarkerChanged: {
                if (marker.hovered !== undefined)
                    marker.hoveredChanged.connect(updateTarget)
                if (marker.clicked !== undefined)
                    marker.clicked.connect(seek)
            }
        }
    }

    Repeater {
        model: d.engine.chapters
        Loader {
            readonly property Chapter chapter: modelData
            readonly property Slider control: seeker
            x: seeker.width * chapter.rate
            sourceComponent: markerStyle
        }
    }

    QtObject {
        id: d;
        readonly property Engine engine: App.engine
        property bool ticking: false
        function target(x) { return (min + (x/seeker.width)*(max - min)); }
    }

    Connections {
        target: d.engine
        onTick: {
            d.ticking = true;
            seeker.value = d.engine.time
            d.ticking = false;
        }
        onEndChanged: {
            d.ticking = true;
            seeker.max = d.engine.end
            seeker.value = d.engine.time
            d.ticking = false;
        }
        onBeginChanged: {
            d.ticking = true;
            seeker.min = d.engine.begin
            seeker.value = d.engine.time
            d.ticking = false;
        }
    }
    onValueChanged: { if (!d.ticking) d.engine.seek(value); }

    MouseArea {
        id: mouseArea
        visible: bind || toolTip
        anchors.fill: parent
        hoverEnabled: true
        property bool moving: pressed || containsMouse
        property int time: seeker.target >= 0 ? seeker.target : moving ? d.target(mouseX) : d.engine.time
        Text { id: t }
        onMovingChanged: if (toolTip && !moving) App.window.hideToolTip()
        onPositionChanged: {
            var val = d.target(mouse.x)
            if (toolTip)
                App.window.showToolTip(seeker, mouse.x, mouse.y,
                                       t.formatTime(val) + "/" + t.formatTime(max))
            if (pressed)
                value = val
        }
        onPressed: { value = d.target(mouse.x) }
    }
}
