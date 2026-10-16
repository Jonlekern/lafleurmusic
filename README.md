# LAFLEURMUSIC

Lecteur de musique façon **iPod Classic 6G** pour consoles portables sous **ROCKNIX**, aux couleurs de **LAFLEURSTUDIO**.
Menus iPod, **Cover Flow**, lecture **en arrière-plan** pendant les jeux, écran éteint clapet fermé.

*An iPod Classic–style music player for ROCKNIX handhelds: iPod menus, Cover Flow, background playback while gaming, screen off when the lid is closed. French and English UI.*

![LAFLEURMUSIC — menu, Cover Flow, En cours](docs/images/maquettes.png)

## Fonctions

- Menu principal : Cover Flow, Playlists (albums), Artistes, Morceaux, Genres, Lecture aléatoire, En cours, Réglages.
- **Cover Flow** des albums avec leurs pochettes (pochettes intégrées aux fichiers, mises en cache).
- **Arrière-plan** (L1 + R1) : ON, la musique continue après avoir quitté l'appli, même en jeu ; OFF (par défaut), quitter arrête la musique.
- **Clapet** : ON → écran éteint, la musique continue ; OFF → pause et écran éteint, reprise à l'ouverture.
- Interface en **français** ou en **anglais**, selon la langue de la console.

## Touches

| Touche | Action |
|---|---|
| Croix | naviguer (← → : morceau précédent / suivant dans En cours) |
| A / B | ouvrir / retour |
| START | lecture / pause |
| SELECT | aller à En cours |
| L1 / R1 | morceau précédent / suivant |
| L1 + R1 | Arrière-plan ON / OFF |
| Y / X | aléatoire / répéter (off → tout → un seul) |
| MENU | quitter |

## Comment ça marche

- **Moteur audio** : MPD 0.23 (binaire aarch64 du port PortMaster « Music Player Daemon »), qui joue en arrière-plan.
- **Interface** : LÖVE 11.5 (Lua), qui pilote MPD en TCP sur `127.0.0.1:6601`.
- **Gardien du clapet** (`lidwatch/`) : petite appli LÖVE sans fenêtre qui lit l'interrupteur du clapet et gère l'écran.
- La musique est lue dans `/storage/roms/music`.

Testé sur **Anbernic RG SP** (720×480) avec **ROCKNIX 20261001**. Les autres tailles d'écran sont en préparation.

## Installation (depuis un Mac ou un PC sur le même Wi-Fi)

1. Sur la console : activer **Samba** (START > Network Settings > Enable Samba).
2. `tools/fetch-vendor.sh` : télécharge MPD et LÖVE depuis les releases officielles PortMaster (vérification md5).
3. `tools/build.sh` : assemble `build/lafleur-music/`.
4. `RGSP_HOST=<ip de la console> tools/install.sh` : copie l'appli dans `/storage/roms/lafleur-music/` et le lanceur dans le menu **Music**.
5. Sur la console : START > Game Settings > Update Gamelists, puis **Music > LAFLEURMUSIC**.

Pour que le clapet ne mette pas la console en veille (la musique s'arrêterait), ajouter dans
`/storage/.config/logind.conf.d/80-lafleur-clapet.conf` :

```ini
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```

## Tests

```bash
luajit tests/run.lua
```

La logique (protocole MPD, bibliothèque, langue, réglages, touches, Cover Flow, clapet) est testée sous LuaJIT ; l'interface se vérifie sur la console.

## Licences

- **Code** : MIT, voir [LICENSE](LICENSE).
- **Logos et marque LAFLEURSTUDIO / LAFLEURMUSIC** (`ui/assets/fleur*.png`, `ui/assets/logo-texte*.png`, `docs/images/`) : © LAFLEURSTUDIO, tous droits réservés. Ils ne sont **pas** couverts par la licence MIT.
- **Inter** (`ui/assets/fonts/`) : SIL Open Font License 1.1.
- **MPD** (GPL-2.0) et **LÖVE** (zlib) ne sont pas inclus dans ce dépôt : `tools/fetch-vendor.sh` les télécharge depuis PortMaster, avec leurs licences.
