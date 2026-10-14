#!/usr/bin/env bash
# rotation-ecran-externe.sh : empeche hyprmoncfgd (plugin "hyprmoncfg") de remettre
# l'ecran de la tablette a l'horizontale quand un ecran externe est branche.
#
# hyprmoncfgd verifie l'etat des ecrans toutes les 5 secondes. Quand la rotation
# change, il reapplique son profil (ecran de la tablette a l'horizontale) et
# recharge Hyprland ; le plugin de rotation retourne l'ecran, et ainsi de suite.
# On espace cette verification a 24 h. hyprmoncfgd continue de reagir tout de
# suite quand un ecran est branche ou debranche, ou quand le couvercle change.
#
# Ne touche pas aux fichiers de hyprmoncfg : ajoute un petit fichier de reglage
# systemd, a supprimer pour revenir en arriere.
# Teste sur une Surface Pro 6 (Omarchy 4.0.4, Hyprland 0.56.2), octobre 2026.
set -euo pipefail

UNIT=hyprmoncfgd.service
DIR="$HOME/.config/systemd/user/$UNIT.d"
DROPIN="$DIR/rotation-tablette.conf"
INTERVALLE=24h

echo "==> Verifications"
BIN=$(command -v hyprmoncfgd) || { echo "ERREUR : hyprmoncfgd introuvable. Rien n'a ete modifie."; exit 1; }
if ! systemctl --user cat "$UNIT" >/dev/null 2>&1; then
  echo "ERREUR : service $UNIT introuvable. Rien n'a ete modifie."
  exit 1
fi
if ! "$BIN" --help 2>&1 | grep -q -- "--poll-interval"; then
  echo "ERREUR : cette version de hyprmoncfgd n'a pas l'option --poll-interval. Rien n'a ete modifie."
  exit 1
fi

# Commande de lancement actuelle du service, sans une ancienne valeur de
# --poll-interval (si le script est relance).
ARGV=$(systemctl --user show -p ExecStart --value "$UNIT" | sed -n 's/.*argv\[\]=\([^;]*\) ;.*/\1/p' | head -1)
ARGV=$(printf '%s\n' "${ARGV:-$BIN}" | sed -E 's/ --poll-interval[ =][^ ]+//g; s/[[:space:]]+$//')
echo "    lancement actuel : $ARGV"

echo "==> 1/2 Verification des ecrans toutes les $INTERVALLE au lieu de 5 s"
mkdir -p "$DIR"
cat >"$DROPIN" <<EOF
# Ecrit par rotation-ecran-externe.sh : hyprmoncfgd ne verifie plus les ecrans
# toutes les 5 s, ce qui annulait la rotation de l'ecran de la tablette.
# Pour revenir en arriere : supprime ce fichier, puis
#   systemctl --user daemon-reload && systemctl --user restart $UNIT
[Service]
ExecStart=
ExecStart=$ARGV --poll-interval $INTERVALLE
EOF
echo "    $DROPIN"

echo "==> 2/2 Redemarrage de hyprmoncfgd"
systemctl --user daemon-reload
systemctl --user restart "$UNIT"
sleep 3
if systemctl --user is-active --quiet "$UNIT" && pgrep -af hyprmoncfgd | grep -q -- "--poll-interval $INTERVALLE"; then
  echo "    OK : hyprmoncfgd tourne avec --poll-interval $INTERVALLE"
else
  echo "    ATTENTION : hyprmoncfgd ne tourne pas comme prevu. Etat :"
  systemctl --user status "$UNIT" --no-pager -n 5 || true
  echo "    Pour revenir en arriere : rm $DROPIN && systemctl --user daemon-reload && systemctl --user restart $UNIT"
  exit 1
fi

echo
echo "Termine. Mets la tablette a la verticale : l'ecran doit tourner et rester tourne."
echo "Pour revenir en arriere :"
echo "  rm $DROPIN && systemctl --user daemon-reload && systemctl --user restart $UNIT"
