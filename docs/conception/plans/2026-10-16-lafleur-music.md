# LAFLEUR Music Implementation Plan


**Goal:** Un lecteur de musique iPod Classic 6G aux couleurs LAFLEURSTUDIO pour l'Anbernic RG SP sous ROCKNIX, qui joue en arrière-plan pendant les jeux et éteint l'écran clapet fermé.

**Architecture:** Moteur MPD 0.23.17 (binaire aarch64 du port PortMaster « mpd ») qui tourne seul ; interface LÖVE 11.5 (Lua) qui lui parle en TCP sur 127.0.0.1:6601 ; « lidwatch », une seconde appli LÖVE sans fenêtre qui éteint le rétroéclairage clapet fermé. La logique pure vit dans `common/` et `ui/src/`, testée sous LuaJIT sur le Mac ; un lanceur bash orchestre le tout sur la console.

**Tech Stack:** Lua (LuaJIT 2.1 / LÖVE 11.5), MPD 0.23 (protocole texte), bash (ROCKNIX), Python + cairosvg (génération des assets, déjà dans le venv du scratchpad), Homebrew sur le Mac (`luajit`, `mpd`, cask `love`).

**Spec:** `docs/conception/specs/2026-10-16-lafleur-music-design.md`

## Global Constraints

- Écran 720×480 plein écran ; couleurs : fond `#0D0D0D`, barre de titre `#1C1C1C`, texte `#FFFFFF`, secondaire `#969696`, sélection `#F26EF2` avec texte `#1F1F1F` ; police Inter Regular/Bold.
- Logo texte LAFLEURSTUDIO blanc (sans fleur) dans la barre de titre du menu principal ; fleur rose sur le démarrage, le petit écran Arrière-plan et les pochettes de remplacement (fleur sur `#1A1A1A`).
- « LAFLEURSTUDIO » ne se traduit jamais. Nom affiché de l'appli : « LAFLEUR Music ».
- Langue : `system.language` dans `/storage/.config/system/configs/system.cfg` ; commence par `fr` → français, sinon anglais.
- MPD : `127.0.0.1`, port `6601`, `music_directory "/storage/roms/music"`.
- Dossier de l'appli sur la console : `/storage/roms/lafleur-music/` ; lanceur copié dans `/storage/.config/gmu/playlists/LAFLEUR Music.sh`.
- Rétroéclairage : `/sys/class/backlight/backlight/bl_power` (`0` = allumé, `4` = éteint) ; batterie : `/sys/class/power_supply/battery/capacity`.
- Jamais de mise en veille ; lidwatch rallume l'écran avant toute sortie.
- L1 + R1 : deux appuis à moins de 150 ms d'écart ; le petit écran Arrière-plan reste 1,5 s.
- Ne pas modifier ROCKNIX. Pas de dépendance à PortMaster à l'exécution.

## Review Focus

- Noms avec accents, guillemets ou antislash (« Öwnboss », « Salomé », `Little "Talks"`) → les commandes MPD restent valides et le tri reste stable. Test : Task 2 (`quote`) et Task 4 (tri).
- Tag de piste `3/12`, `03`, vide ou absent → morceaux triés par numéro puis titre, sans erreur. Test : Task 4.
- MPD redémarré ou connexion coupée pendant l'utilisation → l'appli se reconnecte une fois, puis écran « Moteur audio indisponible ». Test : Task 3.
- Titres très longs → coupés avec « … » à la largeur disponible, jamais de débordement. Test : Task 9 (`fit_text`).
- L1 maintenu seul longtemps, ou R1 relâché après 150 ms → un seul « précédent » / « suivant », jamais de bascule fantôme. Test : Task 7.

---

## File Structure

```
lafleur-music/
├── common/                  logique partagée UI + lidwatch (pure Lua, testée sous LuaJIT)
│   ├── mpd_protocol.lua     encodage/décodage du protocole texte MPD
│   ├── mpd_client.lua       client TCP (socket de LÖVE), reconnexion
│   ├── library.lua          regroupements et tris (playlists, artistes, genres, morceaux)
│   ├── i18n.lua             détection de langue + textes FR/EN
│   └── settings.lua         réglages key=value + fichier d'état « background »
├── ui/                      appli LÖVE principale
│   ├── conf.lua  main.lua
│   ├── src/input.lua        détection L1+R1 et répétition de la croix
│   ├── src/coverflow_layout.lua
│   ├── src/text.lua         fit_text (coupe avec …)
│   ├── src/theme.lua        couleurs, polices, barre de titre
│   ├── src/covers.lua       pochettes (readpicture → cache → image LÖVE)
│   ├── src/screens/{splash,menu,list,coverflow,nowplaying,settings,toast,message}.lua
│   └── assets/{fonts/Inter-*.otf, logo-texte.png, fleur.png, fleur-tile.png}
├── lidwatch/                appli LÖVE sans fenêtre
│   ├── conf.lua  main.lua
│   └── src/{lid.lua, rule.lua, reader_thread.lua}
├── launcher/LAFLEUR Music.sh
├── engine/mpd.conf
├── tests/{run.lua, test_*.lua, integration/main.lua}
└── tools/{setup-mac.sh, fetch-vendor.sh, make-assets.py, build.sh, dev.sh, install.sh, dev-mpd.conf}
```

