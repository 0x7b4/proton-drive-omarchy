import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

// Widget de barre pour Proton Drive.
// S'appuie sur le CLI officiel `proton-drive` (proton.me/business/drive/cli).
// Statut détecté en interrogeant `proton-drive filesystem list /my-files --json` :
// exitCode 0 => connecté, exitCode != 0 => déconnecté / session expirée.
BarWidget {
  id: root
  moduleName: "io.github.0x7b4.proton-drive"

  // "unknown" | "checking" | "connected" | "disconnected" | "error"
  property string status: "unknown"
  property string lastError: ""

  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = button
    panelLoader.item.hostWidget = root
    panelLoader.item.widget = root
  }

  function refreshStatus() {
    if (statusProcess.running) return
    root.status = "checking"
    statusProcess.running = true
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()

  Component.onCompleted: refreshStatus()

  // Vérifie périodiquement la session (toutes les 5 minutes).
  Timer {
    interval: 5 * 60 * 1000
    running: true
    repeat: true
    onTriggered: root.refreshStatus()
  }

  Process {
    id: statusProcess
    command: ["proton-drive", "filesystem", "list", "/my-files", "--json"]
    stdout: StdioCollector {
      id: statusStdout
    }
    stderr: StdioCollector {
      id: statusStderr
    }
    onExited: function(exitCode) {
      if (exitCode === 0) {
        root.status = "connected"
        root.lastError = ""
      } else {
        root.status = "disconnected"
        root.lastError = statusStderr.text || ""
      }
    }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: {
      if (root.status === "connected") return "󰇙 Drive"
      if (root.status === "checking") return "󰇙 …"
      if (root.status === "disconnected") return "󰇙 !"
      return "󰇙 Drive"
    }
    tooltipText: {
      if (root.status === "connected") return "Proton Drive : connecté"
      if (root.status === "checking") return "Proton Drive : vérification…"
      if (root.status === "disconnected") return "Proton Drive : déconnecté (clic pour se connecter)"
      return "Proton Drive"
    }
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
    }
  }
}
