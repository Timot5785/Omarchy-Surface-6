#!/usr/bin/env bash
# Cree un widget de barre Omarchy qui affiche/cache le clavier virtuel wvkbd.
# Calque sur le widget "omaplug" (BarWidget + BarIconButton). Teste sur une Surface Pro 6 (Omarchy, Hyprland 0.56.2), octobre 2026.
# Le bouton lance wvkbd s'il ne tourne pas, sinon il bascule son affichage.
set -euo pipefail

DIR="$HOME/.config/omarchy/plugins/tim.wvkbd-toggle"
mkdir -p "$DIR"

cat > "$DIR/manifest.json" <<'EOF'
{
  "schemaVersion": 1,
  "id": "tim.wvkbd-toggle",
  "name": "Clavier virtuel (wvkbd)",
  "version": "0.1.0",
  "author": "tim",
  "license": "MIT",
  "description": "Bouton de barre pour afficher ou cacher le clavier virtuel wvkbd",
  "kinds": [
    "bar-widget"
  ],
  "entryPoints": {
    "barWidget": "Widget.qml"
  },
  "barWidget": {
    "displayName": "Clavier virtuel",
    "description": "Affiche ou cache le clavier virtuel wvkbd",
    "category": "Input",
    "defaultSection": "right",
    "allowMultiple": false
  }
}
EOF

cat > "$DIR/Widget.qml" <<'EOF'
import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

BarWidget {
    id: root
    moduleName: "wvkbd-toggle"

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: "\uf11c"
        tooltipText: "Clavier virtuel"

        onPressed: function(b) {
            if (b === Qt.LeftButton) {
                // -L 300 = hauteur du clavier en paysage (a ajuster)
                Quickshell.execDetached(["sh", "-c",
                    "if pgrep -x wvkbd-mobintl >/dev/null; then pkill -RTMIN -x wvkbd-mobintl; else wvkbd-mobintl -L 300 & fi"])
            }
        }
    }
}
EOF

echo "Widget cree dans: $DIR"
echo
echo "Etapes suivantes:"
echo "  1. omarchy restart shell"
echo "  2. Active 'Clavier virtuel' avec le Plugin Manager (icone omaplug dans la barre)"
echo "  3. Si rien n'apparait: qs log -f -p /usr/share/omarchy/shell"