`tools/build.sh` assemble `build/lafleur-music/` en copiant `common/*.lua` dans `ui/common/` et `lidwatch/common/` (LÖVE ne charge que depuis le dossier du jeu), plus les binaires de `vendor/`. `build/`, `vendor/`, `devmusic/` sont dans `.gitignore`.

---

### Task 1: Outillage et lanceur de tests

**Files:**
- Create: `tools/setup-mac.sh`, `tests/run.lua`, `tests/test_smoke.lua`
- Modify: `.gitignore` (ajouter `build/`, `vendor/`, `devmusic/`)

**Interfaces:**
- Produces: `tests/run.lua` — charge chaque `tests/test_*.lua`, qui renvoie une table `{["nom du test"] = function() ... end}` ; affiche `ok`/`FAIL` par test, termine avec code 1 s'il y a un échec. Helpers globaux : `eq(actual, expected, msg)` (comparaison profonde de tables), `truthy(v, msg)`. `package.path` inclut `common/?.lua;ui/src/?.lua;lidwatch/src/?.lua`.

- [ ] **Step 1:** `tools/setup-mac.sh` installe `brew install luajit mpd` et `brew install --cask love` (idempotent : saute ce qui est déjà là). Lancer, vérifier `luajit -v` et `/Applications/love.app/Contents/MacOS/love --version` → `LOVE 11.5`.
- [ ] **Step 2:** Écrire `tests/test_smoke.lua` avec `["eq compare les tables"] = function() eq({a={1,2}}, {a={1,2}}) end`.
- [ ] **Step 3:** Lancer `luajit tests/run.lua` → erreur (`run.lua` absent).
- [ ] **Step 4:** Écrire `tests/run.lua`.
- [ ] **Step 5:** `luajit tests/run.lua` → `ok  test_smoke: eq compare les tables`, code 0.
- [ ] **Step 6:** Commit `chore: outillage Mac et lanceur de tests`.

### Task 2: Protocole MPD

**Files:**
- Create: `common/mpd_protocol.lua`, `tests/test_mpd_protocol.lua`

**Interfaces:**
- Produces:
  - `P.quote(s: string) -> string` — entoure de `"` et échappe `\` puis `"`.
  - `P.parse(lines: {string}) -> {ok: boolean, err: string|nil, pairs: {{key, value}}}` — s'arrête à `OK` ou `ACK [...] {...} message`.
  - `P.records(pairs, first_key: string) -> {table}` — découpe une liste de paires en enregistrements, un nouveau commençant à chaque `first_key` (ex. `file`).
  - `P.binary_header(pairs) -> {size: number, binary: number}` — pour `readpicture`.

- [ ] **Step 1:** Tests :
  - `quote('Little "Talks"')` → `'"Little \\"Talks\\""'` ; `quote('a\\b')` → `'"a\\\\b"'` ; `quote("Öwnboss")` → `'"Öwnboss"'`.
  - `parse({"volume: 60", "state: play", "OK"})` → `ok=true`, `pairs={{"volume","60"},{"state","play"}}`.
  - `parse({"ACK [50@0] {find} no such song"})` → `ok=false`, `err="no such song"`.
  - `records({{"file","a.mp3"},{"Title","A"},{"file","b.mp3"},{"Title","B"}}, "file")` → `{{file="a.mp3",Title="A"},{file="b.mp3",Title="B"}}`.
  - Une valeur contenant `: ` (`"Title: Ça: va"`) garde tout après le premier `": "`.
- [ ] **Step 2:** `luajit tests/run.lua` → FAIL (module absent).
- [ ] **Step 3:** Implémenter `common/mpd_protocol.lua`.
- [ ] **Step 4:** `luajit tests/run.lua` → tous `ok`.
- [ ] **Step 5:** Commit `feat: protocole MPD`.

### Task 3: Client MPD avec reconnexion

**Files:**
- Create: `common/mpd_client.lua`, `tests/test_mpd_client.lua`, `tests/integration/main.lua`, `tests/integration/conf.lua`, `tools/dev-mpd.conf`, `tools/dev.sh`

