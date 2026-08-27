import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// __NAME__ — __DESC__
//
// Replace this comment with prose that says *why* the widget behaves the way it
// does. See TASTE.md rule 8: the Omarchy house style explains reasoning, not
// mechanics, and a comment that restates the line under it should be deleted.
BarWidget {
  id: root
  moduleName: "__ID__"

  // Defaults live here, not in a settings screen. The widget has to be right
  // for someone who never opens shell.json — that person is almost everyone.
  readonly property int refreshSeconds: setting("refreshSeconds", 30)

  property string value: "—"

  // The horizontal bar has room for a word; the vertical bar has room for a
  // glyph. Deciding that here keeps the branch out of the paint path below.
  readonly property string displayText: vertical ? value.slice(0, 3) : value

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    source.running = true
  }

  // Reads once on a timer rather than polling continuously: a bar widget that
  // wakes the CPU every second is spending someone's battery on itself.
  Process {
    id: source
    command: ["sh", "-c", "echo hello"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: root.value = text.trim() || "—"
    }
  }

  Timer {
    interval: root.refreshSeconds * 1000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  // Exposes the widget to a Hyprland keybind over the shell's IPC, the way
  // every first-party widget does. Confirm the exact CLI form on your own box
  // with `omarchy-shell --help` before you put it in the README.
  IpcHandler {
    target: "__ID__"

    function refresh(): void { root.refresh() }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.displayText
    hasVisualContent: text !== ""
    tooltipText: "__NAME__ — right-click to refresh"

    // Three buttons, three meanings. A widget that answers only the left click
    // is leaving affordance on the table (TASTE.md rule 9).
    onPressed: function (b) {
      if (b === Qt.RightButton) root.refresh()
    }
  }
}
