#!/usr/bin/env bash
# shellcheck disable=SC2024  # les journaux appartiennent a l utilisateur : redirection voulue
# install.sh : installe tout pour une Surface Pro 6 sous Omarchy 4 :
# tactile, rotation, clavier AZERTY a l'ecran, boutons de barre, clavier sur
# l'ecran de verrouillage, demarrage sur le noyau Surface et mise en veille.
#
# Usage :
#   bash install.sh              installation complete (etapes 1 a 7)
#   bash install.sh --depuis 3   reprendre a l'etape 3
#   bash install.sh --verifier   verifier seulement ce qui est en place
#
# Reglages facultatifs (variables d'environnement) :
#   CLAVIER_PAYSAGE=400    hauteur du clavier a l'ecran en paysage (pixels)
#   CLAVIER_PORTRAIT=500   hauteur du clavier a l'ecran en portrait (pixels)
#   LOCK_EXPLORER=oui|non  installer le plugin Lock Screen Explorer sans poser la question
#   ex. : CLAVIER_PORTRAIT=450 bash install.sh
#
# Sans danger si relance : chaque etape verifie ce qui est deja fait.
# Etapes testees une a une sur une Surface Pro 6 (Omarchy 4.0.4, Hyprland 0.56.2),
# octobre 2026.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
S="$DIR/scripts"
LOG="$HOME/omarchy-surface-install.log"

CLAVIER_PAYSAGE="${CLAVIER_PAYSAGE:-400}"
CLAVIER_PORTRAIT="${CLAVIER_PORTRAIT:-500}"
LOCK_EXPLORER="${LOCK_EXPLORER:-}"

SURFACE_KEY="56C464BAAC421453"
SURFACE_KEY_URL="https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc"
TABLET_MODE_URL="https://github.com/andreiyurik/omarchy-tablet-mode"
TABLET_MODE_COMMIT="c6ba596"
TABLET_MODE_DIR="$HOME/.config/omarchy/plugins/andreiyurik.tablet-mode"
LOCK_EXPLORER_URL="https://github.com/SirJul1337/omarchy-lock-explorer.git"
LOCK_EXPLORER_DIR="$HOME/.config/omarchy/plugins/io.github.sirjul1337.lock-explorer"
WVKBD_URL="https://git.sr.ht/~proycon/wvkbd/archive/v0.20.tar.gz"
SRC="$HOME/src/wvkbd-v0.20"
BIN="$HOME/.local/bin"

# --------------------------------------------------------------------- affichage

GRAS=$'\e[1m' VERT=$'\e[32m' JAUNE=$'\e[33m' ROUGE=$'\e[31m' FIN=$'\e[0m'
ETAPE=0

titre() {
  printf '\n%s==== %s ====%s\n' "$GRAS" "$*" "$FIN"
  echo "==== $* ($(date '+%F %T'))" >>"$LOG"
}
ok() { printf '  %sOK%s %s\n' "$VERT" "$FIN" "$*"; echo "  OK $*" >>"$LOG"; }
info() { printf '  %s\n' "$*"; echo "  $*" >>"$LOG"; }
attention() { printf '  %sATTENTION%s %s\n' "$JAUNE" "$FIN" "$*"; echo "  ATTENTION $*" >>"$LOG"; }
erreur() {
  printf '\n%sERREUR%s %s\n' "$ROUGE" "$FIN" "$*"
  echo "ERREUR $*" >>"$LOG"
  if ((ETAPE > 0)); then
    printf '\nCorrige le probleme, puis reprends a cette etape :\n  bash %s --depuis %d\n' "$DIR/install.sh" "$ETAPE"
  fi
  printf 'Journal complet : %s\n' "$LOG"
  exit 1
}

# Lance une commande sans question en gardant sa sortie dans le journal.
journal() { "$@" 2>&1 | tee -a "$LOG"; }

