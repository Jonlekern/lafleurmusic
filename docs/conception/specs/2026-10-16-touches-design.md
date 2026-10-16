# LAFLEURMUSIC — touches personnalisées (clapet ouvert / fermé)

Date : 16.10.2026 · Maquettes validées : `maquettes/simulation/touches.png` (gitignoré).
Le mode tactile fera l'objet d'une spec séparée, après celle-ci.

## 1. But

Chaque raccourci de LAFLEURMUSIC peut être placé sur la touche ou la combinaison de deux touches de son choix,
avec un réglage pour le **clapet ouvert** et un autre pour le **clapet fermé** (musique dans la poche).

**Réussi quand :**
- dans Réglages → « Touches clapet ouvert », on change la touche d'Aléatoire et la nouvelle touche marche tout de suite ;
- les inscriptions à l'écran (En cours, petits écrans) montrent les touches choisies ;
- clapet fermé, L2 + R2 met en pause / relance, R1 + R2 passe au suivant, L1 + L2 au précédent,
  que l'appli soit ouverte ou quittée en Arrière-plan ON ;
- clapet fermé, une touche seule ne fait rien ;
- « Réinitialiser » remet les touches d'origine ; les réglages survivent au redémarrage.

**Hors périmètre :** remapper la croix, Valider, Retour et MENU (seulement « A/B inversés ») ; les touches volume
(gérées par ROCKNIX) ; trois touches ou plus ; appui long ; mode tactile.

## 2. Ce que Johnny a dit / ce qui est supposé

