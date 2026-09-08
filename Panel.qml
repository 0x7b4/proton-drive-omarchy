import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Panneau ouvert au clic sur le widget de barre.
// Toutes les actions passent par le CLI officiel `proton-drive`.
// Dossiers locaux synchronisés : ~/ProtonDrive/upload et ~/ProtonDrive/download
// (créés automatiquement s'ils n'existent pas). Adapte remotePath si besoin.
Panel {
  id: root
  moduleName: "io.github.0x7b4.proton-drive"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var widget: null

  property string remotePath: "/my-files/Omarchy"
  property string uploadDir:
    StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/ProtonDrive/upload"
  property string downloadDir:
    StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/ProtonDrive/download"

  property string listing: ""
  property bool busy: false
  property string lastActionMessage: ""

  function open() { root.controller.show() }
  function close() { root.controller.hide() }
  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  function runAction(process, message) {
    if (root.busy) return
    root.busy = true
    root.lastActionMessage = message
    process.running = true
  }

  function login() {
    runAction(loginProcess, "Ouverture du navigateur pour la connexion…")
  }

  function refreshListing() {
    runAction(listProcess, "Rafraîchissement de la liste…")
  }

  function uploadFolder() {
    runAction(uploadProcess, "Envoi de " + uploadDir + " vers " + remotePath + "…")
  }

  function downloadFolder() {
    runAction(downloadProcess, "Récupération de " + remotePath + " vers " + downloadDir + "…")
  }

  // proton-drive auth login (ouvre le navigateur, écrit la session dans le
  // trousseau système — libsecret sur Linux). Aucune saisie de mot de passe ici.
  Process {
    id: loginProcess
    command: ["proton-drive", "auth", "login"]
    onExited: function(exitCode) {
      root.busy = false
      root.lastActionMessage = exitCode === 0
        ? "Connecté."
        : "Échec de la connexion (code " + exitCode + ")."
      if (root.widget) root.widget.refreshStatus()
    }
  }

  Process {
    id: listProcess
    command: ["proton-drive", "filesystem", "list", root.remotePath]
    stdout: StdioCollector {
      id: listStdout
      onStreamFinished: root.listing = text
    }
    onExited: function(exitCode) {
      root.busy = false
      root.lastActionMessage = exitCode === 0
        ? "Liste à jour."
        : "Impossible de lister " + root.remotePath + " (code " + exitCode + ")."
      if (root.widget) root.widget.refreshStatus()
    }
  }

  // Crée le dossier local puis envoie son contenu, sans écraser les fichiers
  // distants existants (conflict-strategy skip).
  Process {
    id: uploadProcess
    command: ["sh", "-c",
      "mkdir -p '" + root.uploadDir + "' && " +
      "find '" + root.uploadDir + "' -mindepth 1 -maxdepth 1 -print0 | " +
      "xargs -0 -r proton-drive filesystem upload " +
      "--folder-conflict-strategy merge --file-conflict-strategy skip " +
      "'" + root.remotePath + "'"
    ]
    onExited: function(exitCode) {
      root.busy = false
      root.lastActionMessage = exitCode === 0
        ? "Envoi terminé."
        : "Échec de l'envoi (code " + exitCode + ")."
      root.refreshListing()
    }
  }

  Process {
    id: downloadProcess
    command: ["sh", "-c",
      "mkdir -p '" + root.downloadDir + "' && " +
      "proton-drive filesystem download '" + root.remotePath + "' '" + root.downloadDir + "'"
    ]
    onExited: function(exitCode) {
      root.busy = false
      root.lastActionMessage = exitCode === 0
        ? "Téléchargement terminé dans " + root.downloadDir + "."
        : "Échec du téléchargement (code " + exitCode + ")."
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(10)

        Text {
          width: parent.width
          text: "Proton Drive"
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.subtitle
          font.bold: true
        }

        Text {
          width: parent.width
          text: root.lastActionMessage || "Chemin distant : " + root.remotePath
          color: root.barForeground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          wrapMode: Text.WordWrap
        }

        Row {
          spacing: Style.space(8)

          Rectangle {
            width: loginLabel.implicitWidth + Style.space(16)
            height: Style.space(28)
            radius: Style.space(6)
            color: Style.color.surfaceHover
            Text {
              id: loginLabel
              anchors.centerIn: parent
              text: "Se connecter"
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
            }
            MouseArea {
              anchors.fill: parent
              enabled: !root.busy
              onClicked: root.login()
            }
          }

          Rectangle {
            width: refreshLabel.implicitWidth + Style.space(16)
            height: Style.space(28)
            radius: Style.space(6)
            color: Style.color.surfaceHover
            Text {
              id: refreshLabel
              anchors.centerIn: parent
              text: "Rafraîchir"
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
            }
            MouseArea {
              anchors.fill: parent
              enabled: !root.busy
              onClicked: root.refreshListing()
            }
          }
        }

        Row {
          spacing: Style.space(8)

          Rectangle {
            width: uploadLabel.implicitWidth + Style.space(16)
            height: Style.space(28)
            radius: Style.space(6)
            color: Style.color.surfaceHover
            Text {
              id: uploadLabel
              anchors.centerIn: parent
              text: "Envoyer ~/ProtonDrive/upload"
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
            }
            MouseArea {
              anchors.fill: parent
              enabled: !root.busy
              onClicked: root.uploadFolder()
            }
          }

          Rectangle {
            width: downloadLabel.implicitWidth + Style.space(16)
            height: Style.space(28)
            radius: Style.space(6)
            color: Style.color.surfaceHover
            Text {
              id: downloadLabel
              anchors.centerIn: parent
              text: "Récupérer vers ~/ProtonDrive/download"
              color: root.barForeground
              font.family: root.bar ? root.bar.fontFamily : Style.font.family
            }
            MouseArea {
              anchors.fill: parent
              enabled: !root.busy
              onClicked: root.downloadFolder()
            }
          }
        }

        Text {
          width: parent.width
          visible: root.listing.length > 0
          text: root.listing
          color: root.barForeground
          font.family: "monospace"
          font.pixelSize: Style.font.small
          wrapMode: Text.WordWrap
        }
      }
    }
  }
}