# Pareil pour un script qui laisse des programmes en arriere-plan (le clavier,
# sa surveillance) : sa sortie passe par un fichier, que ces programmes peuvent
# garder ouvert sans bloquer l'installation. Elle s'affiche a la fin du script.
journal_fichier() {
  local tmp rc=0
  tmp=$(mktemp)
  "$@" >"$tmp" 2>&1 </dev/null || rc=$?
  cat "$tmp"
  cat "$tmp" >>"$LOG"
  rm -f "$tmp"
  return "$rc"
}

# Question oui/non. $1 = question, $2 = reponse par defaut (o ou n).
demander() {
  local rep=""
  if [[ -t 0 ]]; then read -r -p "  $1 " rep || rep=""; fi
  rep="${rep:-$2}"
  [[ ${rep,,} =~ ^(o|oui|y|yes)$ ]]
}

# ----------------------------------------------------------------------- outils

plugin_connu() {
  omarchy-shell shell listPlugins 2>/dev/null | jq -e --arg id "$1" 'any(.[]; .id == $id)' >/dev/null 2>&1
}

plugin_actif() {
  omarchy-shell shell listPlugins 2>/dev/null |
    jq -e --arg id "$1" 'any(.[]; .id == $id and .enabled == true)' >/dev/null 2>&1
}

activer_plugin() {
  local id="$1" i
  if plugin_actif "$id"; then
    ok "$id deja actif"
    return 0
  fi
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  for i in $(seq 40); do
    plugin_connu "$id" && break
    sleep 0.25
  done
  if omarchy plugin enable "$id" >>"$LOG" 2>&1; then
    ok "$id active"
  else
    attention "$id n'a pas pu etre active : active-le dans le Plugin Manager (icone omaplug de la barre)"
  fi
}

garder_sudo() {
  sudo -v || erreur "sudo refuse"
  (while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 50; done) &
}

# ------------------------------------------------------------------ verifications

verifications() {
  titre "Verifications"
  ((EUID != 0)) || erreur "lance le script en utilisateur normal, sans sudo : bash install.sh"
  [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] ||
    erreur "lance le script depuis un terminal de la session Omarchy (pas en SSH ni depuis une console texte)"
  command -v omarchy >/dev/null || erreur "Omarchy introuvable"
  [[ -f $HOME/.config/hypr/hyprland.lua && -f $HOME/.config/hypr/autostart.lua ]] ||
    erreur "configuration Hyprland en Lua introuvable (~/.config/hypr/hyprland.lua) : il faut Omarchy 4"
  for f in corrections-tablet-mode.sh azerty-landscape.py azerty-full.py install-wvkbd-widget.sh \
    install-close-widget.sh simplifier-tablette.sh clavier-super.sh demarrage-surface.sh veille.sh \
    rotation-ecran-externe.sh; do
    [[ -f $S/$f ]] || erreur "fichier manquant : scripts/$f (depot incomplet)"
  done
  ok "Omarchy $(omarchy-version 2>/dev/null || echo '?'), Hyprland en Lua, scripts presents"

  local modele
  modele=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
  if [[ $modele == "Surface Pro 6" ]]; then
    ok "modele : $modele"
  elif [[ $modele == Surface* ]]; then
    attention "modele : $modele. Tout a ete teste sur une Surface Pro 6 seulement."
    attention "Le nom de l'ecran tactile peut differer : verifie la rotation du tactile apres le redemarrage."
    demander "Continuer quand meme ? [o/N]" n || exit 0
  else
    erreur "modele : '${modele:-inconnu}'. Ce depot est fait pour une Microsoft Surface (Surface Pro 6)."
  fi

  local sb
  sb=$(bootctl status 2>/dev/null | grep -i "secure boot" | head -1 || true)
  if [[ ${sb,,} == *enabled* ]]; then
    erreur "Secure Boot est active ($sb). Eteins la tablette, maintiens Volume + puis appuie sur Power, puis Security > Secure Boot > Disabled."
  elif [[ -n $sb ]]; then
    ok "Secure Boot : ${sb#*: }"
  else
    attention "etat de Secure Boot inconnu : il doit etre desactive"
  fi

  curl -fsSI https://github.com >/dev/null 2>&1 || erreur "pas d'acces a Internet (connecte-toi au Wi-Fi)"
  ok "acces a Internet"
  garder_sudo
}