| Dit par Johnny | Supposé (validé en maquette) |
|---|---|
| Chaque fonction sur une touche perso, dans les Réglages | Deux lignes dans Réglages : « Touches clapet ouvert », « Touches clapet fermé » |
| Combinaisons de touches, clapet fermé ou pas | Une touche ou deux ensemble (fenêtre 0,15 s, comme L1 + R1 aujourd'hui) |
| Clapet fermé il atteint L1, R1, L2, R2, volume, la croix, A, B, X, Y | Clapet fermé : combinaisons de deux touches seulement (appuis dans la poche) |
| — | Navigation fixe + option « A/B inversés » ; conflit → les deux raccourcis échangent leur touche |
| — | Changer une touche : petit écran « Appuie sur… », annulé après 5 s sans appui |

## 3. Les raccourcis

| Action | Clapet ouvert (défaut) | Clapet fermé (défaut) |
|---|---|---|
| Lecture / Pause | START | L2 + R2 |
| Morceau suivant | R1 | R1 + R2 |
| Morceau précédent | L1 | L1 + L2 |
| Aléatoire | Y | — |
| Répéter | X | — |
| En cours | SELECT | (sans objet) |
| Arrière-plan | L1 + R1 | (sans objet) |

Touches utilisables :
- **clapet ouvert** : X, Y, START, SELECT, L1, R1, L2, R2, seules ou par deux ;
- **clapet fermé** : L1, R1, L2, R2 seulement (relevé sur la console : les autres touches sont inaccessibles clapet fermé), toujours par deux.

Fixes clapet ouvert : croix, A = Valider, B = Retour, MENU = Quitter. « A/B inversés » échange Valider et Retour.

## 4. Architecture

### 4.1 `common/keymap.lua` (nouveau, testé sous LuaJIT)
Données pures, partagées par l'interface et le gardien du clapet :
- `DEFAULTS.open`, `DEFAULTS.closed` : tableau action → combinaison (`"start"`, `"l1+r1"`, `""` = aucune) ;
- `load(settings)` / `store(settings, map)` : clés `key_open_<action>`, `key_closed_<action>`, `ab_swap` dans `settings.txt` ;
  valeur absente ou invalide → défaut ;
- `assign(map, side, action, combo)` : refuse une touche non autorisée pour ce côté (fixe, ou seule clapet fermé) ;
  si la combinaison est déjà prise par une autre action, celle-ci reçoit l'ancienne combinaison de `action` ;
- `label(combo)` : `"l1+r1"` → `"L1 + R1"`, `""` → `"—"` ;
- `normalize(a, b)` : combinaison triée, pour que L1 puis R1 = R1 puis L1.

### 4.2 `ui/src/input.lua` (généralisé)
`In.new({ bindings = map.open, ab_swap = … })`. Les touches fixes donnent leurs actions comme aujourd'hui.
Une touche qui fait partie d'au moins une combinaison attend 0,15 s : si l'autre touche arrive, l'action de la
combinaison part ; sinon l'action de la touche seule part au relâchement ou à la fin de la fenêtre.
Les autres touches partent immédiatement. `In:set_bindings(map)` applique un changement sans relancer l'appli.
L2 / R2 arrivent de SDL comme axes (`triggerleft`, `triggerright`) : appui au-dessus de 0,5, relâchement en dessous de 0,3.

### 4.3 Écrans
- `screens/keys.lua` (nouveau) : liste (même composant que Réglages) des actions du côté choisi avec leur touche,
  plus « A/B inversés » (clapet ouvert) et « Réinitialiser ». Valider ouvre la capture.
- Capture : petit écran façon toast, en attente de touches. Clapet ouvert : une touche, ou deux à moins de 0,15 s.
  Clapet fermé : il faut deux touches. Touche fixe ou refusée → « Touche réservée ». 5 s sans appui → annulé.
- En cours et les petits écrans (Aléatoire, Répéter, Arrière-plan) affichent `keymap.label` au lieu de Y, X, START, L1 + R1.

### 4.4 Clapet fermé : le gardien du clapet (`lidwatch`)
- Le gardien tourne déjà pendant que l'appli est ouverte et en Arrière-plan ON après l'avoir quittée.
  Il devient le **seul** à traiter les touches clapet fermé ; il écrit `state/lid` (`open` / `closed`).
- L'interface lit `state/lid` à chaque image : clapet fermé, elle ignore toutes les touches.
- Le fil de lecture lit aussi le périphérique evdev de la manette (bloc de `/proc/bus/input/devices` avec
  `EV_KEY` et `BTN_SOUTH`). Les codes evdev de la RG SP sont relevés une fois sur la console (étape du plan)
  et gardés dans une table code → nom (`a`, `b`, `l2`…).
- `lidwatch/src/combo.lua` (nouveau, testé) : même règle de combinaison que l'interface, mais deux touches obligatoires.
- Actions : Lecture / Pause = `pause` avec bascule ; si Arrière-plan OFF avait mis en pause, relancer annule
  « mis en pause par nous » (la reprise à l'ouverture ne se refait pas) ; suivant / précédent = `next` / `previous` ;
  Aléatoire et Répéter = mêmes commandes que l'interface (`playmode`).
- Le gardien relit `settings.txt` quand sa date de modification change.

### 4.5 Textes
Nouvelles clés FR / EN dans `i18n.lua` : touches_open, touches_closed, ab_swap, reset_keys, press_key,
press_two_keys, key_reserved, cancelled_in, et les noms des actions.

## 5. Erreurs
- `settings.txt` illisible ou combinaison inconnue → touches d'origine, ligne dans `log.txt`.
- Manette introuvable par le gardien → clapet géré comme aujourd'hui, sans touches clapet fermé, ligne dans le journal.
- MPD absent quand une touche clapet fermé arrive → ignoré (le gardien s'arrête déjà après 3 échecs).

## 6. Tests
- `test_keymap.lua` : défauts, lecture / écriture, refus des touches fixes, refus d'une touche seule clapet fermé,
  échange en cas de conflit, libellés, ordre indifférent.
- `test_input.lua` : combinaison quelconque, touche seule après la fenêtre, A/B inversés, nouvelles touches appliquées.
- `test_combo.lua` (gardien) : deux touches → action, une seule → rien.
- `test_rule.lua` : relancer clapet fermé en Arrière-plan OFF annule la reprise automatique.
- Simulateur : écrans Touches et capture aux 4 tailles. Console : relevé des codes evdev, puis essai clapet fermé dans les deux modes.
