#!/usr/bin/env bash
# Cree un widget de barre Omarchy qui ferme la fenetre active (equivalent tactile de Super+W).
# Calque sur le widget "tim.wvkbd-toggle". Teste sur une Surface Pro 6 (Omarchy, Hyprland 0.56.2), octobre 2026.
# A lancer seulement apres avoir verifie que cette commande ferme bien une fenetre:
#   hyprctl dispatch 'hl.dsp.window.close()'
set -euo pipefail

DIR="$HOME/.config/omarchy/plugins/tim.close-window"
mkdir -p "$DIR"

cat > "$DIR/manifest.json" <<'EOF'
{
  "schemaVersion": 1,
  "id": "tim.close-window",
  "name": "Fermer la fenetre",
  "version": "0.1.0",
  "author": "tim",
  "license": "MIT",
  "description": "Bouton de barre pour fermer la fenetre active au toucher",
  "kinds": [
    "bar-widget"
  ],
  "entryPoints": {
    "barWidget": "Widget.qml"
  },
  "barWidget": {
    "displayName": "Fermer la fenetre",
    "description": "Ferme la fenetre active (comme Super+W)",
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
    moduleName: "close-window"

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: "\uf00d"
        tooltipText: "Fermer la fenetre"

        onPressed: function(b) {
            if (b === Qt.LeftButton) {
                // Demande de fermeture "propre": l'application peut proposer d'enregistrer
                Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.close()"])
            }
        }
    }
}
EOF

echo "Widget cree dans: $DIR"
echo
echo "Etapes suivantes:"
echo "  1. omarchy restart shell"
echo "  2. Active 'Fermer la fenetre' avec le Plugin Manager (icone omaplug dans la barre)"
echo "  3. Si rien n'apparait: qs log -f -p /usr/share/omarchy/shell"