# ------------------------------------------------------------------------ etapes

etape1() {
  ETAPE=1
  titre "Etape 1/7 : tactile (noyau linux-surface et iptsd)"
  if pacman -Q linux-surface iptsd >/dev/null 2>&1; then
    ok "linux-surface et iptsd deja installes"
  else
    if ! sudo pacman-key --list-keys "$SURFACE_KEY" >/dev/null 2>&1; then
      info "Ajout de la cle du depot linux-surface"
      curl -fsSL "$SURFACE_KEY_URL" | sudo pacman-key --add - >>"$LOG" 2>&1 ||
        erreur "impossible d'ajouter la cle linux-surface"
      sudo pacman-key --finger "$SURFACE_KEY" >>"$LOG" 2>&1 || erreur "cle linux-surface introuvable apres ajout"
      sudo pacman-key --lsign-key "$SURFACE_KEY" >>"$LOG" 2>&1 || erreur "impossible de signer la cle linux-surface"
    fi
    ok "cle linux-surface"
    if ! grep -qF "[linux-surface]" /etc/pacman.conf; then
      printf '\n[linux-surface]\nServer = https://pkg.surfacelinux.com/arch/\n' | sudo tee -a /etc/pacman.conf >/dev/null
    fi
    ok "depot linux-surface dans /etc/pacman.conf"
    echo
    info "${GRAS}Mise a jour du systeme (omarchy update) :${FIN}"
    info "  - reponds Oui pour lancer la mise a jour ;"
    info "  - s'il propose de redemarrer, reponds Non : le script continue ensuite."
    omarchy update || attention "omarchy update s'est termine avec une erreur"
    pacman -Si linux-surface >/dev/null 2>&1 ||
      erreur "le depot linux-surface n'est pas encore lu : relance et accepte la mise a jour"
    journal sudo pacman -S --needed --noconfirm linux-surface linux-surface-headers iptsd ||
      erreur "installation de linux-surface impossible"
    ok "linux-surface et iptsd installes"
  fi
  info "Entrees de demarrage (limine-update), patiente..."
  sudo limine-update >>"$LOG" 2>&1 || attention "limine-update a signale une erreur (voir le journal)"
  if sudo grep -qi "linux-surface" /boot/limine.conf 2>/dev/null; then
    ok "entree linux-surface dans le menu de demarrage"
  else
    attention "pas d'entree linux-surface dans /boot/limine.conf"
  fi
}

etape2() {
  ETAPE=2
  titre "Etape 2/7 : rotation (iio-sensor-proxy et plugin Tablet Mode)"
  journal sudo pacman -S --needed --noconfirm iio-sensor-proxy || erreur "installation de iio-sensor-proxy impossible"
  ok "iio-sensor-proxy"
  if [[ -d $TABLET_MODE_DIR ]]; then
    ok "plugin Tablet Mode deja installe"
  else
    journal omarchy plugin add "$TABLET_MODE_URL" --enable --yes || erreur "installation du plugin Tablet Mode impossible"
  fi
  if git -C "$TABLET_MODE_DIR" rev-parse --git-dir >/dev/null 2>&1; then
    # Version testee, sur laquelle les corrections s'appliquent (remet aussi le
    # fichier d'origine avant de les refaire).
    git -C "$TABLET_MODE_DIR" cat-file -e "$TABLET_MODE_COMMIT^{commit}" 2>/dev/null ||
      git -C "$TABLET_MODE_DIR" fetch -q origin >>"$LOG" 2>&1 || true
    git -C "$TABLET_MODE_DIR" checkout -q -f "$TABLET_MODE_COMMIT" >>"$LOG" 2>&1 ||
      erreur "impossible de passer le plugin Tablet Mode a la version $TABLET_MODE_COMMIT"
    ok "plugin Tablet Mode en version $TABLET_MODE_COMMIT (1.7.4)"
  else
    attention "plugin Tablet Mode installe hors git : sa version n'est pas verifiee"
  fi
  activer_plugin andreiyurik.tablet-mode
  journal bash "$S/corrections-tablet-mode.sh" || erreur "corrections du plugin Tablet Mode"
}

