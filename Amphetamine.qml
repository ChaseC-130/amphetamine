import QtQuick
import QtQuick.Layouts
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
  readonly property string configPath: stateDir + "/config.json"
  readonly property string binPath: {
    var url = Qt.resolvedUrl("bin/amphetamine").toString()
    return url.replace(/^file:\/\//, "")
  }

  property bool active: false
  property string mode: "off"
  property string label: "Off"
  property double expiresAt: 0
  property int remainingSec: 0
  property bool panelOpened: false

  // Configuration properties
  property bool allowDisplaySleep: false
  property bool turnOffDisplayOnLidClose: true
  property string selectedDuration: "indefinite"

  visible: true
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function open() { panelOpened = true }
  function close() { panelOpened = false }
  function togglePanel() { panelOpened = !panelOpened }

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
      return "Amphetamine: Inactive\n• Left-click: Open Menu\n• Right-click: Quick Cycle Presets"
    }
    if (root.mode === "indefinite") {
      return "Amphetamine: Active (Indefinite)\n• Lid-close & system sleep inhibited\n• Left-click: Open Menu\n• Right-click: Quick Cycle"
    }
    return "Amphetamine: Active (" + formatTime(root.remainingSec) + " remaining)\n• Lid-close & system sleep inhibited\n• Left-click: Open Menu"
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

  function loadConfig(raw) {
    try {
      if (!raw || raw.trim() === "") return
      var data = JSON.parse(raw)
      if (data.allowDisplaySleep !== undefined)
        root.allowDisplaySleep = !!data.allowDisplaySleep
      if (data.turnOffDisplayOnLidClose !== undefined)
        root.turnOffDisplayOnLidClose = !!data.turnOffDisplayOnLidClose
      if (data.defaultDuration)
        root.selectedDuration = data.defaultDuration
    } catch (e) {
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

  FileView {
    id: configFileView
    path: root.configPath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadConfig(text())
    onFileChanged: reload()
  }

  Timer {
    interval: 1000
    running: root.active && root.mode === "timer"
    repeat: true
    onTriggered: root.updateRemaining()
  }

  Process {
    id: startProc
    command: ["bash", "-c", root.binPath + " on " + root.selectedDuration]
    onExited: stateFileView.reload()
  }

  Process {
    id: stopProc
    command: ["bash", "-c", root.binPath + " off"]
    onExited: stateFileView.reload()
  }

  Process {
    id: cycleProc
    command: ["bash", "-c", root.binPath + " cycle"]
    onExited: stateFileView.reload()
  }

  Process {
    id: setConfigProc
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
        root.togglePanel()
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.panelOpened
    contentWidth: Style.space(340)
    contentHeight: panelColumn.implicitHeight + Style.spacing.popupPadding * 2
    focusTarget: panelColumn

    Column {
      id: panelColumn
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: Style.space(12)

      // Header row
      Row {
        width: parent.width
        spacing: Style.space(10)

        Text {
          text: "󰛊"
          font.family: Style.font.family
          font.pixelSize: Style.font.heading
          color: root.active ? Color.accent : Color.foreground
          anchors.verticalCenter: parent.verticalCenter
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)

          Text {
            text: "Amphetamine"
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
            color: Color.foreground
          }

          Text {
            text: root.active
              ? (root.mode === "timer" ? "Active (" + root.formatTime(root.remainingSec) + " left)" : "Active (Indefinite)")
              : "System Sleep Allowed"
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            color: root.active ? Color.accent : Qt.darker(Color.foreground, 1.4)
          }
        }
      }

      PanelSeparator {
        width: parent.width
      }

      // Session Duration section
      PanelSectionHeader {
        text: "SESSION DURATION"
      }

      Dropdown {
        id: durationDropdown
        width: parent.width
        label: "Duration"
        value: root.selectedDuration
        options: [
          { value: "indefinite", label: "Indefinite" },
          { value: "15m", label: "15 Minutes" },
          { value: "30m", label: "30 Minutes" },
          { value: "1h", label: "1 Hour" },
          { value: "2h", label: "2 Hours" },
          { value: "4h", label: "4 Hours" },
          { value: "8h", label: "8 Hours" }
        ]
        onChanged: function(val) {
          root.selectedDuration = val
          setConfigProc.command = ["bash", "-c", root.binPath + " config set defaultDuration " + val]
          setConfigProc.running = true
        }
      }

      Button {
        width: parent.width
        text: root.active ? "End Active Session" : "Start Keep-Awake Session"
        iconText: root.active ? "󰅙" : "󰐊"
        accent: root.active ? Color.urgent : Color.accent
        bordered: true
        onClicked: {
          if (root.active) {
            stopProc.running = true
          } else {
            startProc.running = true
          }
        }
      }

      PanelSeparator {
        width: parent.width
      }

      // Preferences / Toggles section
      PanelSectionHeader {
        text: "LID & DISPLAY PREFERENCES"
      }

      Toggle {
        width: parent.width
        label: "Display Sleep on Lid Close"
        description: "Turn off screen on lid close (saves battery & heat)"
        checked: root.turnOffDisplayOnLidClose
        onClicked: {
          root.turnOffDisplayOnLidClose = !root.turnOffDisplayOnLidClose
          setConfigProc.command = ["bash", "-c", root.binPath + " config set turnOffDisplayOnLidClose " + root.turnOffDisplayOnLidClose]
          setConfigProc.running = true
        }
      }

      Toggle {
        width: parent.width
        label: "Keep Screen Awake"
        description: "Prevent screensaver & idle lock while active"
        checked: !root.allowDisplaySleep
        onClicked: {
          root.allowDisplaySleep = !root.allowDisplaySleep
          setConfigProc.command = ["bash", "-c", root.binPath + " config set allowDisplaySleep " + root.allowDisplaySleep]
          setConfigProc.running = true
        }
      }

      PanelSeparator {
        width: parent.width
      }

      // Quick Agent Tip
      Row {
        width: parent.width
        spacing: Style.space(6)

        Text {
          text: "󱐋"
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          color: Color.accent
        }

        Text {
          text: "Run 'amphetamine run <cmd>' to keep awake for agents."
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          color: Qt.darker(Color.foreground, 1.3)
          elide: Text.ElideRight
          width: parent.width - Style.space(24)
        }
      }
    }
  }

  Component.onCompleted: {
    stateFileView.reload()
    configFileView.reload()
  }
}
