#!/usr/bin/env bash
# demarrage-surface.sh : deux reglages de demarrage pour la Surface.
#
#  1. Limine retient le dernier noyau demarre (remember_last_entry: yes).
#     Choisis linux-surface une fois dans le menu : il sera ensuite le choix par defaut.
#  2. Le clavier virtuel est lance et surveille par un seul programme, wvkbd-verrou :
#     il attend que le clavier soit pret avant de lui envoyer un signal, reessaie
#     tant que ce n'est pas fait, et relance le clavier s'il s'arrete. Le clavier
#     doit ainsi apparaitre aussi sur l'ecran de verrouillage juste apres le demarrage.
#
# Sauvegarde avant chaque modification. Teste sur une Surface Pro 6 (Omarchy, Hyprland 0.56.2), octobre 2026.
set -euo pipefail

HYPR="$HOME/.config/hypr"
BIN="$HOME/.local/bin"
LC=/boot/limine.conf
STAMP="$(date +%Y%m%d-%H%M%S)"

echo "==> Verifications"
[ -x "$BIN/wvkbd-fr" ] || { echo "ERREUR : $BIN/wvkbd-fr introuvable. Rien n'a ete modifie."; exit 1; }
[ -f "$HYPR/autostart.lua" ] || { echo "ERREUR : $HYPR/autostart.lua introuvable. Rien n'a ete modifie."; exit 1; }
sudo test -f "$LC" || { echo "ERREUR : $LC introuvable. Rien n'a ete modifie."; exit 1; }

echo "==> 1/4 Limine : retenir le dernier noyau demarre"
sudo cp "$LC" "$LC.avant-surface-$STAMP"
if sudo grep -q "^remember_last_entry:" "$LC"; then
  sudo sed -i 's/^remember_last_entry:.*/remember_last_entry: yes/' "$LC"
else
  sudo sed -i '1i remember_last_entry: yes' "$LC"
fi
echo "    Regeneration des entrees (limine-update), patiente..."
if sudo limine-update >"/tmp/limine-update-$STAMP.log" 2>&1; then
  echo "    limine-update : OK"
else
  echo "    ATTENTION : limine-update a signale une erreur (journal : /tmp/limine-update-$STAMP.log)"
fi
if sudo grep -q "^remember_last_entry: yes" "$LC"; then
  echo "    OK : la ligne est toujours la apres limine-update"
else
  echo "    ATTENTION : limine-update a retire la ligne. Sauvegarde : $LC.avant-surface-$STAMP"
fi

echo "==> 2/4 Nouveau wvkbd-verrou (lance et surveille le clavier)"
[ -f "$BIN/wvkbd-verrou" ] && cp "$BIN/wvkbd-verrou" "$BIN/wvkbd-verrou.bak-$STAMP"
cat > "$BIN/wvkbd-verrou" <<'EOF'
#!/bin/sh
# Lance le clavier virtuel wvkbd-fr et le surveille :
#  - il s'affiche quand l'ecran se verrouille, et se cache au deverrouillage ;
#  - s'il s'arrete, il est relance.
# Les options recues (ex. --hidden -L 300) sont passees au clavier.
# wvkbd : SIGUSR2 = afficher, SIGUSR1 = cacher. Un signal recu avant que le
# clavier soit pret l'arreterait : on attend 3 s apres chaque lancement, et
# on ne note un changement d'etat qu'une fois le signal bien envoye.
KBD="$HOME/.local/bin/wvkbd-fr"
[ $# -gt 0 ] || set -- --hidden -L 300
prev=inconnu
while :; do
  if ! pgrep -x wvkbd-fr >/dev/null; then
    "$KBD" "$@" >/dev/null 2>&1 &
    sleep 3
    prev=inconnu
  fi
  if now=$(hyprctl locked 2>/dev/null) && [ "$now" != "$prev" ]; then
    if [ "$now" = "true" ]; then sig=USR2; else sig=USR1; fi
    if pkill -"$sig" -x wvkbd-fr; then prev=$now; fi
  fi
  sleep 1
done
EOF
chmod +x "$BIN/wvkbd-verrou"

echo "==> 3/4 autostart.lua : un seul lancement (wvkbd-verrou lance le clavier)"
cp "$HYPR/autostart.lua" "$HYPR/autostart.lua.bak-$STAMP"
python3 - "$HYPR/autostart.lua" <<'EOF'
import re, sys
p = sys.argv[1]
lines = open(p, encoding="utf-8").read().splitlines()
# Options du clavier : celles d'une ligne wvkbd-verrou deja la (script relance),
# sinon celles de la ligne wvkbd-fr ecrite par simplifier-tablette.sh.
opts_verrou = opts_fr = None
for l in lines:
    if not l.strip().startswith("o.launch_on_start"):
        continue
    m = re.search(r'wvkbd-verrou ([^"]+)"', l)
    if m:
        opts_verrou = m.group(1).strip()
    m = re.search(r'wvkbd-fr ([^"]+)"', l)
    if m:
        opts_fr = m.group(1).strip()
opts = opts_verrou or opts_fr or "--hidden -L 300"
kept = [l for l in lines if not (l.strip().startswith("o.launch_on_start") and "wvkbd" in l)]
kept.append('o.launch_on_start(os.getenv("HOME") .. "/.local/bin/wvkbd-verrou %s")' % opts)
open(p, "w", encoding="utf-8").write("\n".join(kept) + "\n")
print("    OK (options du clavier : %s)" % opts)
EOF

echo "==> 4/4 Relance de la surveillance"
OPTS=$(sed -n 's|.*wvkbd-verrou \([^"]*\)").*|\1|p' "$HYPR/autostart.lua" | tail -1)
pkill -f "$BIN/wvkbd-verrou" || true
sleep 1
# shellcheck disable=SC2086
nohup "$BIN/wvkbd-verrou" $OPTS >/dev/null 2>&1 &
sleep 4
if pgrep -f "$BIN/wvkbd-verrou" >/dev/null && pgrep -x wvkbd-fr >/dev/null; then
  echo "    OK : wvkbd-verrou et wvkbd-fr tournent"
else
  echo "    ATTENTION : verifie avec  pgrep -af \"wvkbd\""
fi

echo
echo "Termine. Au prochain demarrage, choisis linux-surface une fois dans le menu Limine :"
echo "il sera ensuite choisi tout seul."
echo "Pour annuler Limine : sudo cp $LC.avant-surface-$STAMP $LC"
echo "Pour annuler le clavier : cp $HYPR/autostart.lua.bak-$STAMP $HYPR/autostart.lua"