**Interfaces:**
- Consumes: `P.parse`, `P.records`, `P.binary_header`, `P.quote` (Task 2).
- Produces: `C.new(opts: {host, port, connect: function(host, port) -> sock|nil, err}) -> client` ; méthodes :
  - `client:command(line: string) -> resp` (table de `P.parse`), reconnecte **une** fois si l'envoi ou la lecture échoue ; si la seconde tentative échoue → `{ok=false, err="unavailable"}`.
  - `client:songs() -> {table}` (via `listallinfo`, enregistrements `file`).
  - `client:status() -> table`, `client:currentsong() -> table|nil`.
  - `client:picture(file: string) -> string|nil` (boucle `readpicture <file> <offset>` jusqu'à `size`).
  - `sock` = objet avec `send(s)`, `receive("*l")`, `receive(n)`, `close()` (LuaSocket, fourni par LÖVE ; injecté pour les tests).
- `tools/dev-mpd.conf` : MPD sur le Mac, port 6601, `music_directory` = `$PWD/devmusic`, db/state/pid dans `/tmp/lafleur-mpd/`, sortie `osx`. `tools/dev.sh start|stop` lance/arrête ce MPD et copie 2 albums depuis le NAS (`rsync johnny@pi-music.local:/mnt/ssd/music/{Rock,House}/ devmusic/`, lecture seule) si `devmusic/` est vide.

- [ ] **Step 1:** Tests avec un faux socket (script de lignes) :
  - `command("status")` renvoie les paires du script.
  - Premier `send` qui renvoie `nil,"closed"`, puis connexion neuve qui répond `OK` → `ok=true`, `connect` appelé 2 fois.
  - Deux échecs de suite → `{ok=false, err="unavailable"}`, pas de troisième appel à `connect`.
  - `picture("x.mp3")` reconstitue 2 morceaux de 3 octets (`size: 6`, `binary: 3`) en une chaîne de 6 octets.
- [ ] **Step 2:** `luajit tests/run.lua` → FAIL.
- [ ] **Step 3:** Implémenter `common/mpd_client.lua` (le banner `OK MPD x.y.z` est lu à la connexion).
- [ ] **Step 4:** `luajit tests/run.lua` → `ok`.
- [ ] **Step 5:** Écrire `tests/integration/main.lua` : appli LÖVE qui se connecte au MPD de dev, vérifie `songs()` non vide et `picture()` non nil sur le premier morceau, `print`e le résultat et `love.event.quit(0|1)`. Lancer `tools/dev.sh start && love tests/integration` → `INTEGRATION OK`.
- [ ] **Step 6:** Commit `feat: client MPD avec reconnexion`.

### Task 4: Bibliothèque

**Files:**
- Create: `common/library.lua`, `tests/test_library.lua`

**Interfaces:**
- Consumes: liste de morceaux `{file, Title, Artist, Album, Genre, Track, Time}` (Task 3 `songs()`).
- Produces (toutes pures) :
  - `L.sort_key(s: string) -> string` — minuscules, accents latins ramenés à la lettre de base (é→e, ö→o, ç→c…), articles non retirés.
  - `L.track_number(t: string|nil) -> number` — `"3/12"`→3, `"03"`→3, vide/nil→`math.huge`.
  - `L.albums(songs) -> {{name, count, first_file}}` triés par `sort_key(name)`.
  - `L.tracks_of_album(songs, album) -> {song}` triés par `track_number` puis `sort_key(Title)`.
  - `L.artists(songs) -> {{name, count}}` ; `L.tracks_of_artist(songs, artist)`.
  - `L.genres(songs) -> {{name, count}}` ; `L.albums_of_genre(songs, genre) -> {{name, count, first_file}}`.
  - `L.all_tracks(songs) -> {song}` triés par `sort_key(Title)`.
  - Tag manquant → regroupé sous la chaîne `""`, que l'UI affiche via `i18n` (`unknown`).

- [ ] **Step 1:** Tests : albums `{"Émo", "abc", "Zed"}` → ordre `abc, Émo, Zed` ; pistes `"10"`, `"2/12"`, `nil`, `"03"` → `2, 3, 10, nil` ; `track_number("")` → `math.huge` ; `genres` compte correctement ; `albums_of_genre("EDM")` ne renvoie que les albums de ce genre.
- [ ] **Step 2:** `luajit tests/run.lua` → FAIL.
- [ ] **Step 3:** Implémenter `common/library.lua`.
- [ ] **Step 4:** `luajit tests/run.lua` → `ok`.
- [ ] **Step 5:** Commit `feat: regroupements et tris de la bibliothèque`.

### Task 5: Langue et textes

**Files:**
- Create: `common/i18n.lua`, `tests/test_i18n.lua`

**Interfaces:**
- Produces: `I.detect(syscfg_text: string|nil) -> "fr"|"en"` ; `I.t(lang, key, ...) -> string` (remplace `%d`/`%s` avec `string.format`).
- Clés et textes exacts :

| clé | fr | en |
|---|---|---|
| cover_flow | Cover Flow | Cover Flow |
| playlists | Playlists | Playlists |
| artists | Artistes | Artists |
| songs | Morceaux | Songs |
| genres | Genres | Genres |
| shuffle_all | Lecture aléatoire | Shuffle Songs |
| now_playing | En cours | Now Playing |
| settings | Réglages | Settings |
| shuffle | Aléatoire | Shuffle |
| repeat | Répéter | Repeat |
| background | Arrière-plan | Background |
| background_default | Arrière-plan par défaut | Background by default |
| update_library | Mettre à jour la bibliothèque | Update Library |
| on / off | ON / OFF | ON / OFF |
| bg_on_msg | La musique continue\nquand tu quittes l'appli | Music keeps playing\nwhen you quit the app |
| bg_off_msg | La musique s'arrêtera\nquand tu quittes l'appli | Music will stop\nwhen you quit the app |
| n_songs | %d morceaux | %d songs |
| n_of | %d sur %d | %d of %d |
| playlist_n | Playlist · %d morceaux | Playlist · %d songs |
| empty_library | Ajoute de la musique dans roms/music | Add music to roms/music |
| engine_down | Moteur audio indisponible | Audio engine unavailable |
| unknown | Inconnu | Unknown |
| updating | Mise à jour… | Updating… |

- [ ] **Step 1:** Tests : `detect("x=1\nsystem.language=fr_FR\n")` → `"fr"` ; `detect("system.language=en_US")` → `"en"` ; `detect(nil)` → `"en"` ; `detect("system.language=de_DE")` → `"en"` ; `t("fr","n_of",3,88)` → `"3 sur 88"` ; chaque clé existe dans les deux langues (boucle sur la table `fr`).
- [ ] **Step 2:** FAIL. **Step 3:** implémenter. **Step 4:** `ok`. **Step 5:** Commit `feat: langue FR/EN`.

### Task 6: Réglages et état Arrière-plan

**Files:**
- Create: `common/settings.lua`, `tests/test_settings.lua`

**Interfaces:**
- Produces:
  - `S.DEFAULTS = {background_default = "on"}` (aléatoire/répéter sont stockés par MPD lui-même via `state_file`).
  - `S.load(path) -> table` (fichier `key=value` ; absent ou illisible → copie de `DEFAULTS`) ; `S.save(path, tbl)` (écriture dans `path..".tmp"` puis `os.rename`).
  - `S.read_background(state_dir) -> "on"|"off"` (fichier `state_dir.."/background"`, absent → `"on"`) ; `S.write_background(state_dir, v)`.
- Chemins : `settings.txt` à la racine de l'appli ; `state_dir` = `engine/state`.

- [ ] **Step 1:** Tests : aller-retour `save`/`load` ; fichier absent → `{background_default="on"}` ; ligne mal formée ignorée ; `read_background` sans fichier → `"on"` ; `write_background(d,"off")` puis `read_background(d)` → `"off"`. Dossier temporaire via `os.tmpname()`.
- [ ] **Step 2:** FAIL. **Step 3:** implémenter. **Step 4:** `ok`. **Step 5:** Commit `feat: réglages et état arrière-plan`.

### Task 7: Touches (L1+R1 et répétition)

**Files:**
- Create: `ui/src/input.lua`, `tests/test_input.lua`

**Interfaces:**
- Produces: `In.new({window = 0.15, repeat_delay = 0.4, repeat_rate = 0.08}) -> input` ; `input:press(btn, t)`, `input:release(btn, t)`, `input:update(t)` ; chacun renvoie une liste d'actions (chaînes) : `"previous"`, `"next"`, `"toggle_background"`, `"up"`, `"down"`, `"left"`, `"right"`, `"ok"`, `"back"`, `"playpause"`, `"now_playing"`. Boutons : `"l1","r1","up","down","left","right","a","b","start","select"`.
- Règle L1/R1 : un appui sur `l1` (ou `r1`) est mis en attente ; si l'autre est appuyé avant `t0 + window` → `toggle_background`, et aucun des deux ne produit `previous`/`next` jusqu'à leur relâchement ; sinon, à `t0 + window` (via `update`) ou au relâchement s'il est plus tôt → une seule fois `previous` (l1) ou `next` (r1). Pas de répétition sur L1/R1.
- Croix haut/bas : action immédiate, puis répétition après `repeat_delay` toutes les `repeat_rate` tant que maintenue.

- [ ] **Step 1:** Tests :
  - `press(l1,0)`, `press(r1,0.1)` → `{"toggle_background"}` ; `update(0.5)` → `{}` ; relâchements → `{}`.
  - `press(l1,0)`, `update(0.16)` → `{"previous"}` ; `press(r1,0.2)` → `{}` puis `update(0.36)` → `{"next"}` (pas de bascule).
  - `press(l1,0)`, `update(2)` → un seul `previous` ; `update(3)` → `{}`.
  - `press(l1,0)`, `release(l1,0.05)` → `{"previous"}`.
  - `press(down,0)` → `{"down"}` ; `update(0.39)` → `{}` ; `update(0.41)` → `{"down"}` ; `update(0.49)` → `{"down"}`.
  - `press(start,0)` → `{"playpause"}` ; `press(select,0)` → `{"now_playing"}` ; `press(a,0)` → `{"ok"}` ; `press(b,0)` → `{"back"}`.
- [ ] **Step 2:** FAIL. **Step 3:** implémenter. **Step 4:** `ok`. **Step 5:** Commit `feat: touches et combo L1+R1`.

### Task 8: Disposition du Cover Flow

**Files:**
- Create: `ui/src/coverflow_layout.lua`, `tests/test_coverflow_layout.lua`

**Interfaces:**
- Produces: `CF.layout(pos: number, count: number) -> {{index, x, y, w, h, side}}` pour l'écran 720×480 ; `pos` est fractionnaire pendant l'animation. Pochette centrale 240×240 en `x=240, y=70`, `side="center"` ; voisines à distance `d` (1 à 3) : largeur projetée 110, hauteur 240, `x = 240 - 55*d - 55` à gauche / `x = 480 + 55*(d-1)` à droite (valeurs de la maquette : 130/75/20 et 480/535/590), `side="left"|"right"` ; liste ordonnée **du plus loin au plus proche** (ordre de dessin), centre en dernier. Indices hors `[1,count]` exclus.
- `CF.step(pos, target, dt) -> number` — rapproche `pos` de `target` (vitesse 12/s, s'arrête exactement sur `target` quand l'écart < 0.01).

- [ ] **Step 1:** Tests : `layout(4,6)` contient 7 éléments, le dernier est l'index 4 en `x=240` ; `layout(1,6)` n'a pas d'élément à gauche ; ordre de dessin : index 1 (d=3) avant 3 (d=1) ; `step(1,2,1)` → `2` ; `step(1,2,0.01)` entre 1 et 2.
- [ ] **Step 2:** FAIL. **Step 3:** implémenter. **Step 4:** `ok`. **Step 5:** Commit `feat: disposition Cover Flow`.

### Task 9: Squelette de l'appli LÖVE, thème, démarrage

**Files:**
- Create: `ui/conf.lua`, `ui/main.lua`, `ui/src/theme.lua`, `ui/src/text.lua`, `ui/src/screens/splash.lua`, `ui/src/screens/message.lua`, `tools/make-assets.py`, `tools/build.sh`, `tests/test_text.lua`
- Create (générés puis commités) : `ui/assets/logo-texte.png` (logo blanc, 250 px de large), `ui/assets/fleur.png` (rose, 480 px), `ui/assets/fleur-tile.png` (fleur sur `#1A1A1A`, 300×300), `ui/assets/fonts/Inter-Regular.otf`, `Inter-Bold.otf` (copiés depuis le thème Elementerial, avec `LICENSE.txt`)

**Interfaces:**
- Consumes: `common/*` (Tasks 2–6), `In` (Task 7).
- Produces:
  - `fit_text(s: string, max_w: number, measure: function(string) -> number) -> string` dans `ui/src/text.lua` — renvoie `s` s'il tient, sinon le plus long préfixe (par caractère UTF-8) suivi de `…` qui tient.
  - `theme` : `theme.colors` (valeurs des Global Constraints), `theme.font(kind: "Regular"|"Bold", size) -> Font` (mis en cache), `theme.title_bar(title: string|nil, playing: boolean, battery: number|nil)` (titre `nil` → logo texte).
  - `app` (global dans `main.lua`) : `app.lang`, `app.mpd` (client), `app.songs`, `app.push(screen)`, `app.pop()`, `app.replace(screen)`, `app.toast(on: boolean)`, `app.quit()`. Un écran = table avec `enter()`, `update(dt)`, `draw()`, `action(name)`.
  - Variables d'environnement (dev sur le Mac) : `LAFLEUR_MPD_PORT` (6601), `LAFLEUR_SYSCFG` (`/storage/.config/system/configs/system.cfg`), `LAFLEUR_APPDIR` (dossier de l'appli, défaut `/storage/roms/lafleur-music`), `LAFLEUR_BATTERY` (`/sys/class/power_supply/battery/capacity`).
