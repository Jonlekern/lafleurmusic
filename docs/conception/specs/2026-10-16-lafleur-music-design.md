# LAFLEUR Music — spec de design

Date : 16.10.2026 · Appareil : Anbernic RG SP (H700, DDR3, écran 720×480, 3:2) sous ROCKNIX 20261001.

## 1. But

Un lecteur de musique fait maison, aux couleurs LAFLEURSTUDIO, avec les menus de l'iPod Classic 6G et un Cover Flow.
Il remplace le lecteur d'origine de ROCKNIX (GMU) dans le menu **Music** de la console.
La musique doit pouvoir continuer pendant les jeux et clapet fermé, « comme un iPod dans la poche ».

**Réussi quand :**
- on lance « LAFLEUR Music » depuis le menu Music et on retrouve les écrans des maquettes (`maquettes/`) ;
- on navigue dans les 6 playlists (albums), 338 artistes, 443 morceaux de `roms/music` sans à-coups ;
- avec Arrière-plan ON, on quitte l'appli, on lance un jeu, la musique continue ; clapet fermé, l'écran s'éteint ;
- avec Arrière-plan OFF, quitter l'appli arrête la musique ;
- l'appli s'affiche en français si la console est en français, sinon en anglais.

**Hors périmètre :** modifier ou recompiler ROCKNIX ; contrôler la musique depuis l'intérieur d'un jeu ; Spotify ; radio/podcasts ; édition des tags.

## 2. Ce que Johnny a dit / ce qui est supposé

| Dit par Johnny | Supposé (validé en maquette) |
|---|---|
| Lecteur maison qui remplace le menu Music d'origine | Nom affiché : « LAFLEUR Music » |
| Menus comme l'iPod Classic 6G, Cover Flow | Disposition : liste à gauche, pochette à droite |
| Les albums sont ses playlists compilées | Cover Flow = les albums |
| Musique pendant les jeux, clapet fermé | Moteur MPD en arrière-plan |
| L1 + R1 dans l'appli bascule Arrière-plan, avec un petit écran | Le petit écran reste ~1,5 s |
| Clapet fermé = écran éteint, partout (option B) | Seulement si Arrière-plan ON et musique en cours |
| Thème LAFLEURSTUDIO, logo texte sans la fleur dans la barre de titre | Rose #F26EF2, fond #0D0D0D, police Inter |
| Langue = celle de la console (FR, sinon EN) | Lue dans `system.cfg` (`system.language`) |
| Ne pas modifier ROCKNIX, pas besoin de PortMaster au quotidien | Binaires `mpd` et `love` copiés dans le dossier de l'appli |

## 3. Architecture

Trois pièces, dans un seul dossier `/storage/roms/lafleur-music/` (carte de 128 Go, TF2) :

```
lafleur-music/
├── LAFLEUR Music.sh      lanceur (copié aussi dans /storage/.config/gmu/playlists/ → menu Music)
├── engine/               moteur audio : binaire mpd + libs du port PortMaster « mpd » (aarch64, config pipewire ROCKNIX)
│   ├── mpd.conf          music_directory /storage/roms/music, port 6601 sur 127.0.0.1, db/state/pid dans engine/state/
│   └── state/            base MPD, état de lecture (reprise au même endroit)
├── lidwatch/             « gardien du clapet »
├── ui/                   interface LÖVE 11.5 (Lua)
├── bin/love              runtime LÖVE (celui du port Spotify Connect, sinon runtime officiel PortMaster copié ici)
├── cache/covers/         pochettes réduites (PNG 300 px et 120 px)
├── settings.json         réglages de l'appli (Arrière-plan par défaut, aléatoire, répéter)
└── log.txt               journal (lanceur + UI + gardien)
```

**Moteur audio (MPD).** Démarré par le lanceur s'il ne tourne pas déjà (vérifié par `engine/state/pid` + connexion TCP).
Il garde la base des tags et l'état de lecture (`state_file`), donc la lecture reprend où elle en était.
Il est indépendant de l'UI : il continue de jouer quand l'UI est fermée.

**Interface (LÖVE).** Parle à MPD en TCP (`127.0.0.1:6601`, protocole texte MPD, `socket` inclus dans LÖVE).
Commandes utilisées : `status`, `currentsong`, `list album`, `list artist`, `list genre`, `find`, `findadd`,
`clear`, `play`, `pause`, `next`, `previous`, `seekcur`, `random`, `repeat`, `update`, `readpicture`
(pochette intégrée), `idle player` pour suivre les changements.

**Gardien du clapet (lidwatch).** Lancé avec le moteur, tourne tant que MPD tourne.
Il lit l'interrupteur du clapet (événement `SW_LID` du périphérique d'entrée) et éteint/rallume l'écran via
`/sys/class/backlight/backlight/bl_power` (chemin vu dans les journaux de la console).
Règle : clapet fermé **et** Arrière-plan ON **et** MPD en lecture → écran éteint ; tout le reste → écran allumé.
Si le gardien rencontre une erreur ou s'arrête, il rallume l'écran avant de sortir.
Le langage (shell + outil système, Python, ou petit binaire) est choisi au plan, après avoir vérifié ce que
ROCKNIX fournit sur la console. Il n'utilise jamais la mise en veille.

