#!/usr/bin/env bash
# veille.sh : delais de mise en veille sur Omarchy.
#
#  1. Ecran verrouille : extinction apres 30 s sans activite.
#     - Avec le plugin Lock Screen Explorer (il remplace l'ecran de verrouillage
#       d'Omarchy) : son propre reglage, "omarchy-shell lock setBlankDelay".
#     - Sans lui : le delai est fixe dans un fichier d'Omarchy (5 s) ; le script
#       le modifie et installe un hook pacman qui refait la modification apres
#       chaque mise a jour d'Omarchy.
#  2. Session ouverte : verrouillage apres 2 min sans activite (reglage
#     "idle.lock" de ~/.config/omarchy/shell.json).
#
# Sauvegarde avant chaque modification. Teste sur une Surface Pro 6 (Omarchy, Hyprland 0.56.2), octobre 2026.
set -euo pipefail

OUVERT=120   # secondes avant verrouillage, session ouverte
VERROU=30    # secondes avant extinction, ecran verrouille

SHELLJSON="$HOME/.config/omarchy/shell.json"
LOCKEXPLORER="$HOME/.config/omarchy/plugins/io.github.sirjul1337.lock-explorer"
OMARCHY="${OMARCHY_PATH:-/usr/share/omarchy}"
LOCKQML="$OMARCHY/shell/plugins/lock/Service.qml"
IDLEQML="$OMARCHY/shell/plugins/services/idle/Service.qml"
HELPER=/usr/local/bin/omarchy-veille-verrou
HOOK=/etc/pacman.d/hooks/zz-omarchy-veille-verrou.hook
ORIG=/usr/local/share/omarchy-veille/Service.qml.orig
STAMP="$(date +%Y%m%d-%H%M%S)"

if [ -d "$LOCKEXPLORER" ] && grep -q '"io.github.sirjul1337.lock-explorer"' "$SHELLJSON" 2>/dev/null; then
  MODE=lock-explorer
else
  MODE=omarchy
fi

echo "==> Verifications (ecran de verrouillage : $MODE)"
[ -f "$SHELLJSON" ] || { echo "ERREUR : $SHELLJSON introuvable. Rien n'a ete modifie."; exit 1; }
if ! grep -q "idleConfig" "$IDLEQML" 2>/dev/null; then
  echo "ERREUR : ta version d'Omarchy ne gere pas la veille dans $IDLEQML. Rien n'a ete modifie."
  exit 1
fi
if [ "$MODE" = omarchy ]; then
  if ! grep -q "id: idleBlankTimer" "$LOCKQML" 2>/dev/null; then
    echo "ERREUR : minuterie d'extinction introuvable dans $LOCKQML. Rien n'a ete modifie."
    exit 1
  fi
  case "$LOCKQML" in
    /usr/*) ;;
    *) echo "ERREUR : Omarchy n'est pas installe dans /usr ($OMARCHY). Rien n'a ete modifie."; exit 1 ;;
  esac
fi
pgrep -x hypridle >/dev/null && echo "    ATTENTION : hypridle tourne aussi ; ses propres delais s'ajoutent a ceux-ci."
cp "$SHELLJSON" "$SHELLJSON.bak-veille-$STAMP"

echo "==> 1/2 Ecran verrouille : extinction apres $VERROU s"
if [ "$MODE" = lock-explorer ]; then
  REP=$(omarchy-shell lock setBlankDelay "${VERROU}000" 2>&1 || true)
  if [ "$REP" = "ok" ]; then
    echo "    OK : Lock Screen Explorer eteint l'ecran apres $VERROU s"
  else
    echo "    ATTENTION : reponse de Lock Screen Explorer : $REP"
  fi
  # Le shell vient de reecrire shell.json : on le laisse finir avant l'etape 2.
  sleep 2
else
  echo "    Delai actuel : $(sed -n '/id: idleBlankTimer/,/interval:/ s/.*interval: \([0-9]*\).*/\1/p' "$LOCKQML" | head -1) ms"
  sudo mkdir -p /usr/local/bin /usr/local/share/omarchy-veille /etc/pacman.d/hooks
  sudo test -f "$ORIG" || sudo cp "$LOCKQML" "$ORIG"
  sudo tee "$HELPER" >/dev/null <<EOF
#!/bin/sh
# Ecran verrouille d'Omarchy : extinction apres $VERROU s sans activite.
# Lance par le hook pacman $HOOK apres chaque mise a jour d'Omarchy.
F="$LOCKQML"
[ -f "\$F" ] || exit 0
sed -i '/id: idleBlankTimer/,/interval:/ s/interval: [0-9][0-9]*/interval: ${VERROU}000/' "\$F"
EOF
  sudo chmod 755 "$HELPER"
  sudo tee "$HOOK" >/dev/null <<EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Path
Target = ${LOCKQML#/}

[Action]
Description = Ecran verrouille d'Omarchy : extinction apres $VERROU s
When = PostTransaction
Exec = $HELPER
EOF
  sudo "$HELPER"
  NOUVEAU=$(sed -n '/id: idleBlankTimer/,/interval:/ s/.*interval: \([0-9]*\).*/\1/p' "$LOCKQML" | head -1)
  if [ "$NOUVEAU" = "${VERROU}000" ]; then
    echo "    OK : delai de l'ecran verrouille = $NOUVEAU ms"
  else
    echo "    ATTENTION : delai lu apres modification = '$NOUVEAU'"
  fi
fi

echo "==> 2/2 Session ouverte : verrouillage apres $OUVERT s"
python3 - "$SHELLJSON" "$OUVERT" <<'EOF'
import json, sys
p, ouvert = sys.argv[1], int(sys.argv[2])
data = json.load(open(p, encoding="utf-8"))
idle = data.get("idle")
if not isinstance(idle, dict):
    idle = {}
avant = dict(idle)
idle["lock"] = ouvert
data["idle"] = idle
open(p, "w", encoding="utf-8").write(json.dumps(data, indent=2) + "\n")
print("    avant : %s" % (avant or "valeurs par defaut (economiseur 150 s, verrouillage 300 s)"))
print("    apres : %s" % idle)
eco = idle.get("screensaver", 150)
if isinstance(eco, (int, float)) and eco >= ouvert:
    print("    (l'economiseur d'ecran, prevu a %s s, n'apparaitra plus : le verrouillage vient avant)" % eco)
EOF

echo "==> Relance de la barre et de l'ecran de verrouillage"
omarchy restart shell >/dev/null 2>&1 || echo "    Relance a la main : omarchy restart shell"

echo
echo "Termine. Pour annuler :"
echo "  cp $SHELLJSON.bak-veille-$STAMP $SHELLJSON && omarchy restart shell"
if [ "$MODE" = omarchy ]; then
  echo "  sudo rm $HOOK $HELPER && sudo cp $ORIG $LOCKQML && omarchy restart shell"
fi
