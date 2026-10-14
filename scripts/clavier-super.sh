#!/usr/bin/env bash
# clavier-super.sh : rend Super+W (et les autres raccourcis Super) utilisables
# depuis le clavier virtuel wvkbd-fr.
#
#  1. ajoute une touche "Sup" sur les couches de lettres, a la place de "Cmp"
#     (les accents restent accessibles par appui long sur la lettre)
#  2. demande a Hyprland de lire les raccourcis du clavier virtuel d'apres la
#     lettre affichee. Sans ca, avec une disposition AZERTY, la touche "w" du
#     clavier virtuel compte comme "z" pour les raccourcis.
#
# Sauvegarde avant chaque modification. Teste sur une Surface Pro 6 (Omarchy, Hyprland 0.56.2), octobre 2026.
set -euo pipefail

SRC="$HOME/src/wvkbd-v0.20"
HYPR="$HOME/.config/hypr"
BIN="$HOME/.local/bin"
DEV="hl-virtual-keyboard-wvkbd-fr"
STAMP="$(date +%Y%m%d-%H%M%S)"

echo "==> Verifications"
[ -f "$SRC/layout.fr.h" ] || { echo "ERREUR : $SRC/layout.fr.h introuvable. Rien n'a ete modifie."; exit 1; }
[ -f "$HYPR/tablette.lua" ] || { echo "ERREUR : $HYPR/tablette.lua introuvable. Lance d'abord simplifier-tablette.sh."; exit 1; }
echo "    Disposition clavier de Hyprland : $(hyprctl getoption input:kb_layout 2>/dev/null | head -1)"

echo "==> 1/4 Touche Sup sur les couches de lettres"
cp "$SRC/layout.fr.h" "$SRC/layout.fr.h.bak-sup-$STAMP"
python3 - "$SRC/layout.fr.h" <<'EOF'
import sys
p = sys.argv[1]
s = open(p, encoding="utf-8").read()
CMP = '{"Cmp", "Cmp", 1.0, Compose, .scheme = 1},'
SUP = '{"Sup", "Sup", 1.0, Mod, Super, .scheme = 1},'
for name in ("keys_landscape", "keys_full"):
    marker = "static struct key %s[] = {" % name
    if s.count(marker) != 1:
        sys.exit("Bloc %s introuvable ou en double, rien modifie." % name)
    start = s.index(marker)
    end = s.index("\n};", start)
    block = s[start:end]
    if SUP in block:
        print("    %s : deja fait" % name)
        continue
    if block.count(CMP) != 1:
        sys.exit("Touche Cmp introuvable dans %s, rien modifie." % name)
    s = s[:start] + block.replace(CMP, SUP) + s[end:]
    print("    %s : OK" % name)
open(p, "w", encoding="utf-8").write(s)
EOF

echo "==> 2/4 Compilation et installation de wvkbd-fr"
make -C "$SRC" LAYOUT=fr clean >/dev/null
if ! make -C "$SRC" LAYOUT=fr wvkbd-fr >/dev/null 2>&1; then
  echo "ERREUR de compilation. Pour voir le message : make -C $SRC LAYOUT=fr wvkbd-fr"
  echo "Pour revenir en arriere : cp $SRC/layout.fr.h.bak-sup-$STAMP $SRC/layout.fr.h"
  exit 1
fi
pkill -x wvkbd-fr || true
sleep 1
install -Dm755 "$SRC/wvkbd-fr" "$BIN/wvkbd-fr"

echo "==> 3/4 Raccourcis du clavier virtuel lus d'apres la lettre affichee"
if grep -q "$DEV" "$HYPR/tablette.lua"; then
  echo "    deja fait"
else
  cp "$HYPR/tablette.lua" "$HYPR/tablette.lua.bak-sup-$STAMP"
  cat >> "$HYPR/tablette.lua" <<EOF

-- Clavier virtuel : les raccourcis (Super+W...) suivent la lettre affichee sur la touche.
-- Sans ca, avec une disposition AZERTY, la touche "w" du clavier virtuel compte comme "z".
hl.device({
  name = "$DEV",
  resolve_binds_by_sym = true,
})
EOF
  echo "    OK"
fi

echo "==> 4/4 Relance du clavier"
OPTS="--hidden -L 300"
if grep -q -- "--auto" "$HYPR/autostart.lua"; then OPTS="$OPTS --auto"; fi
# shellcheck disable=SC2086
nohup "$BIN/wvkbd-fr" $OPTS >/dev/null 2>&1 &
sleep 2
hyprctl reload >/dev/null
sleep 1
echo "--- Erreurs de config Hyprland (rien en dessous = aucune) :"
hyprctl configerrors
if hyprctl devices | grep -q "$DEV"; then
  echo "    Clavier virtuel reconnu : $DEV"
else
  echo "    ATTENTION : clavier virtuel $DEV introuvable. Noms vus :"
  hyprctl devices | grep -i "virtual-keyboard" || echo "    (aucun)"
fi

echo
echo "Termine. Test : affiche le clavier, touche une fenetre, puis Sup, puis w."
