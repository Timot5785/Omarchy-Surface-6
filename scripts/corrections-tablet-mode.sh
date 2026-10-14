#!/usr/bin/env bash
# corrections-tablet-mode.sh : les deux corrections du plugin Tablet Mode pour la Surface (etape 2).
#
#  1. Le capteur de mode tablette est dans le Type Cover : sans correction, l'ecran
#     reste a l'horizontale quand le Type Cover est detache. Le plugin ignore donc
#     ce capteur pour ce modele (nom du modele ajoute a UNREPORTED_FOLD).
#  2. Le tactile passe par le peripherique virtuel d'iptsd : sans correction, l'ecran
#     tourne mais pas le tactile. Le plugin fait donc tourner ce peripherique aussi.
#
# Sans danger si relance. Sauvegarde de l'original dans omarchy-tablet-mode.bak.
# Teste sur une Surface Pro 6 (Tablet Mode 1.7.4, c6ba596), octobre 2026.
set -euo pipefail

F="$HOME/.config/omarchy/plugins/andreiyurik.tablet-mode/bin/omarchy-tablet-mode"
STATE="$HOME/.local/state/omarchy/tablet-mode"
TOUCH_DEFAUT="iptsd-virtual-touchscreen-045e:001f"

echo "==> Verifications"
[ -f "$F" ] || { echo "ERREUR : plugin Tablet Mode introuvable ($F). Rien n'a ete modifie."; exit 1; }
MODELE=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
[ -n "$MODELE" ] || { echo "ERREUR : nom du modele introuvable. Rien n'a ete modifie."; exit 1; }
echo "    modele : $MODELE"

# Nom de l'ecran tactile virtuel d'iptsd : lu s'il est la (noyau linux-surface demarre),
# sinon celui de la Surface Pro 6.
TOUCH=$(hyprctl devices 2>/dev/null | grep -o 'iptsd-virtual-touchscreen-[0-9a-fA-F:]*' | head -1 || true)
if [ -n "$TOUCH" ]; then
  echo "    ecran tactile : $TOUCH"
else
  TOUCH=$TOUCH_DEFAUT
  echo "    ecran tactile pas encore visible (noyau Surface pas encore demarre) : $TOUCH par defaut"
fi

[ -f "$F.bak" ] || cp "$F" "$F.bak"

echo "==> Corrections"
python3 - "$F" "$MODELE" "$TOUCH" <<'EOF'
import sys
p, modele, touch = sys.argv[1:4]
s = open(p, encoding="utf-8").read()

old1 = 'UNREPORTED_FOLD = ('
new1 = 'UNREPORTED_FOLD = ("%s", ' % modele
if new1 in s:
    print("    1. capteur du Type Cover ignore : deja fait")
elif s.count(old1) == 1:
    s = s.replace(old1, new1)
    print("    1. capteur du Type Cover ignore : OK")
else:
    sys.exit("    ERREUR : motif 1 introuvable, version du plugin differente. Rien n'a ete modifie.")

old2 = 'for touch in conf.get("touch", [])'
if old2 + ' + [' in s:
    print("    2. ecran tactile virtuel : deja fait")
elif s.count(old2) == 1:
    s = s.replace(old2, '%s + ["%s"]' % (old2, touch))
    print("    2. ecran tactile virtuel : OK")
else:
    sys.exit("    ERREUR : motif 2 introuvable, version du plugin differente. Rien n'a ete modifie.")

open(p, "w", encoding="utf-8").write(s)
EOF

echo "==> Relance du plugin (la barre le redemarre en 2 s)"
rm -f "$STATE/folded"
pkill -f "omarchy-tablet-mode daemon" || true
sleep 4
STATUS=$("$F" status 2>/dev/null || true)
echo "    $STATUS"
if printf '%s' "$STATUS" | grep -q '"hasFoldSensor": false'; then
  echo "    OK : le plugin suit l'accelerometre dans toutes les positions"
else
  echo "    ATTENTION : \"hasFoldSensor\" devrait etre false"
fi
