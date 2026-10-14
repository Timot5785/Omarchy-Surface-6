# Omarchy sur Surface Pro 6

Une commande installe tout ce qu'il faut pour utiliser une Surface Pro 6 en tablette sous Omarchy 4 :

- le tactile ;
- la rotation de l'écran, avec le tactile qui suit ;
- un clavier AZERTY à l'écran : accents par appui long, touche Super ;
- deux boutons dans la barre : afficher le clavier, fermer la fenêtre ;
- le clavier sur l'écran de verrouillage ;
- le démarrage automatique sur le noyau Surface ;
- la mise en veille : verrouillage après 2 min, écran éteint 30 s après le verrouillage.

## Pré-requis

1. **Omarchy 4** est installé et ta session est ouverte.
2. Tablette **sur secteur**, **connectée au Wi-Fi**, **Type Cover attaché**.

## Installation

Ouvre un terminal (Super + Entrée) et colle :

```bash
git clone https://github.com/Timot5785/Omarchy-Surface-6.git ~/Omarchy-Surface-6
bash ~/Omarchy-Surface-6/install.sh
```

Compte 10 à 30 minutes, surtout pour la mise à jour du système. Pendant l'installation :

- tape ton **mot de passe** quand il est demandé ;
- le script te demande si tu veux **Lock Screen Explorer**, l'écran de verrouillage de la première tablette (facultatif) ;
- pendant la **mise à jour du système** (`omarchy update`), réponds **Oui** pour la lancer, puis **Non** si elle propose de redémarrer : le script continue ;
- à la fin, accepte de **redémarrer**, puis choisis **linux-surface** dans le menu de démarrage avec les flèches et Entrée. Une seule fois : il sera ensuite choisi tout seul.

Après le redémarrage, contrôle que tout est en place :

```bash
bash ~/Omarchy-Surface-6/install.sh --verifier
```

Toutes les lignes doivent être cochées `[x]`.

## Ce que le script installe