- `conf.lua` : `t.window.width=720`, `height=480`, `fullscreen = (os.getenv("LAFLEUR_WINDOWED") == nil)`, `t.window.title="LAFLEUR Music"`, `t.modules.physics=false`, `t.modules.video=false`.
- Démarrage : splash (fleur + logo texte sur noir) → connexion MPD (essai toutes les 0,5 s pendant 5 s) → chargement `songs()` → menu principal ; vide → `message` avec `empty_library` ; MPD injoignable → `message` avec `engine_down` (B quitte).
- `tools/build.sh` produit `build/lafleur-music/` ; `tools/dev.sh run` lance `LAFLEUR_WINDOWED=1 love build/lafleur-music/ui` avec MPD de dev.

- [ ] **Step 1:** Tests `fit_text` avec `measure = function(s) return #s * 10 end` : `fit_text("1901", 100, m)` → `"1901"` ; `r = fit_text("Long Cool Woman", 80, m)` → `r` se termine par `"…"`, `m(r) <= 80`, et `r` sans le `"…"` est un préfixe de `"Long Cool Woman"` ; chaîne UTF-8 `"Ééééé"` jamais coupée au milieu d'un caractère (le résultat est de l'UTF-8 valide : `utf8_ok(r)` défini dans le test).
- [ ] **Step 2:** FAIL. **Step 3:** implémenter `ui/src/text.lua`. **Step 4:** `ok`.
- [ ] **Step 5:** `tools/make-assets.py` (venv du scratchpad, cairosvg) génère les PNG depuis le dossier des logos LAFLEURSTUDIO ; lancer, vérifier les 3 PNG.
- [ ] **Step 6:** Implémenter `conf.lua`, `main.lua`, `theme.lua`, `splash.lua`, `message.lua`.
- [ ] **Step 7:** `tools/build.sh && tools/dev.sh start && tools/dev.sh run` → splash puis écran vide « menu » (placeholder) ; MPD arrêté (`tools/dev.sh stop`) → « Audio engine unavailable » (console en `en_US`) ; avec `LAFLEUR_SYSCFG` pointant vers un fichier `system.language=fr_FR` → « Moteur audio indisponible ».
- [ ] **Step 8:** Commit `feat: squelette de l'appli, thème et démarrage`.