etape3() {
  ETAPE=3
  titre "Etape 3/7 : clavier AZERTY a l'ecran (wvkbd-fr)"
  journal sudo pacman -S --needed --noconfirm wayland wayland-protocols pango cairo libxkbcommon base-devel ||
    erreur "installation des outils de compilation impossible"
  if [[ ! -f $SRC/layout.mobintl.h ]]; then
    mkdir -p "$HOME/src"
    info "Telechargement de wvkbd 0.20"
    curl -fsSL -o "$HOME/src/wvkbd-0.20.tar.gz" "$WVKBD_URL" || erreur "telechargement de wvkbd impossible"
    tar xzf "$HOME/src/wvkbd-0.20.tar.gz" -C "$HOME/src" || erreur "archive wvkbd illisible"
  fi
  [[ -f $SRC/layout.mobintl.h ]] || erreur "sources de wvkbd introuvables dans $SRC"
  local f
  for f in layout keymap config; do
    [[ -f $SRC/$f.fr.h ]] || cp "$SRC/$f.mobintl.h" "$SRC/$f.fr.h"
  done
  journal python3 "$S/azerty-landscape.py" "$SRC" || erreur "disposition AZERTY (paysage)"
  journal python3 "$S/azerty-full.py" "$SRC" || erreur "disposition AZERTY (portrait)"
  info "Compilation, patiente..."
  make -C "$SRC" LAYOUT=fr wvkbd-fr >>"$LOG" 2>&1 || erreur "compilation de wvkbd-fr (voir le journal)"
  pkill -x wvkbd-fr 2>/dev/null || true
  install -Dm755 "$SRC/wvkbd-fr" "$BIN/wvkbd-fr"
  ok "wvkbd-fr installe dans $BIN"
}

etape4() {
  ETAPE=4
  titre "Etape 4/7 : boutons de la barre (clavier et fermer la fenetre)"
  journal bash "$S/install-wvkbd-widget.sh" >/dev/null || erreur "bouton clavier"
  journal bash "$S/install-close-widget.sh" >/dev/null || erreur "bouton fermer la fenetre"
  ok "boutons crees"
  activer_plugin tim.wvkbd-toggle
  activer_plugin tim.close-window
}

etape5() {
  ETAPE=5
  titre "Etape 5/7 : clavier sur l'ecran de verrouillage, touche Super, demarrage"
  journal_fichier bash "$S/simplifier-tablette.sh" || erreur "simplifier-tablette.sh"
  journal_fichier bash "$S/clavier-super.sh" || erreur "clavier-super.sh"
  journal_fichier bash "$S/demarrage-surface.sh" || erreur "demarrage-surface.sh"
  local widget="$HOME/.config/omarchy/plugins/tim.wvkbd-toggle/Widget.qml"
  local autostart="$HOME/.config/hypr/autostart.lua"
  local taille="-L $CLAVIER_PAYSAGE -H $CLAVIER_PORTRAIT"
  [[ -f $widget ]] || erreur "bouton clavier introuvable : reprends a l'etape 4 (bash install.sh --depuis 4)"
  sed -i -E "s/-L [0-9]+( -H [0-9]+)?/$taille/" "$autostart" "$widget"
  if grep -q -- "wvkbd-verrou --hidden $taille" "$autostart" && grep -q -- "$taille" "$widget"; then
    ok "taille du clavier : $CLAVIER_PAYSAGE px en paysage, $CLAVIER_PORTRAIT px en portrait"
  else
    attention "taille du clavier non appliquee : verifie ~/.config/hypr/autostart.lua"
  fi
  pkill -f "$BIN/wvkbd-verrou" 2>/dev/null || true
  pkill -x wvkbd-fr 2>/dev/null || true
  sleep 1
  # shellcheck disable=SC2086
  nohup "$BIN/wvkbd-verrou" --hidden $taille >/dev/null 2>&1 &
  ok "clavier relance"
}

