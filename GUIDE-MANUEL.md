# Tactile, rotation et clavier AZERTY : Surface Pro 6 sous Omarchy

> Version manuelle de `install.sh` : la même installation, étape par étape. Le plus simple reste `bash install.sh` (voir le README).

Sur une Surface Pro 6 sous Omarchy (Hyprland 0.56.2), ces six étapes donnent le tactile, la rotation avec le tactile qui suit, un clavier AZERTY à l'écran (aussi sur l'écran de verrouillage), deux boutons de barre (clavier et fermer la fenêtre) et des délais de mise en veille réglés. L'étape 7, facultative, garde la rotation quand un écran externe est branché. Une étape marquée (non confirmé) n'a pas été vérifiée sur la première tablette. Si la nouvelle n'est pas une Surface Pro 6, lis d'abord « À adapter sur un autre appareil ».

## Ce qu'il faut installer

Six éléments sont indispensables, les autres sont facultatifs. Chacun s'installe à l'étape indiquée : suis les étapes dans l'ordre.

| Élément | À quoi il sert | Indispensable | Où |
| --- | --- | --- | --- |
| Noyau `linux-surface` et `iptsd` | Écran tactile de la Surface | **Oui** | Étape 1 |
| `iio-sensor-proxy` | Lit l'accéléromètre | **Oui** | Étape 2 |
| Plugin [Tablet Mode](https://github.com/andreiyurik/omarchy-tablet-mode), version `c6ba596` | Tourne l'écran et le tactile | **Oui** | Étape 2 |
| Les deux corrections du plugin Tablet Mode | Rotation juste sur la Surface | **Oui** | Étape 2 |
| Outils de compilation et wvkbd 0.20 | Clavier AZERTY à l'écran (`wvkbd-fr`) | **Oui** | Étape 3 |
| Les huit premiers scripts de l'annexe | Clavier, boutons, verrouillage, démarrage, veille | **Oui** | Étapes 3 à 6 |
| Plugin [Lock Screen Explorer](https://github.com/SirJul1337/omarchy-lock-explorer) | Autre écran de verrouillage | Non : l'étape 6 marche avec ou sans | Avant l'étape 6 |
| Plugin [hyprmoncfg](https://github.com/crmne/omarchy-hyprmoncfg) et `rotation-ecran-externe.sh` | Écrans externes | Seulement avec un écran externe | Étape 7 |

Inutiles : OmaTouch, la config « Tablet Experience » et le paquet AUR `wvkbd`.

Les deux plugins facultatifs s'installent depuis GitHub avec les commandes de leurs auteurs (non confirmé). Réponds oui aux questions :

```bash
# Ecran de verrouillage de la premiere tablette (a installer avant l'etape 6)
omarchy plugin add https://github.com/SirJul1337/omarchy-lock-explorer.git --enable
# Gestion des ecrans externes (fais ensuite l'etape 7)
omarchy plugin add https://github.com/crmne/omarchy-hyprmoncfg.git --enable
```

## Avant de commencer

- **Les scripts** : crée dans `~/Downloads` les neuf scripts utilisés aux étapes 3 à 7 (huit indispensables, un facultatif). Leur texte complet est dans l'annexe, à la fin de ce document : chaque bloc se colle tel quel dans un terminal et crée son fichier. Vérifie-les ensuite avec la commande d'empreintes donnée à la fin de l'annexe.
- Branche la tablette sur secteur, connecte-la au Wi-Fi et garde le Type Cover attaché pendant l'installation.
- Ne lance jamais `pacman -Syu` directement : Omarchy le bloque (message « Woah partner... »). Passe par `omarchy update`.
- Désactive Secure Boot : appareil éteint, maintiens Volume + puis appuie sur Power, puis Security, Secure Boot, Disabled. Sur le premier appareil, `bootctl status` affiche `Secure Boot: disabled (setup)` (confirmé).

## Étape 1 — Tactile : noyau linux-surface

L'écran tactile de la Surface demande le noyau linux-surface et le démon iptsd.

**Clé et dépôt (confirmé)**

```bash
curl -s https://raw.githubusercontent.com/linux-surface/linux-surface/master/pkg/keys/surface.asc | sudo pacman-key --add -
sudo pacman-key --finger 56C464BAAC421453
sudo pacman-key --lsign-key 56C464BAAC421453
grep -qF "[linux-surface]" /etc/pacman.conf || sudo tee -a /etc/pacman.conf >/dev/null <<'EOF'

[linux-surface]
Server = https://pkg.surfacelinux.com/arch/
EOF
```

**Mise à jour et paquets**

```bash
omarchy update
sudo pacman -S --needed linux-surface linux-surface-headers iptsd
```

- `libwacom-surface` n'existe plus dans le dépôt : ne l'installe pas.
- Si Omarchy bloque la seconde commande : `sudo env OMARCHY_ALLOW_DIRECT_PACMAN=1 pacman -S --needed linux-surface linux-surface-headers iptsd` (non confirmé).
- Sur le premier appareil, ces paquets étaient installés (journal pacman), mais la commande exacte et la sortie de `omarchy update` n'ont pas été vues.

**Entrée de démarrage (confirmé)**

```bash
sudo limine-update
sudo ls /boot/EFI/Linux
sudo grep -i surface /boot/limine.conf
```

Tu dois voir `omarchy_linux-surface.efi` et une entrée `linux-surface`. Le noyau `linux-omarchy` reste dans le menu en secours. Ne copie pas `/etc/default/limine` d'un appareil à l'autre : il contient l'identifiant du disque.

**Redémarrer et vérifier (confirmé)**

Redémarre et choisis `linux-surface` dans le menu Limine avec les flèches du clavier, puis :

```bash
uname -r
systemctl status 'iptsd@*'
```

`uname -r` doit finir par `surface`, et iptsd doit être `active (running)` en « Touchscreen mode ». Pour que linux-surface démarre tout seul, lance demarrage-surface.sh à l'étape 5.

## Étape 2 — Rotation avec le tactile qui suit

Le plugin `andreiyurik.tablet-mode` fait tourner l'écran d'après l'accéléromètre, lu par `iio-sensor-proxy`. Sur le premier appareil : version `c6ba596` de [omarchy-tablet-mode](https://github.com/andreiyurik/omarchy-tablet-mode), réglage `mapping` à `standard`.

**Installation (indispensable)**

```bash
sudo pacman -S --needed iio-sensor-proxy
omarchy plugin add https://github.com/andreiyurik/omarchy-tablet-mode --enable
git -C ~/.config/omarchy/plugins/andreiyurik.tablet-mode checkout c6ba596
```

- La deuxième ligne installe le plugin Tablet Mode depuis [GitHub](https://github.com/andreiyurik/omarchy-tablet-mode), avec la commande donnée par son auteur (non confirmé). Réponds oui aux questions. Autre façon : « Tablet Mode » (Andrei Yurik) dans le Marketplace du Plugin Manager, puis l'activer dans la barre.
- La troisième ligne remet la version testée (`c6ba596`, version 1.7.4) : les deux corrections ci-dessous sont faites pour elle.
- N'accepte pas la mise à jour que le Plugin Manager proposera ensuite (« Update Unverified ») : elle efface les deux corrections.
- Sur la première tablette, le plugin et `iio-sensor-proxy` étaient déjà installés avant notre session ; la rotation y est confirmée.

**Deux corrections (confirmé)**

Sans elles, l'écran reste à l'horizontale quand le Type Cover est détaché, et le tactile ne tourne pas avec l'écran. Elles modifient le plugin : une mise à jour du plugin les efface, il faut alors les refaire.

```bash
F=~/.config/omarchy/plugins/andreiyurik.tablet-mode/bin/omarchy-tablet-mode
cp $F $F.bak
# 1. Le capteur de mode tablette est dans le Type Cover : on l'ignore pour ce modèle
sed -i 's/UNREPORTED_FOLD = ("HP ENVY/UNREPORTED_FOLD = ("Surface Pro 6", "HP ENVY/' $F
# 2. Le tactile passe par le périphérique virtuel d'iptsd : on le fait tourner aussi
python3 - <<'EOF'
import os
p = os.path.expanduser("~/.config/omarchy/plugins/andreiyurik.tablet-mode/bin/omarchy-tablet-mode")
s = open(p).read()
old = 'for touch in conf.get("touch", [])'
new = 'for touch in conf.get("touch", []) + ["iptsd-virtual-touchscreen-045e:001f"]'
assert s.count(old) == 1, "motif introuvable ou en double, rien modifie"
open(p, "w").write(s.replace(old, new))
print("OK")
EOF
rm -f ~/.local/state/omarchy/tablet-mode/folded
pkill -f "omarchy-tablet-mode daemon"; sleep 1; nohup $F daemon >/dev/null 2>&1 &
```

Vérification :

- `cat /sys/class/dmi/id/product_name` affiche `Surface Pro 6` (sinon, mets ce nom dans le `sed`).
- `grep -n "Surface Pro 6\|iptsd-virtual" $F` montre les deux lignes modifiées. Rien ne s'affiche : la version du plugin est différente.
- `$F status` affiche `"hasFoldSensor": false`.

**Test (confirmé)** : penche la tablette dans les quatre sens, attends 2 à 3 secondes à chaque fois, et touche les quatre coins de l'écran.

## Étape 3 — Clavier AZERTY (wvkbd-fr)

wvkbd n'a pas de disposition AZERTY : on compile sa version 0.20 avec une disposition modifiée, installée sous le nom `wvkbd-fr`. Les accents passent par un appui long sur la lettre (è é ê ë, à â, ç, ù û ü, î ï, ô œ).

```bash
pacman -Q wayland wayland-protocols pango cairo libxkbcommon base-devel
mkdir -p ~/src && cd ~/src
curl -L -o wvkbd-0.20.tar.gz https://git.sr.ht/~proycon/wvkbd/archive/v0.20.tar.gz
tar xzf wvkbd-0.20.tar.gz
cd wvkbd-v0.20
cp layout.mobintl.h layout.fr.h
cp keymap.mobintl.h keymap.fr.h
cp config.mobintl.h config.fr.h
python3 ~/Downloads/azerty-landscape.py ~/src/wvkbd-v0.20
python3 ~/Downloads/azerty-full.py
make LAYOUT=fr wvkbd-fr
install -Dm755 ~/src/wvkbd-v0.20/wvkbd-fr ~/.local/bin/wvkbd-fr
```

- Chaque script Python doit afficher `OK:`. Les messages `Using "code" is deprecated` de la compilation sont sans conséquence.
- S'il manque des outils : `sudo pacman -S --needed wayland wayland-protocols pango cairo libxkbcommon base-devel` (non confirmé).
- Travaille dans `~/src`, pas dans `/tmp`, qui est vidé au redémarrage.
- Paysage et portrait confirmés.
- Le paquet AUR `wvkbd` (`wvkbd-mobintl`, en QWERTY) n'est pas nécessaire.

## Étape 4 — Boutons de barre

```bash
bash ~/Downloads/install-wvkbd-widget.sh
bash ~/Downloads/install-close-widget.sh
omarchy restart shell
```

Active ensuite « Clavier virtuel » et « Fermer la fenêtre » dans le Plugin Manager (icône omaplug de la barre). Le bouton clavier s'affiche à gauche de la barre, le × à droite (confirmé). Le bouton clavier ne marche qu'après l'étape 5.

Le × ferme la fenêtre que tu viens de toucher : dans Hyprland 0.56.2, toucher une fenêtre lui donne le focus, et toucher la barre ne le lui retire pas (confirmé). Si un bouton n'apparaît pas : `qs log -f -p /usr/share/omarchy/shell`.

## Étape 5 — Réglages finaux

Lance ces commandes dans cet ordre, une seule fois chacune, puis redémarre. `simplifier-tablette.sh` et `clavier-super.sh` affichent une ligne « Erreurs de config Hyprland » qui doit être vide ; `demarrage-surface.sh` se termine par deux lignes `OK`. Si tu relances `simplifier-tablette.sh`, relance ensuite tout ce qui suit.

```bash
bash ~/Downloads/simplifier-tablette.sh
bash ~/Downloads/clavier-super.sh
bash ~/Downloads/demarrage-surface.sh
sed -i 's/-L 300/-L 400 -H 500/' ~/.config/hypr/autostart.lua ~/.config/omarchy/plugins/tim.wvkbd-toggle/Widget.qml
sudo reboot
```

`simplifier-tablette.sh` :

- lance `wvkbd-fr` caché au démarrage (dans `autostart.lua`) et branche le bouton clavier de la barre dessus ;
- installe une première version de `wvkbd-verrou`, remplacée ensuite par `demarrage-surface.sh` ;
- crée `~/.config/hypr/tablette.lua` : clavier utilisable par-dessus l'écran de verrouillage, et balayage depuis le bord gauche ou droit pour changer de bureau ;
- en option, `AUTO=1 bash ~/Downloads/simplifier-tablette.sh` affiche le clavier dès qu'un champ de texte est touché, aussi quand le Type Cover est branché.

`clavier-super.sh` (confirmé : Super+W marche depuis le clavier virtuel) :

- remplace la touche « Cmp » par **Sup** sur les couches de lettres ;
- fait lire à Hyprland les raccourcis du clavier virtuel d'après la lettre affichée. Sans ça, en AZERTY, la touche « w » du clavier virtuel compte comme « z ».

`demarrage-surface.sh` (confirmé : linux-surface démarre tout seul) :

- demande à Limine de retenir le dernier noyau démarré (`remember_last_entry: yes` dans `/boot/limine.conf`). Choisis linux-surface une fois dans le menu : il est ensuite choisi tout seul ;
- confie le lancement du clavier à `wvkbd-verrou`, qui attend que le clavier soit prêt avant de lui envoyer un signal, l'affiche quand l'écran se verrouille, le cache au déverrouillage et le relance s'il s'arrête.

**Taille du clavier (confirmé)** : la commande `sed` passe la hauteur en paysage de 300 à 400 pixels et règle le portrait à 500 (250 par défaut, trop petit). Pour d'autres valeurs, change-les dans la ligne `wvkbd-verrou` de `~/.config/hypr/autostart.lua` et dans `~/.config/omarchy/plugins/tim.wvkbd-toggle/Widget.qml`, puis redémarre.

## Étape 6 — Mise en veille

Session ouverte, la tablette se verrouille après 2 minutes sans activité ; une fois verrouillée, l'écran s'éteint après 30 secondes sans activité (5 secondes par défaut).

```bash
bash ~/Downloads/veille.sh
```

- Le délai de la session ouverte est le réglage `idle.lock` de `~/.config/omarchy/shell.json` (300 secondes par défaut). L'économiseur d'écran, prévu à 150 secondes, n'apparaît plus puisque le verrouillage vient avant.
- Le délai de l'écran verrouillé dépend de l'écran de verrouillage utilisé. Avec le plugin Lock Screen Explorer (installé sur la première tablette), le script utilise son réglage `omarchy-shell lock setBlankDelay 30000`, aussi accessible dans ses paramètres (« Blank the display after »). Sans ce plugin, le délai est fixé dans un fichier d'Omarchy (`/usr/share/omarchy/shell/plugins/lock/Service.qml`) : le script le modifie et installe un hook pacman qui refait la modification après chaque mise à jour d'Omarchy.
- Pour d'autres valeurs, change `OUVERT=120` et `VERROU=30` en haut du script, puis relance-le.
- Le script se termine par une ligne `OK` pour chacun des deux délais (confirmé).

## Étape 7 — Écran externe : garder la rotation (facultatif)

Avec un écran externe branché et le plugin hyprmoncfg installé, l'écran de la tablette revenait à l'horizontale toutes les 5 secondes dès qu'on la mettait à la verticale. Ce script le corrige (confirmé). Sans le plugin hyprmoncfg, saute cette étape.

```bash
bash ~/Downloads/rotation-ecran-externe.sh
```

- **Cause** : hyprmoncfgd, le service du plugin hyprmoncfg (gestion des écrans), vérifie les écrans toutes les 5 secondes. Quand la rotation change, il réapplique sa disposition enregistrée, avec la tablette à l'horizontale, et recharge Hyprland.
- **Ce que fait le script** : il espace cette vérification à 24 h. hyprmoncfgd réagit toujours tout de suite quand tu branches ou débranches un écran, ou quand le couvercle change. Les fichiers de hyprmoncfg ne sont pas touchés : le réglage est un petit fichier dans `~/.config/systemd/user/hyprmoncfgd.service.d/`.
- **Résultat attendu** : la ligne `OK : hyprmoncfgd tourne avec --poll-interval 24h`. Pour vérifier plus tard, `pgrep -af hyprmoncfgd` doit montrer `--poll-interval 24h`.
- **Au branchement ou débranchement de l'écran**, l'écran de la tablette peut repasser un instant à l'horizontale, puis se retourner 2 à 3 secondes après : c'est normal.
- Sur la première tablette, ce réglage a disparu une fois sans cause trouvée. Si l'écran rebascule de nouveau toutes les 5 secondes, relance le script.

## Au quotidien

| Pour | Fais |
| --- | --- |
| Afficher ou cacher le clavier | Touche l'icône clavier de la barre |
| Fermer une fenêtre | Touche la fenêtre, puis le × de la barre ; ou Sup, puis w |
| Un raccourci Omarchy | Sup, puis la touche du raccourci |
| Une lettre accentuée | Appui long sur la lettre |
| Chiffres et symboles | Touche ⌨ en bas à gauche du clavier ; en portrait, les chiffres sont aussi sur la rangée du haut |
| Changer de bureau | Glisse depuis le bord gauche ou droit de l'écran |
| Clic droit | Appui long dans Chrome et beaucoup d'applications GTK, pas dans le terminal |
| Mot de passe de l'écran de verrouillage | Le clavier s'affiche tout seul |
| Déverrouiller le disque à l'allumage | Type Cover : à ce stade le bureau n'est pas encore lancé, aucun clavier tactile n'est possible |

## À adapter sur un autre appareil

- **Nom du modèle** (étape 2, correction 1) : ici `Surface Pro 6`, à lire avec `cat /sys/class/dmi/id/product_name`.
- **Écran tactile virtuel** (étape 2, correction 2) : ici `iptsd-virtual-touchscreen-045e:001f`, à lire avec `hyprctl devices | grep -iE -A2 "touch|ipts|045e"`.
- **Clavier virtuel** (étape 5) : `clavier-super.sh` vise `hl-virtual-keyboard-wvkbd-fr` et signale s'il ne le trouve pas.
- **Disposition clavier** : tout est prévu pour `fr`, à vérifier avec `hyprctl getoption input:kb_layout`.
- **Sens de rotation** : réglage `mapping` du plugin, ici `standard`. Autres valeurs : `portrait-swapped`, `landscape-swapped`, `rotated-180`. Pour choisir, `monitor-sensor` affiche ce que voit l'accéléromètre quand tu tournes la tablette (`normal`, `left-up`, `right-up`, `bottom-up`) ; `Ctrl+C` pour l'arrêter.
- **Noyau linux-surface** : seulement pour les Surface.

## Erreurs rencontrées

| Symptôme | Cause | Solution |
| --- | --- | --- |
| « Woah partner... » avec `pacman -Syu` | Omarchy bloque les mises à jour directes | `omarchy update` |
| `target not found: libwacom-surface` | Paquet retiré du dépôt | Ne pas l'installer |
| `target not found: wvkbd` avec pacman | Paquet AUR | Inutile : on compile `wvkbd-fr` |
| `hyprctl keyword` refusé | Config Hyprland en Lua | `hyprctl eval` |
| Écran bloqué à l'horizontale sans le Type Cover | Le capteur de mode tablette disparaît avec le Type Cover | Étape 2, correction 1 |
| L'écran tourne, pas le tactile | Le plugin ignorait le tactile virtuel d'iptsd | Étape 2, correction 2 |
| Espace ignoré dans Chrome avec OmaTouch | Cause non trouvée | Utiliser `wvkbd-fr` et désactiver OmaTouch |
| Super+W inactif au clavier virtuel | Raccourcis lus en AZERTY, pas de touche Super | `clavier-super.sh` |
| Dossier disparu dans `/tmp` | `/tmp` vidé au redémarrage | Travailler dans `~/src` |
| `Permission denied` sur `/boot/limine.conf` | Fichier réservé à root | Ajouter `sudo` |
| Clavier écrasé en portrait | Hauteur en portrait par défaut : 250 pixels | Option -H 500 (étape 5) |
| Avec un écran externe, l'écran de la tablette revient à l'horizontale toutes les 5 s | hyprmoncfgd (plugin hyprmoncfg) réapplique sa disposition d'écrans | Étape 7 |

## Pour revenir en arrière

- **Rotation** : `cp $F.bak $F`, avec F défini comme à l'étape 2, puis relance le démon (dernière ligne des corrections).
- **Réglages finaux et veille** : `simplifier-tablette.sh`, `demarrage-surface.sh` et `veille.sh` affichent à la fin leurs commandes d'annulation. Leurs sauvegardes sont dans `~/.config/hypr` (`sauvegarde-<date>`, `autostart.lua.bak-<date>`), `~/.config/omarchy` (`shell.json.bak-veille-<date>`), `/boot` (`limine.conf.avant-surface-<date>`) et `/usr/local/share/omarchy-veille`.
- **Touche Sup et raccourcis** : `layout.fr.h.bak-sup-<date>` dans `~/src/wvkbd-v0.20`, et `tablette.lua.bak-sup-<date>` dans `~/.config/hypr`.
- **Disposition AZERTY** : `layout.fr.h.bak` et `layout.fr.h.bak-full` dans `~/src/wvkbd-v0.20`.
- **Boutons de barre** : `rm -r ~/.config/omarchy/plugins/tim.wvkbd-toggle ~/.config/omarchy/plugins/tim.close-window`, puis `omarchy restart shell`.
- **Noyau** : `linux-omarchy` reste dans le menu de démarrage.
- **Écran externe** : `rm ~/.config/systemd/user/hyprmoncfgd.service.d/rotation-tablette.conf && systemctl --user daemon-reload && systemctl --user restart hyprmoncfgd.service`.

## Encore non vérifié

- [x] Fermer une fenêtre avec le × de la barre.
- [x] Taper au doigt le mot de passe de l'écran de verrouillage (l'affichage du clavier est confirmé).
- [x] Le clavier AZERTY en portrait.
- [x] Le noyau Surface choisi par défaut au démarrage.
- [ ] Étape 1, « Mise à jour et paquets » : sur la première tablette, ces paquets étaient déjà installés avant notre session, donc ces deux commandes n'y ont pas été lancées.
- [x] Le clic droit par appui long.
- [x] La mise en veille de l'étape 6.
- [ ] Les commandes `omarchy plugin add` depuis GitHub (étape 2 et plugins facultatifs) : sur la première tablette, ces plugins avaient été installés autrement.

## Annexe — les neuf scripts

Colle chaque bloc dans un terminal : il crée le script dans `~/Downloads`, sans rien lancer. Lance ensuite les scripts comme indiqué aux étapes 3 à 7.

### `azerty-landscape.py`

**Indispensable** — étape 3. Colle tout le bloc dans un terminal.

```bash
cat > ~/Downloads/azerty-landscape.py <<'FIN_SCRIPT'
#!/usr/bin/env python3
"""Remplace la couche 'Landscape' de wvkbd (layout.fr.h) par une disposition AZERTY.

Seules les positions des touches changent: chaque touche garde son code
et sa couche d'accents (appui long). Sauvegarde dans layout.fr.h.bak.
Teste sur une Surface Pro 6 (Omarchy, Hyprland 0.56.2), octobre 2026.
Ne modifie que la copie dans ~/src.

Usage: python3 azerty-landscape.py [dossier-des-sources]
"""
import os
import shutil
import sys

DIR = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/src/wvkbd-v0.20")
path = os.path.join(DIR, "layout.fr.h")

NEW = r'''static struct key keys_landscape[] = {
  {"Esc", "Esc", 1.0, Code, KEY_ESC, .scheme = 1},
  {"", "", 0.5, Pad, .scheme = 1},
  {"a", "A", 1.0, Code, KEY_A, &layouts[ComposeA]},
  {"z", "Z", 1.0, Code, KEY_Z, &layouts[ComposeZ]},
  {"e", "E", 1.0, Code, KEY_E, &layouts[ComposeE]},
  {"r", "R", 1.0, Code, KEY_R, &layouts[ComposeR]},
  {"t", "T", 1.0, Code, KEY_T, &layouts[ComposeT]},
  {"y", "Y", 1.0, Code, KEY_Y, &layouts[ComposeY]},
  {"u", "U", 1.0, Code, KEY_U, &layouts[ComposeU]},
  {"i", "I", 1.0, Code, KEY_I, &layouts[ComposeI]},
  {"o", "O", 1.0, Code, KEY_O, &layouts[ComposeO]},
  {"p", "P", 1.0, Code, KEY_P, &layouts[ComposeP]},
  {"", "", 0.5, Pad, .scheme = 1},
  {"Tab", "Tab", 1.0, Code, KEY_TAB, .scheme = 1},
  {"", "", 0.0, EndRow},

  {"↑", "↑", 0.75, Code, KEY_UP, .scheme = 1},
  {"↓", "↓", 0.75, Code, KEY_DOWN, .scheme = 1},
  {"", "", 0.5, Pad, .scheme = 1},
  {"q", "Q", 1.0, Code, KEY_Q, &layouts[Emoji]},
  {"s", "S", 1.0, Code, KEY_S, &layouts[ComposeS]},
  {"d", "D", 1.0, Code, KEY_D, &layouts[ComposeD]},
  {"f", "F", 1.0, Code, KEY_F, &layouts[ComposeF]},
  {"g", "G", 1.0, Code, KEY_G, &layouts[ComposeG]},
  {"h", "H", 1.0, Code, KEY_H, &layouts[ComposeH]},
  {"j", "J", 1.0, Code, KEY_J, &layouts[ComposeJ]},
  {"k", "K", 1.0, Code, KEY_K, &layouts[ComposeK]},
  {"l", "L", 1.0, Code, KEY_L, &layouts[ComposeL]},
  {"m", "M", 1.0, Code, KEY_M, &layouts[ComposeM]},
  {"'", "\"", 1.0, Code, KEY_APOSTROPHE, &layouts[ComposeBracket]},
  {"", "", 0.0, EndRow},

  {"←", "←", 0.75, Code, KEY_LEFT, .scheme = 1},
  {"→", "→", 0.75, Code, KEY_RIGHT, .scheme = 1},
  {"⇧", "⇫", 1.5, Mod, Shift, .scheme = 1},
  {"w", "W", 1.0, Code, KEY_W, &layouts[ComposeW]},
  {"x", "X", 1.0, Code, KEY_X, &layouts[ComposeX]},
  {"c", "C", 1.0, Code, KEY_C, &layouts[ComposeC]},
  {"v", "V", 1.0, Code, KEY_V, &layouts[ComposeV]},
  {"b", "B", 1.0, Code, KEY_B, &layouts[ComposeB]},
  {"n", "N", 1.0, Code, KEY_N, &layouts[ComposeN]},
  {"/", ">", 1.0, Code, KEY_SLASH},
  {"", "", 0.5, Pad, .scheme = 1},
  {"-", "_", 1.0, Code, KEY_MINUS, &layouts[ComposeBracket]},
  {"⌫", "⌫", 1.5, Code, KEY_BACKSPACE, .scheme = 1},
  {"", "", 0.0, EndRow},

  {"⌨͕", "⌨͔", 1.0, NextLayer, .scheme = 1},
  {"Cmp", "Cmp", 1.0, Compose, .scheme = 1},
  {"Ctr", "Ctr", 1.0, Mod, Ctrl, .scheme = 1},
  {",", "'", 1.0, Code, KEY_COMMA, &layouts[ComposeMath]},
  {"", "Tab", 5.0, Code, KEY_SPACE},
  {".", "?", 1.0, Code, KEY_DOT, &layouts[ComposePunctuation]},
  {"Enter", "Enter", 2.0, Code, KEY_ENTER, .scheme = 1},

  /* end of layout */
  {"", "", 0.0, Last},
};'''

src = open(path, encoding="utf-8").read()
marker = "static struct key keys_landscape[] = {"
if src.count(marker) != 1:
    sys.exit("Bloc keys_landscape introuvable ou en double, rien modifie.")

start = src.index(marker)
end = src.index("\n};", start) + len("\n};")

backup = path + ".bak"
if not os.path.exists(backup):
    shutil.copy(path, backup)

with open(path, "w", encoding="utf-8") as handle:
    handle.write(src[:start] + NEW + src[end:])

print("OK: couche Landscape remplacee par une version AZERTY.")
print("Sauvegarde: %s" % backup)
FIN_SCRIPT
```

### `azerty-full.py`

**Indispensable** — étape 3. Colle tout le bloc dans un terminal.

```bash
cat > ~/Downloads/azerty-full.py <<'FIN_SCRIPT'
#!/usr/bin/env python3
"""Remplace la couche 'Full' (portrait) de wvkbd (layout.fr.h) par une disposition AZERTY.

Seules les positions des lettres changent: chaque touche garde son code
et sa couche d'accents (appui long). La rangee de chiffres reste inchangee.
Sauvegarde dans layout.fr.h.bak-full. Teste sur une Surface Pro 6 (Omarchy, Hyprland 0.56.2), octobre 2026.
Ne modifie que la copie dans ~/src.

Usage: python3 azerty-full.py [dossier-des-sources]
"""
import os
import shutil
import sys

DIR = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/src/wvkbd-v0.20")
path = os.path.join(DIR, "layout.fr.h")

NEW = r'''static struct key keys_full[] = {
  {"Esc", "Esc", 1.0, Code, KEY_ESC, .scheme = 1},
  {"Ctr", "Ctr", 1.0, Mod, Ctrl, .scheme = 1},
  {"↑", "↑", 1.0, Code, KEY_UP, .scheme = 1},
  {"↓", "↓", 1.0, Code, KEY_DOWN, .scheme = 1},
  {"←", "←", 1.0, Code, KEY_LEFT, .scheme = 1},
  {"→", "→", 1.0, Code, KEY_RIGHT, .scheme = 1},
  {"'", "\"", 1.0, Code, KEY_APOSTROPHE, &layouts[ComposeBracket] },
  {"-", "_", 1.0, Code, KEY_MINUS, &layouts[ComposeMath] },
  {"/", ">", 1.0, Code, KEY_SLASH,  &layouts[ComposePunctuation] },
  {"Tab", "Tab", 1.0, Code, KEY_TAB, .scheme = 1},
  {"", "", 0.0, EndRow},

  {"1", "!", 1.0, Code, KEY_1},
  {"2", "@", 1.0, Code, KEY_2},
  {"3", "#", 1.0, Code, KEY_3},
  {"4", "$", 1.0, Code, KEY_4},
  {"5", "%", 1.0, Code, KEY_5},
  {"6", "^", 1.0, Code, KEY_6},
  {"7", "&", 1.0, Code, KEY_7},
  {"8", "*", 1.0, Code, KEY_8},
  {"9", "(", 1.0, Code, KEY_9, &layouts[ComposeBracket]},
  {"0", ")", 1.0, Code, KEY_0, &layouts[ComposeBracket]},
  {"", "", 0.0, EndRow},

  {"a", "A", 1.0, Code, KEY_A, &layouts[ComposeA]},
  {"z", "Z", 1.0, Code, KEY_Z, &layouts[ComposeZ]},
  {"e", "E", 1.0, Code, KEY_E, &layouts[ComposeE]},
  {"r", "R", 1.0, Code, KEY_R, &layouts[ComposeR]},
  {"t", "T", 1.0, Code, KEY_T, &layouts[ComposeT]},
  {"y", "Y", 1.0, Code, KEY_Y, &layouts[ComposeY]},
  {"u", "U", 1.0, Code, KEY_U, &layouts[ComposeU]},
  {"i", "I", 1.0, Code, KEY_I, &layouts[ComposeI]},
  {"o", "O", 1.0, Code, KEY_O, &layouts[ComposeO]},
  {"p", "P", 1.0, Code, KEY_P, &layouts[ComposeP]},
  {"", "", 0.0, EndRow},

  {"q", "Q", 1.0, Code, KEY_Q, &layouts[Emoji]},
  {"s", "S", 1.0, Code, KEY_S, &layouts[ComposeS]},
  {"d", "D", 1.0, Code, KEY_D, &layouts[ComposeD]},
  {"f", "F", 1.0, Code, KEY_F, &layouts[ComposeF]},
  {"g", "G", 1.0, Code, KEY_G, &layouts[ComposeG]},
  {"h", "H", 1.0, Code, KEY_H, &layouts[ComposeH]},
  {"j", "J", 1.0, Code, KEY_J, &layouts[ComposeJ]},
  {"k", "K", 1.0, Code, KEY_K, &layouts[ComposeK]},
  {"l", "L", 1.0, Code, KEY_L, &layouts[ComposeL]},
  {"m", "M", 1.0, Code, KEY_M, &layouts[ComposeM]},
  {"", "", 0.0, EndRow},

  {"⇧", "⇫", 2.0, Mod, Shift, .scheme = 1},
  {"w", "W", 1.0, Code, KEY_W, &layouts[ComposeW]},
  {"x", "X", 1.0, Code, KEY_X, &layouts[ComposeX]},
  {"c", "C", 1.0, Code, KEY_C, &layouts[ComposeC]},
  {"v", "V", 1.0, Code, KEY_V, &layouts[ComposeV]},
  {"b", "B", 1.0, Code, KEY_B, &layouts[ComposeB]},
  {"n", "N", 1.0, Code, KEY_N, &layouts[ComposeN]},
  {"⌫", "⌫", 2.0, Code, KEY_BACKSPACE, .scheme = 1},
  {"", "", 0.0, EndRow},

  {"⌨͕", "⌨͔", 1.5, NextLayer, .scheme = 1},
  {"Cmp", "Cmp", 1.0, Compose, .scheme = 1},
  {",", "'", 1.0, Code, KEY_COMMA, &layouts[ComposeMath]},
  {"", "Tab", 4.0, Code, KEY_SPACE},
  {".", "?", 1.0, Code, KEY_DOT, &layouts[ComposePunctuation]},
  {"Enter", "Enter", 1.5, Code, KEY_ENTER, .scheme = 1},

  /* end of layout */
  {"", "", 0.0, Last},
};'''

src = open(path, encoding="utf-8").read()
marker = "static struct key keys_full[] = {"
if src.count(marker) != 1:
    sys.exit("Bloc keys_full introuvable ou en double, rien modifie.")

start = src.index(marker)
end = src.index("\n};", start) + len("\n};")

backup = path + ".bak-full"
if not os.path.exists(backup):
    shutil.copy(path, backup)

with open(path, "w", encoding="utf-8") as handle:
    handle.write(src[:start] + NEW + src[end:])

print("OK: couche Full (portrait) remplacee par une version AZERTY.")
print("Sauvegarde: %s" % backup)
FIN_SCRIPT
```

### `install-wvkbd-widget.sh`

**Indispensable** — étape 4. Colle tout le bloc dans un terminal.

```bash
cat > ~/Downloads/install-wvkbd-widget.sh <<'FIN_SCRIPT'
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
FIN_SCRIPT
```

### `install-close-widget.sh`

**Indispensable** — étape 4. Colle tout le bloc dans un terminal.

```bash
cat > ~/Downloads/install-close-widget.sh <<'FIN_SCRIPT'
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
FIN_SCRIPT
```

### `simplifier-tablette.sh`

**Indispensable** — étape 5. Colle tout le bloc dans un terminal.

```bash
cat > ~/Downloads/simplifier-tablette.sh <<'FIN_SCRIPT'
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
FIN_SCRIPT
```

### `clavier-super.sh`

**Indispensable** — étape 5. Colle tout le bloc dans un terminal.

```bash
cat > ~/Downloads/clavier-super.sh <<'FIN_SCRIPT'
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
FIN_SCRIPT
```

### `demarrage-surface.sh`

**Indispensable** — étape 5. Colle tout le bloc dans un terminal.

```bash
cat > ~/Downloads/demarrage-surface.sh <<'FIN_SCRIPT'
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
FIN_SCRIPT
```

### `veille.sh`

**Indispensable** — étape 6. Colle tout le bloc dans un terminal.

```bash
cat > ~/Downloads/veille.sh <<'FIN_SCRIPT'
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
FIN_SCRIPT
```

### `rotation-ecran-externe.sh`

**Facultatif** — étape 7, seulement avec le plugin hyprmoncfg. Colle tout le bloc dans un terminal.

```bash
cat > ~/Downloads/rotation-ecran-externe.sh <<'FIN_SCRIPT'
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
FIN_SCRIPT
```

### Vérifier les neuf fichiers

Cette commande vérifie que chaque fichier est identique au texte de cette annexe. Chaque ligne doit finir par `OK` ; sinon, recolle le bloc du script concerné.

```bash
cd ~/Downloads && sha256sum -c <<'FIN'
7ae462533d23ba68a5938da1141a88ab1eb6e552d98328852cbd2c9d0bcd1103  azerty-landscape.py
e6b3f13fbc79d8969831452333853afc9f8e702c465c3e6de17aa31d4485337a  azerty-full.py
dc464dbdfeaaa24beaec44e52e4aed5bb81b755845cae55114cbb549e6f241c0  install-wvkbd-widget.sh
db3e54e30b2eb684b1252f2414f629465e661d1ce2cb017a654269563cc7f449  install-close-widget.sh
7bfc22e58b251d0fe54a03f27c997a31f0fc13d3d3f553303dbeaa82c9377564  simplifier-tablette.sh
9d77898214f06b62f3e49527ac324cfa66a0c22a3f0a448847dc0c5d58729e2b  clavier-super.sh
9568b11a250747d0dcf802718e0dcd9c4972a95a388fd3157775c8452c164056  demarrage-surface.sh
c3c79d3d9a667391388113d1465c0a921fc034eb8f620c3cb1af111a9e1593c7  veille.sh
2a06926746b9e0d56639848ceaaaba153cf07f00d26995ecea75b055e775610e  rotation-ecran-externe.sh
FIN
```