**Arrêt.** À la sortie de l'UI : Arrière-plan ON → le lanceur laisse MPD et le gardien tourner ;
Arrière-plan OFF → le lanceur arrête le gardien (écran rallumé) puis MPD.

**Installation.** Copier le dossier par le Wi-Fi (partage `games-roms`), puis copier le lanceur dans
`/storage/.config/gmu/playlists/` (partage `config`). Aucun changement à ROCKNIX.

## 4. Écrans

Résolution 720×480 plein écran. Couleurs : fond #0D0D0D, barre de titre #1C1C1C, texte #FFFFFF,
secondaire #969696, sélection #F26EF2 avec texte #1F1F1F. Police Inter (Regular/Bold).

- **Barre de titre (tous les écrans)** : icône lecture/pause à gauche, au centre le logo texte LAFLEURSTUDIO
  blanc (menu principal) ou le nom de l'écran, à droite batterie (% + icône).
- **Démarrage** : fleur rose + logo texte sur noir (comme le splash du thème), le temps de joindre MPD.
- **Menu principal** : Cover Flow, Playlists, Artistes, Morceaux, Genres, Lecture aléatoire, En cours, Réglages.
  Liste à gauche (380 px), pochette de l'élément sélectionné à droite avec reflet.
- **Cover Flow** : albums en pochettes inclinées, celle du centre de face avec reflet, nom + nombre de morceaux,
  points de position. Défilement animé.
- **Listes** (Playlists, Artistes, Morceaux, Genres et sous-listes) : même mise en page que le menu principal.
- **En cours** : grande pochette + reflet, « n sur N », titre, artiste, album, barre de progression rose,
  temps écoulé / restant, Aléatoire, Répéter, badge « Arrière-plan : ON/OFF · L1 + R1 ».
- **Petit écran Arrière-plan** : panneau centré sur fond flouté, fleur + « Arrière-plan ON » (rose) ou « OFF » (gris)
  + phrase explicative, ~1,5 s.
- **Réglages** : Aléatoire, Répéter, Arrière-plan par défaut, Mettre à jour la bibliothèque.

Navigation : Playlists → morceaux → lecture ; Artistes → morceaux → lecture ; Genres → playlists → morceaux → lecture ;
Lecture aléatoire → toute la bibliothèque en aléatoire, va sur En cours.

## 5. Touches

| Touche | Action |
|---|---|
| Croix haut/bas | se déplacer (appui long : défilement rapide) |
| Croix gauche/droite | Cover Flow : pochette précédente/suivante ; listes : page précédente/suivante |
| A | ouvrir / lancer |
| B | retour ; au menu principal : quitter |
| START | lecture / pause |
| SELECT | aller à En cours |
| L1 / R1 | morceau précédent / suivant |
| L1 + R1 | basculer Arrière-plan ON/OFF (+ petit écran) |
| Volume | volume système (inchangé) |

L1 + R1 : détecté si les deux sont enfoncés à moins de 150 ms d'écart ; dans ce cas ni « précédent » ni « suivant ».

## 6. Données

- Playlists = valeurs distinctes du tag album, triées par nom ; morceaux triés par numéro de piste.
- Artistes = tag artist trié ; Genres = tag genre trié ; Morceaux = tous, triés par titre.
- Pochettes : `readpicture` sur le premier morceau de l'album, réduites et mises en cache dans `cache/covers/`
  (clé = nom d'album). Pochette absente ou illisible → fleur LAFLEURSTUDIO sur #1A1A1A.
- Langue : `system.language` dans `/storage/.config/system/configs/system.cfg` ; commence par `fr` → français,
  sinon anglais. Textes dans deux tables (`fr`, `en`).

## 7. Erreurs

| Situation | Comportement |
|---|---|
| Bibliothèque vide | message « Ajoute de la musique dans roms/music » / « Add music to roms/music » |
| MPD ne répond pas | une relance, puis écran « Moteur audio indisponible », retour au menu de la console avec B |
| Carte TF2 absente | le lanceur affiche un message et sort proprement |
| Pochette illisible | fleur de remplacement, l'erreur va dans le journal |
| Gardien en erreur | écran rallumé, erreur dans le journal, la musique continue |

Tout est écrit dans `log.txt`, lisible par le partage réseau `games-roms`.

## 8. Tests

- **Logique (automatique, sur le Mac)** : tri des listes, regroupements, détection L1 + R1, choix de langue,
  analyse des réponses MPD — avec un faux serveur MPD.
- **Interface (sur le Mac)** : LÖVE et MPD installés sur macOS, fenêtre 720×480, vraie musique de la carte.
  Comparer aux maquettes.
- **Gardien** : testé sur la console avec un clapet réel ; vérifier que l'écran se rallume dans tous les cas
  (clapet ouvert, musique arrêtée, Arrière-plan OFF, gardien tué).
- **Console** : installation par le Wi-Fi, essai par Johnny, lecture de `log.txt` à distance.

## 9. Licences

MPD (GPL-2.0) et LÖVE (zlib) redistribués tels quels avec leurs licences dans le dossier. Polices Inter (OFL)
reprises du thème Elementerial. Logos LAFLEURSTUDIO : ceux de Johnny.