etape6() {
  ETAPE=6
  titre "Etape 6/7 : mise en veille (verrouillage 2 min, ecran eteint 30 s une fois verrouille)"
  if [[ -d $LOCK_EXPLORER_DIR ]]; then
    ok "Lock Screen Explorer deja installe"
    activer_plugin io.github.sirjul1337.lock-explorer
  elif [[ ${LOCK_EXPLORER,,} == oui ]]; then
    journal omarchy plugin add "$LOCK_EXPLORER_URL" --enable --yes ||
      erreur "installation de Lock Screen Explorer impossible"
    info "Attente de la prise en charge de l'ecran de verrouillage..."
    local i rep=""
    for i in $(seq 20); do
      rep=$(omarchy-shell lock setBlankDelay 30000 2>/dev/null || true)
      [[ $rep == ok ]] && break
      if ((i == 10)); then omarchy restart shell >/dev/null 2>&1 || true; fi
      sleep 1
    done
    if [[ $rep == ok ]]; then ok "Lock Screen Explorer actif"; else attention "Lock Screen Explorer ne repond pas encore"; fi
  else
    info "Lock Screen Explorer non installe : l'ecran de verrouillage d'Omarchy est garde"
  fi
  journal bash "$S/veille.sh" || erreur "veille.sh"
}

etape7() {
  ETAPE=7
  titre "Etape 7/7 : ecran externe (seulement avec le plugin hyprmoncfg)"
  if command -v hyprmoncfgd >/dev/null 2>&1; then
    journal bash "$S/rotation-ecran-externe.sh" ||
      attention "rotation-ecran-externe.sh a echoue : relance-le plus tard avec bash install.sh --depuis 7"
  else
    info "hyprmoncfg n'est pas installe : rien a faire."
    info "Si tu l'installes plus tard : bash $DIR/install.sh --depuis 7"
  fi
}

# --------------------------------------------------------------------- controle

verifier() {
  titre "Controle"
  local bons=0 total=0 F="$TABLET_MODE_DIR/bin/omarchy-tablet-mode"
  point() {  # $1 = libelle, puis la commande de test
    local libelle="$1"
    shift
    total=$((total + 1))
    if "$@" >/dev/null 2>&1; then
      printf '  %s[x]%s %s\n' "$VERT" "$FIN" "$libelle"
      echo "  [x] $libelle" >>"$LOG"
      bons=$((bons + 1))
    else
      printf '  %s[ ]%s %s\n' "$ROUGE" "$FIN" "$libelle"
      echo "  [ ] $libelle" >>"$LOG"
    fi
  }
  point "linux-surface et iptsd installes" pacman -Q linux-surface iptsd
  point "noyau Surface demarre (sinon : redemarre et choisis linux-surface)" bash -c '[[ $(uname -r) == *surface* ]]'
  point "iptsd actif (tactile)" bash -c 'systemctl list-units "iptsd@*" --state=running --no-legend | grep -q .'
  point "Limine retient le dernier noyau demarre" sudo grep -q "^remember_last_entry: yes" /boot/limine.conf
  point "iio-sensor-proxy installe" pacman -Q iio-sensor-proxy
  point "plugin Tablet Mode actif" plugin_actif andreiyurik.tablet-mode
  point "plugin Tablet Mode : correction 1 (capteur du Type Cover)" grep -q 'UNREPORTED_FOLD = ("Surface' "$F"
  point "plugin Tablet Mode : correction 2 (ecran tactile virtuel)" grep -q 'conf.get("touch", \[\]) + \[' "$F"
  point "clavier wvkbd-fr installe" test -x "$BIN/wvkbd-fr"
  point "clavier : touche Sup" grep -q '"Sup", "Sup"' "$SRC/layout.fr.h"
  point "bouton clavier actif" plugin_actif tim.wvkbd-toggle
  point "bouton fermer la fenetre actif" plugin_actif tim.close-window
  point "clavier sur l'ecran de verrouillage (tablette.lua)" grep -q "above_lock" "$HOME/.config/hypr/tablette.lua"
  point "raccourcis Super depuis le clavier a l'ecran" grep -q "resolve_binds_by_sym" "$HOME/.config/hypr/tablette.lua"
  point "surveillance du clavier lancee (wvkbd-verrou)" pgrep -f "$BIN/wvkbd-verrou"
  point "verrouillage apres 2 min" bash -c 'jq -e ".idle.lock == 120" "$HOME/.config/omarchy/shell.json"'
  if [[ -d $LOCK_EXPLORER_DIR ]]; then
    point "ecran eteint 30 s apres verrouillage (Lock Screen Explorer)" grep -q '"blankMs": 30000' "$HOME/.config/omarchy/shell.json"
  else
    point "ecran eteint 30 s apres verrouillage (Omarchy)" test -f /etc/pacman.d/hooks/zz-omarchy-veille-verrou.hook
  fi
  if command -v hyprmoncfgd >/dev/null 2>&1; then
    point "ecran externe : rotation gardee (hyprmoncfgd)" bash -c 'pgrep -af hyprmoncfgd | grep -q -- "--poll-interval 24h"'
  fi
  echo
  info "$bons/$total points en place."
}

