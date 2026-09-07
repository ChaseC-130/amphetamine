import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "chase.amphetamine"

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateDir: home + "/.local/state/amphetamine"
  readonly property string statePath: stateDir + "/state.json"
  readonly property string binPath: {
    var url = Qt.resolvedUrl("bin/amphetamine").toString()
    return url.replace(/^file:\/\//, "")
  }

  property bool active: false
  property string mode: "off" // "off", "indefinite", "timer"
  property string label: "Off"
  property double expiresAt: 0
  property int remainingSec: 0

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function formatTime(seconds) {
    var mins = Math.max(1, Math.ceil(seconds / 60))
    if (mins >= 60) {
      var h = Math.floor(mins / 60)
      var m = mins % 60
      return m > 0 ? h + "h " + m + "m" : h + "h"
    }
    return mins + "m"
  }

  function getTooltip() {
    if (!root.active) {
      return "Amphetamine: Inactive\n• Left-click: Stay awake indefinitely\n• Right-click: Presets (15m, 30m, 1h, 2h)"
    }
    if (root.mode === "indefinite") {
      return "Amphetamine: Active (Indefinite)\n• Lid-close & system sleep inhibited\n• Left-click: Deactivate\n• Right-click: Switch to timer"
    }
    return "Amphetamine: Active (" + formatTime(root.remainingSec) + " remaining)\n• Lid-close & system sleep inhibited\n• Left-click: Deactivate\n• Right-click: Next preset"
  }

  function updateRemaining() {
    if (root.active && root.mode === "timer" && root.expiresAt > 0) {
      var now = Math.floor(Date.now() / 1000)
      var diff = root.expiresAt - now
      root.remainingSec = Math.max(0, diff)
      if (diff <= 0) {
        resetState()
      }
    } else {
      root.remainingSec = 0
    }
  }

  function loadState(raw) {
    try {
      if (!raw || raw.trim() === "") {
        resetState()
        return
      }
      var data = JSON.parse(raw)
      root.active = !!data.active
      root.mode = data.mode || "off"
      root.label = data.label || "Off"
      root.expiresAt = Number(data.expiresAt) || 0
      updateRemaining()
    } catch (e) {
      resetState()
    }
  }

  function resetState() {
    root.active = false
    root.mode = "off"
    root.label = "Off"
    root.expiresAt = 0
    root.remainingSec = 0
  }

  FileView {
    id: stateFileView
    path: root.statePath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadState(text())
    onFileChanged: reload()
    onLoadFailed: root.resetState()
  }

  Timer {
    interval: 1000
    running: root.active && root.mode === "timer"
    repeat: true
    onTriggered: root.updateRemaining()
  }

  Process {
    id: toggleProc
    command: ["bash", "-c", root.binPath + " toggle"]
    onExited: stateFileView.reload()
  }

  Process {
    id: cycleProc
    command: ["bash", "-c", root.binPath + " cycle"]
    onExited: stateFileView.reload()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰛊"
    active: root.active
    tooltipText: root.getTooltip()
    onPressed: function(b) {
      if (b === Qt.RightButton) {
        cycleProc.running = true
      } else {
        toggleProc.running = true
      }
    }
  }

  Component.onCompleted: {
    stateFileView.reload()
  }
}
