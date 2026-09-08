# Proton Drive (plugin Omarchy)

Widget de barre + panneau pour piloter [Proton Drive CLI](https://proton.me/support/drive-cli)
(officiel, binaire unique) directement depuis Omarchy (Quattro / Quickshell).

- Affiche l'état de connexion dans la barre (connecté / déconnecté).
- Panneau au clic : connexion, rafraîchissement, listing du dossier distant,
  envoi de `~/ProtonDrive/upload`, récupération vers `~/ProtonDrive/download`.

## Prérequis

1. Installer le CLI officiel Proton Drive (binaire statique) :
   <https://proton.me/download/drive/cli/index.html>
   ```sh
   chmod +x proton-drive
   sudo mv proton-drive /usr/local/bin/proton-drive
   ```
2. Vérifier qu'il est bien dans le `PATH` du shell Omarchy :
   ```sh
   proton-drive --help
   ```
3. La session est stockée via `libsecret` (trousseau du bureau) — aucun mot
   de passe ne transite par ce plugin.

## Installation du plugin

```sh
omarchy plugin add https://github.com/0x7b4/proton-drive-omarchy.git --enable
```

Ou en local, pour développer/tester :

```sh
mkdir -p ~/.config/omarchy/plugins
cp -r plugin ~/.config/omarchy/plugins/io.github.0x7b4.proton-drive
omarchy plugin validate ~/.config/omarchy/plugins/io.github.0x7b4.proton-drive
omarchy-shell shell rescanPlugins
```

## Configuration

Édite `Panel.qml` pour changer :
- `remotePath` : dossier distant ciblé (par défaut `/my-files/Omarchy`)
- `uploadDir` / `downloadDir` : dossiers locaux synchronisés

## Déplacer le widget

```sh
omarchy bar move io.github.0x7b4.proton-drive --section right
```

## Désinstaller

```sh
omarchy plugin remove io.github.0x7b4.proton-drive
```

## Notes / limites connues

- Les commandes utilisées ici correspondent aux commandes documentées du CLI officiel `proton-drive`
  (`auth login`, `filesystem list/upload/download`). Le CLI évolue vite
  (partage de liens, albums, multi-comptes annoncés) — vérifie
  `proton-drive --help` si tu veux étendre le plugin (ex. `auth logout`,
  `auth status`) et adapte les `Process` en conséquence.
- Le check de statut appelle `filesystem list /my-files --json` : un code de
  sortie non nul est interprété comme "déconnecté", ce qui couvre aussi une
  éventuelle erreur réseau — à affiner si besoin.
- Plugin non sandboxé : relis le code avant de l'activer (comme tout plugin
  Omarchy tiers).