# ------------------------------------------------------------------------ depart

DEPUIS=1
MODE=installer
while (($#)); do
  case "$1" in
    --depuis)
      DEPUIS="${2:-}"
      shift
      (($#)) && shift
      ;;
    --verifier) MODE=verifier; shift ;;
    -h | --help) awk 'NR > 2 && /^#/ { sub(/^# ?/, ""); print; next } NR > 2 { exit }' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) erreur "option inconnue : $1 (voir bash install.sh --help)" ;;
  esac
done
[[ $DEPUIS =~ ^[1-7]$ ]] || erreur "--depuis attend un numero d'etape de 1 a 7"
[[ $CLAVIER_PAYSAGE =~ ^[0-9]+$ && $CLAVIER_PORTRAIT =~ ^[0-9]+$ ]] ||
  erreur "CLAVIER_PAYSAGE et CLAVIER_PORTRAIT doivent etre des nombres"

echo "==== install.sh $(date '+%F %T') : $MODE, depuis l'etape $DEPUIS" >>"$LOG"

if [[ $MODE == verifier ]]; then
  garder_sudo
  verifier
  exit 0
fi

printf '%sSurface Pro 6 sous Omarchy : tactile, rotation, clavier AZERTY, veille%s\n' "$GRAS" "$FIN"
echo "Etapes $DEPUIS a 7. Duree : 10 a 30 minutes, surtout la mise a jour du systeme."
echo "Garde la tablette sur secteur et connectee au Wi-Fi. Journal : $LOG"
verifications

if ((DEPUIS <= 6)) && [[ ! -d $LOCK_EXPLORER_DIR && -z $LOCK_EXPLORER ]]; then
  echo
  if demander "Installer Lock Screen Explorer, l'ecran de verrouillage de la premiere tablette ? [O/n]" o; then
    LOCK_EXPLORER=oui
  else
    LOCK_EXPLORER=non
  fi
fi
echo
demander "Tout est pret. Commencer ? [O/n]" o || exit 0

for n in 1 2 3 4 5 6 7; do
  if ((n >= DEPUIS)); then
    "etape$n"
  fi
done
ETAPE=0

verifier

titre "Termine"
if [[ $(uname -r) == *surface* ]]; then
  info "Le noyau Surface tourne deja : pas besoin de redemarrer."
  info "Pour tout controler plus tard : bash $DIR/install.sh --verifier"
else
  info "Il reste a redemarrer sur le noyau Surface (le tactile en a besoin)."
  info "Au redemarrage, choisis ${GRAS}linux-surface${FIN} dans le menu Limine (fleches puis Entree)."
  info "Une seule fois : il sera ensuite choisi tout seul."
  info "Apres le redemarrage, pour tout controler : bash $DIR/install.sh --verifier"
  echo
  if demander "Redemarrer maintenant ? [O/n]" o; then
    systemctl reboot
  fi
fi