| Élément | À quoi il sert | Indispensable | Étape |
| --- | --- | --- | --- |
| Noyau `linux-surface` et `iptsd` | Écran tactile de la Surface | **Oui** | 1 |
| `iio-sensor-proxy` | Lit l'accéléromètre | **Oui** | 2 |
| Plugin [Tablet Mode](https://github.com/andreiyurik/omarchy-tablet-mode), version `c6ba596` | Tourne l'écran et le tactile | **Oui** | 2 |
| Deux corrections du plugin Tablet Mode | Rotation juste sur la Surface | **Oui** | 2 |
| Clavier `wvkbd-fr` (wvkbd 0.20 compilé en AZERTY) | Clavier à l'écran | **Oui** | 3 |
| Boutons de barre (clavier, ×) | Clavier et fermeture au doigt | **Oui** | 4 |
| Clavier au verrouillage, touche Super, démarrage | Écran de verrouillage, raccourcis, noyau Surface par défaut | **Oui** | 5 |
| Délais de mise en veille | 2 min, puis 30 s | **Oui** | 6 |
| Plugin [Lock Screen Explorer](https://github.com/SirJul1337/omarchy-lock-explorer) | Autre écran de verrouillage | Non (question posée) | 6 |
| Correctif pour [hyprmoncfg](https://github.com/crmne/omarchy-hyprmoncfg) | Garder la rotation avec un écran externe | Seulement si hyprmoncfg est installé | 7 |

Inutiles : OmaTouch, la config « Tablet Experience » et le paquet AUR `wvkbd`.

## Si une étape échoue

Le script s'arrête, explique le problème et donne la commande pour reprendre, par exemple :

```bash
bash ~/Omarchy-Surface-6/install.sh --depuis 3
```

Tout est noté dans `~/omarchy-surface-install.log` : c'est le fichier à envoyer pour demander de l'aide. Relancer le script ne casse rien : chaque étape vérifie ce qui est déjà fait.

## Réglages

La hauteur du clavier à l'écran se règle au lancement, en pixels :

```bash
CLAVIER_PAYSAGE=400 CLAVIER_PORTRAIT=450 bash ~/Omarchy-Surface-6/install.sh --depuis 5
```

Par défaut : 400 en paysage, 500 en portrait. `LOCK_EXPLORER=oui` ou `LOCK_EXPLORER=non` évite la question sur Lock Screen Explorer.

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

## Écran externe

Le plugin hyprmoncfg (gestion des écrans) remet l'écran de la tablette à l'horizontale toutes les 5 secondes. Si tu l'installes, applique ensuite le correctif :

```bash
omarchy plugin add https://github.com/crmne/omarchy-hyprmoncfg.git --enable
bash ~/Omarchy-Surface-6/install.sh --depuis 7
```

## Mises à jour

- En principe, `omarchy update` ne touche pas à ce qui est installé ici. Après une grosse mise à jour, `bash ~/Omarchy-Surface-6/install.sh --verifier` le confirme.
- **N'accepte pas** la mise à jour du plugin Tablet Mode proposée par le Plugin Manager (« Update Unverified ») : elle efface ses corrections. Si c'est fait, relance `bash ~/Omarchy-Surface-6/install.sh --depuis 2`.

## Revenir en arrière

- **Rotation** : `cp ~/.config/omarchy/plugins/andreiyurik.tablet-mode/bin/omarchy-tablet-mode.bak ~/.config/omarchy/plugins/andreiyurik.tablet-mode/bin/omarchy-tablet-mode`, puis `omarchy restart shell`.
- **Clavier, verrouillage, démarrage, veille** : chaque script du dossier `scripts/` sauvegarde les fichiers qu'il modifie et affiche à la fin sa commande d'annulation (voir le journal). Les sauvegardes sont dans `~/.config/hypr` (`sauvegarde-<date>`, `autostart.lua.bak-<date>`), `~/.config/omarchy` (`shell.json.bak-veille-<date>`) et `/boot` (`limine.conf.avant-surface-<date>`).
- **Boutons de barre** : `rm -r ~/.config/omarchy/plugins/tim.wvkbd-toggle ~/.config/omarchy/plugins/tim.close-window`, puis `omarchy restart shell`.
- **Écran externe** : `rm ~/.config/systemd/user/hyprmoncfgd.service.d/rotation-tablette.conf && systemctl --user daemon-reload && systemctl --user restart hyprmoncfgd.service`.
- **Noyau** : `linux-omarchy` reste dans le menu de démarrage.

## Contenu du dépôt

| Fichier | Rôle |
| --- | --- |
| `install.sh` | Lance les étapes 1 à 7 dans l'ordre, puis le contrôle |
| `scripts/corrections-tablet-mode.sh` | Étape 2 : les deux corrections du plugin Tablet Mode |
| `scripts/azerty-landscape.py`, `scripts/azerty-full.py` | Étape 3 : disposition AZERTY du clavier (paysage, portrait) |
| `scripts/install-wvkbd-widget.sh`, `scripts/install-close-widget.sh` | Étape 4 : boutons de barre |
| `scripts/simplifier-tablette.sh`, `scripts/clavier-super.sh`, `scripts/demarrage-surface.sh` | Étape 5 |
| `scripts/veille.sh` | Étape 6 |
| `scripts/rotation-ecran-externe.sh` | Étape 7 |
| `GUIDE-MANUEL.md` | La même installation, étape par étape, sans `install.sh` |

## Testé sur

Surface Pro 6, Omarchy 4.0.4, Hyprland 0.56.2, noyau 6.19.8-arch1-3-surface, Tablet Mode 1.7.4 (`c6ba596`), wvkbd 0.20, octobre 2026.

Chaque étape a été testée une à une sur la première tablette. `install.sh`, qui les enchaîne, a été vérifié en simulation : son premier vrai passage d'un bloc se fera sur une tablette neuve.
