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