### Task 10: Menu principal, listes et pochettes

**Files:**
- Create: `ui/src/screens/menu.lua`, `ui/src/screens/list.lua`, `ui/src/covers.lua`

**Interfaces:**
- Consumes: `L.*` (Task 4), `app` et `theme` (Task 9), `client:picture` (Task 3).
- Produces:
  - `list.new({title: string, items: {{label, sub?, cover_file?, on_ok: function}}}) -> screen` — liste à gauche (380 px, lignes de 54 px, 8 visibles, chevron `›`), pochette de l'élément sélectionné à droite (300 px en `x=400,y=64`, reflet 70 px, légende sous la pochette), défilement qui garde la sélection visible, gauche/droite = page.
  - `covers.get(file: string|nil, size: 300|120) -> Image` — cache mémoire puis disque `cache/covers/<clé>-<size>.png` (clé = `love.data.hash("md5", file)` en hex), sinon `client:picture` + redimensionnement, sinon `fleur-tile.png`. Chargement au plus 1 pochette par frame (file d'attente) pour éviter les saccades.
  - `menu` = `list.new` avec les 8 entrées (`cover_flow, playlists, artists, songs, genres, shuffle_all, now_playing, settings`), titre `nil` (logo texte).
- Navigation (spec §4) : Playlists → `tracks_of_album` ; Artistes → `tracks_of_artist` ; Genres → `albums_of_genre` → morceaux ; Morceaux → `all_tracks`. Choisir un morceau : `clear` + `findadd album "<album>"` (ou la liste affichée, ajoutée morceau par morceau via `add`) puis `play <index>` et `app.push(nowplaying)`. Lecture aléatoire : `clear`, `add ""` (tout), `random 1`, `play`, puis En cours.

- [ ] **Step 1:** `tools/build.sh && tools/dev.sh run` : le menu ressemble à `maquettes/1-menu.png` ; naviguer dans les 4 listes ; une pochette s'affiche à droite ; un album sans pochette affiche la fleur ; un titre long est coupé avec `…`.
- [ ] **Step 2:** Choisir un morceau → la musique joue sur le Mac (`mpc -p 6601 status` dans un autre terminal → `playing`).
- [ ] **Step 3:** Commit `feat: menu principal, listes et pochettes`.

### Task 11: Écran Cover Flow

**Files:**
- Create: `ui/src/screens/coverflow.lua`

**Interfaces:**
- Consumes: `CF.layout`, `CF.step` (Task 8), `covers.get` (Task 10), `L.albums` (Task 4).
- Produces: `coverflow.new() -> screen` — pochettes latérales dessinées en perspective avec un `love.graphics.newMesh` à 4 sommets (bord intérieur 100 % de la hauteur, bord extérieur 76 %, comme la maquette), assombries de 35 % ; centre + reflet 60 px ; nom de l'album (Bold 24) et `playlist_n` (Regular 17) ; points de position (rose = courant). Gauche/droite déplacent la cible, A ouvre la liste des morceaux de l'album (Task 10), B revient.

- [ ] **Step 1:** `tools/dev.sh run` → Cover Flow ressemble à `maquettes/2-coverflow.png` ; le défilement est animé et s'arrête net sur chaque pochette ; aux extrémités, pas de pochette fantôme.
- [ ] **Step 2:** Commit `feat: Cover Flow`.

### Task 12: En cours, petit écran Arrière-plan et sortie

**Files:**
- Create: `ui/src/screens/nowplaying.lua`, `ui/src/screens/toast.lua`
- Modify: `ui/main.lua` (actions globales)

**Interfaces:**
- Consumes: `client:status`, `client:currentsong`, `S.read_background/write_background` (Task 6), `In` (Task 7).
- Produces:
  - Actions globales dans `main.lua`, valables sur tous les écrans : `playpause` → `pause` (ou `play` si arrêté) ; `previous`/`next` → commandes MPD ; `now_playing` → push En cours ; `toggle_background` → inverse `S.read_background`, l'écrit, `app.toast(nouvelle_valeur == "on")`.
  - `nowplaying` : mise en page de `maquettes/3-en-cours.png` ; `status` interrogé toutes les 0,5 s ; barre de progression = `elapsed/duration` ; badge « `background` : ON/OFF · L1 + R1 ».
  - `toast` : superposé à l'écran courant, fond flouté (canvas + shader de flou 2 passes, ou à défaut assombrissement 45 %), panneau 380×260 centré, contenu de `maquettes/4-arriere-plan.png`, disparaît après 1,5 s.
  - Sortie (B au menu principal) : `love.event.quit(0)`. Au démarrage, si `engine/state/background` n'existe pas, il est créé avec `settings.background_default`.

- [ ] **Step 1:** `tools/dev.sh run` : En cours ressemble à la maquette ; START met en pause/reprend ; L1/R1 changent de morceau ; L1+R1 affiche le petit écran ON puis OFF, et `cat <appdir>/engine/state/background` suit.
- [ ] **Step 2:** Commit `feat: écran En cours et bascule arrière-plan`.

### Task 13: Réglages

**Files:**
- Create: `ui/src/screens/settings.lua`

**Interfaces:**
- Consumes: `list.new` (Task 10), `S.load/save` (Task 6), `client:status`.
- Produces: 4 lignes : `shuffle` (ON/OFF ↔ `random 0|1`), `repeat` (↔ `repeat 0|1`), `background_default` (↔ `settings.txt`), `update_library` (envoie `update`, affiche `updating` jusqu'à ce que `status` n'ait plus `updating_db`, puis recharge `app.songs`). A bascule la valeur ; la valeur s'affiche à droite de la ligne à la place du chevron.

- [ ] **Step 1:** `tools/dev.sh run` : chaque réglage bascule et survit à un redémarrage de l'UI ; ajouter un MP3 dans `devmusic/`, « Mettre à jour la bibliothèque » → il apparaît dans Morceaux.
- [ ] **Step 2:** Commit `feat: écran Réglages`.

### Task 14: Gardien du clapet (lidwatch)

**Files:**
- Create: `lidwatch/conf.lua`, `lidwatch/main.lua`, `lidwatch/src/lid.lua`, `lidwatch/src/rule.lua`, `lidwatch/src/reader_thread.lua`, `tests/test_lid.lua`, `tests/test_rule.lua`

**Interfaces:**
- Consumes: `C.new`/`client:status` (Task 3), `S.read_background` (Task 6).
- Produces:
  - `lid.find_device(proc_devices_text: string) -> string|nil` — renvoie `"/dev/input/eventN"` du premier bloc de `/proc/bus/input/devices` dont la ligne `B: SW=` a le bit 0 (SW_LID) à 1.
  - `lid.decode(bytes: string) -> {type, code, value}|nil` — événement evdev aarch64 de 24 octets : 16 octets de `timeval`, puis `u16 type`, `u16 code`, `s32 value`, little-endian. Clapet = `type 5` (EV_SW), `code 0` (SW_LID), `value 1` fermé / `0` ouvert.
  - `rule.screen_on(lid_closed: boolean, background: "on"|"off", state: "play"|"pause"|"stop"|nil) -> boolean` — `false` seulement si `lid_closed and background == "on" and state == "play"`.
  - `main.lua` : `conf.lua` met `t.window = nil` et coupe `graphics`, `audio`, `sound`, `joystick` ; un `love.thread` (`reader_thread.lua`) lit l'événement bloquant et pousse `"closed"`/`"open"` dans un canal ; la boucle lit le canal, interroge MPD toutes les 2 s, lit `engine/state/background`, et écrit `0`/`4` dans `bl_power` seulement quand la décision change. Écrit son pid dans `engine/state/lidwatch.pid`. Sur toute erreur (`xpcall`) et dans `love.quit` : écrit `0` dans `bl_power`, journalise dans `log.txt`. Si aucun périphérique de clapet n'est trouvé : journalise et sort après avoir écrit `0`.

- [ ] **Step 1:** Tests : `find_device` sur un extrait réaliste (deux blocs, le second avec `H: Handlers=event2` et `B: SW=1`) → `"/dev/input/event2"` ; bloc sans `B: SW=` ignoré ; `B: SW=2` (bit 0 à 0) ignoré. `decode` de 24 octets construits (`string.char`) avec type 5, code 0, value 1 → `{type=5,code=0,value=1}` ; moins de 24 octets → `nil`. `rule.screen_on` : les 8 combinaisons utiles, `true` sauf `(true,"on","play")`.
- [ ] **Step 2:** FAIL. **Step 3:** implémenter `lid.lua`, `rule.lua`. **Step 4:** `ok`.
- [ ] **Step 5:** Implémenter `conf.lua`, `main.lua`, `reader_thread.lua`. Sur le Mac : `LAFLEUR_BL_POWER=/tmp/bl_power LAFLEUR_LID_DEVICE=/tmp/fake-lid love build/lafleur-music/lidwatch` avec un fichier FIFO alimenté de 24 octets → `/tmp/bl_power` passe à `4` puis `0` (variables d'environnement de test : `LAFLEUR_BL_POWER`, `LAFLEUR_LID_DEVICE`).
- [ ] **Step 6:** Commit `feat: gardien du clapet`.

### Task 15: Moteur, lanceur, paquet et installation

**Files:**
- Create: `engine/mpd.conf`, `launcher/LAFLEUR Music.sh`, `tools/fetch-vendor.sh`, `tools/install.sh`
- Modify: `tools/build.sh` (ajouter moteur, runtime, lanceur)

**Interfaces:**
- Consumes: tout le reste.
- Produces:
  - `tools/fetch-vendor.sh` : télécharge dans `vendor/` `mpd.zip` (`https://github.com/PortsMaster/PortMaster-New/releases/download/2025-08-21_2306/mpd.zip`, md5 `acdf22cde8b8e3e3eacf23750c9f516a`) et `librespot.zip` (`https://github.com/PortsMaster/PortMaster-New/releases/download/2026-01-25_1827/librespot.zip`, md5 `89bc0488cde203423a12b6c47dc4f1a5`), refuse si le md5 diffère, extrait `mpd/mpd` + `mpd/libs/*` → `engine/`, `librespot/love` + `librespot/libs/*` → `bin/`, et les licences.
  - `engine/mpd.conf` : `music_directory "/storage/roms/music"`, `playlist_directory "/storage/roms/lafleur-music/engine/state/playlists"`, `db_file`, `state_file`, `pid_file` dans `/storage/roms/lafleur-music/engine/state/`, `bind_to_address "127.0.0.1"`, `port "6601"`, `auto_update "yes"`, `restore_paused "yes"`, et le bloc `audio_output` **pipewire** repris tel quel de `mpd/configs/pipewire/mpdconf` du port.
  - `launcher/LAFLEUR Music.sh` (bash) : `APP=/storage/roms/lafleur-music` ; si absent → journal `/storage/.config/gmu/lafleur-missing.log` et sortie 0 ; `LD_LIBRARY_PATH="$APP/engine:$APP/bin/libs"` ; démarre MPD si le pid de `engine/state/pid` ne vit pas ; démarre lidwatch en arrière-plan si `engine/state/lidwatch.pid` ne vit pas ; lance l'UI au premier plan ; à la sortie, lit `engine/state/background` : `off` → tue lidwatch, écrit `0` dans `bl_power`, `"$APP/engine/mpd" --kill "$APP/engine/mpd.conf"`. Toute la sortie va dans `$APP/log.txt` (remise à zéro à chaque lancement).
  - `tools/install.sh` : monte en invité `games-roms` et `config` de `192.168.1.138` si besoin (`mount_smbfs -N`), `rsync -rt --exclude='._*'` de `build/lafleur-music/` vers `games-roms/lafleur-music/`, copie le lanceur dans `config/gmu/playlists/`, supprime les `._*`, puis compare les fichiers (`diff -rq`).
- Le binaire `love` du port Spotify est un script : l'inspecter à l'étape 1 ; s'il dépend de PortMaster, le remplacer par un petit script qui exécute `liblove` via le chargeur fourni dans `bin/libs` (ou, à défaut, copier le runtime `love_11.5` de PortMaster dans `bin/`). Documenter le choix dans un commentaire en tête du lanceur.

- [ ] **Step 1:** `tools/fetch-vendor.sh` → `md5 OK` deux fois ; lire `vendor/librespot/love` et trancher le point ci-dessus.
- [ ] **Step 2:** `bash -n "launcher/LAFLEUR Music.sh"` → aucune erreur ; `tools/build.sh` → `build/lafleur-music/` contient `engine/mpd`, `bin/love`, `ui/`, `lidwatch/`, `LAFLEUR Music.sh`.
- [ ] **Step 3:** `tools/install.sh` → `diff -rq` vide.
- [ ] **Step 4:** Sur la console (Johnny) : Music > LAFLEUR Music. Lire `games-roms/lafleur-music/log.txt` par le réseau : MPD démarré, lidwatch a trouvé un périphérique de clapet, UI lancée. Corriger et recommencer jusqu'à ce que l'appli s'ouvre.
- [ ] **Step 5:** Commit `feat: moteur, lanceur et installation`.

### Task 16: Vérification sur la console

**Files:** aucun (sauf corrections)

- [ ] **Step 1:** Avec Johnny, cocher les critères de la spec §1 : écrans conformes aux maquettes ; 6 playlists / 338 artistes / 443 morceaux ; Arrière-plan ON → quitter, lancer un jeu, la musique continue ; clapet fermé → écran éteint, rouvert → rallumé ; Arrière-plan OFF → quitter arrête la musique et l'écran reste allumé ; console en français → appli en français.
- [ ] **Step 2:** Lire `log.txt` après chaque essai ; aucune erreur non gérée.
- [ ] **Step 3:** Commit des corrections éventuelles, tag `v1.0`.
