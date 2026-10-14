#!/usr/bin/env bash
# simplifier-tablette.sh : version simplifiee pour la Surface Pro 6 sous Omarchy.
#
#  - un seul clavier virtuel : wvkbd-fr (AZERTY), lance cache au demarrage
#  - le clavier s'affiche tout seul sur l'ecran de verrouillage
#  - le bouton clavier de la barre pilote wvkbd-fr
#  - la config "Tablet Experience" n'est plus chargee (son fichier est garde)
#
# Chaque fichier modifie est sauvegarde avant. Teste sur une Surface Pro 6 (Omarchy, Hyprland 0.56.2), octobre 2026.
#
# Option : AUTO=1 bash simplifier-tablette.sh
#   -> le clavier s'affiche aussi tout seul quand tu touches un champ de texte
#      (attention : aussi quand le Type Cover est branche).
set -euo pipefail

HYPR="$HOME/.config/hypr"
BIN="$HOME/.local/bin"
WIDGET="$HOME/.config/omarchy/plugins/tim.wvkbd-toggle/Widget.qml"
BK="$HYPR/sauvegarde-$(date +%Y%m%d-%H%M%S)"
KBD_OPTS="--hidden -L 300"
if [ "${AUTO:-0}" = "1" ]; then KBD_OPTS="$KBD_OPTS --auto"; fi

echo "==> Verifications"
if [ ! -x "$BIN/wvkbd-fr" ]; then
  if [ -x "$HOME/src/wvkbd-v0.20/wvkbd-fr" ]; then
    install -Dm755 "$HOME/src/wvkbd-v0.20/wvkbd-fr" "$BIN/wvkbd-fr"
    echo "    wvkbd-fr copie dans $BIN"
  else
    echo "ERREUR : wvkbd-fr introuvable (ni dans $BIN ni dans ~/src/wvkbd-v0.20). Rien n'a ete modifie."
    exit 1
  fi
fi
for f in "$HYPR/hyprland.lua" "$HYPR/autostart.lua"; do
  [ -f "$f" ] || { echo "ERREUR : $f introuvable. Rien n'a ete modifie."; exit 1; }
done

echo "==> Sauvegarde dans $BK"
mkdir -p "$BK"
cp "$HYPR/hyprland.lua" "$HYPR/autostart.lua" "$BK/"
if [ -f "$WIDGET" ]; then cp "$WIDGET" "$BK/Widget.qml.wvkbd-toggle"; fi

echo "==> 1/5 Script qui affiche le clavier au verrouillage ($BIN/wvkbd-verrou)"
mkdir -p "$BIN"
cat > "$BIN/wvkbd-verrou" <<'EOF'
#!/bin/sh
# Affiche le clavier virtuel (wvkbd-fr) quand l'ecran se verrouille,
# et le cache au deverrouillage. Verifie l'etat une fois par seconde.
# wvkbd : SIGUSR2 = afficher, SIGUSR1 = cacher.
prev=false
while sleep 1; do
  now=$(hyprctl locked 2>/dev/null) || continue
  [ "$now" = "$prev" ] && continue
  if [ "$now" = "true" ]; then
    pkill -USR2 -x wvkbd-fr
  else
    pkill -USR1 -x wvkbd-fr
  fi
  prev=$now
done
EOF
chmod +x "$BIN/wvkbd-verrou"

echo "==> 2/5 Regles tablette pour Hyprland ($HYPR/tablette.lua)"
cat > "$HYPR/tablette.lua" <<'EOF'
-- Tablette (Surface) : les deux regles utiles reprises de tablet-experience.lua.

-- Balayage depuis le bord gauche ou droit de l'ecran tactile pour changer de bureau.
hl.config({
  gestures = {
    workspace_swipe_touch = true,
    workspace_swipe_touch_invert = false,
  },
})

-- Clavier virtuel wvkbd visible et utilisable par-dessus l'ecran de verrouillage.
hl.layer_rule({
  match = { namespace = "wvkbd" },
  above_lock = 2,
})
EOF

echo "==> 3/5 hyprland.lua : charger tablette.lua au lieu de tablet-experience.lua"
python3 - "$HYPR/hyprland.lua" <<'EOF'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
old = 'require("hypr.tablet-experience")'
new = 'require("hypr.tablette")'
if old in s:
    open(p, "w", encoding="utf-8").write(s.replace(old, new))
    print("    OK")
elif new in s:
    print("    deja fait")
else:
    open(p, "a", encoding="utf-8").write("\n" + new + "\n")
    print("    ligne ajoutee a la fin")
EOF

echo "==> 4/5 autostart.lua : un seul clavier + surveillance du verrouillage"
python3 - "$HYPR/autostart.lua" "$KBD_OPTS" <<'EOF'
import sys
p, opts = sys.argv[1], sys.argv[2]
lines = open(p, encoding="utf-8").read().splitlines()
# On retire les anciens lancements (texp-touch, wvkbd-mobintl, une ancienne version de ces lignes).
kept = [l for l in lines
        if not (l.strip().startswith("o.launch_on_start")
                and ("texp-touch" in l or "wvkbd" in l))]
kept += [
    'o.launch_on_start(os.getenv("HOME") .. "/.local/bin/wvkbd-fr %s")' % opts,
    'o.launch_on_start(os.getenv("HOME") .. "/.local/bin/wvkbd-verrou")',
]
open(p, "w", encoding="utf-8").write("\n".join(kept) + "\n")
print("    OK")
EOF

echo "==> 5/5 Bouton clavier de la barre : piloter wvkbd-fr"
if [ -f "$WIDGET" ]; then
  sed -i 's/wvkbd-mobintl/wvkbd-fr/g' "$WIDGET"
  if grep -q "wvkbd-fr" "$WIDGET"; then echo "    OK"; else echo "    ATTENTION : wvkbd-fr absent du widget"; fi
else
  echo "    widget tim.wvkbd-toggle absent : relance install-wvkbd-widget.sh"
fi

echo "==> Application immediate"
pkill -x wvkbd-mobintl || true
pkill -x wvkbd-fr || true
pkill -f "$BIN/wvkbd-verrou" || true
hyprctl reload >/dev/null
sleep 2
# shellcheck disable=SC2086
pgrep -x wvkbd-fr >/dev/null || nohup "$BIN/wvkbd-fr" $KBD_OPTS >/dev/null 2>&1 &
pgrep -f "$BIN/wvkbd-verrou" >/dev/null || nohup "$BIN/wvkbd-verrou" >/dev/null 2>&1 &
sleep 1
echo "--- Erreurs de config Hyprland (rien en dessous = aucune) :"
hyprctl configerrors
omarchy restart shell >/dev/null 2>&1 || echo "    Relance la barre a la main : omarchy restart shell"

echo
echo "Termine. Sauvegarde : $BK"
echo "Pour tout annuler :"
echo "  cp $BK/hyprland.lua $BK/autostart.lua $HYPR/ && hyprctl reload"
